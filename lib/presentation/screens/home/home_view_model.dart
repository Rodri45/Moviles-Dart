import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/building.dart';
import '../../../domain/entities/cached.dart';
import '../../../domain/entities/level_forecast.dart';
import '../../../domain/entities/level_recommendation.dart';
import '../../../domain/entities/levels_overview.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/location_provider.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/telemetry.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';

class HomeViewModel extends ChangeNotifier with ConnectivityAware {
  HomeViewModel(
    this._parking,
    this._preferences,
    this._location,
    this._telemetry,
    ConnectivityPort connectivity, {
    DateTime Function()? clock,
    this.refreshEvery = const Duration(seconds: 15),
  }) : _clock = clock ?? DateTime.now {
    arrivalAt = _clock().add(defaultLead);
    watchConnectivity(connectivity, load);
  }

  static const defaultLead = Duration(minutes: 20);

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final LocationProvider _location;
  final Telemetry _telemetry;
  final DateTime Function() _clock;

  /// How often the free spots of each level are asked again while Home is
  /// on screen, so a spot taken from any phone shows up here.
  final Duration refreshEvery;
  Timer? _timer;
  bool _hidden = false;
  bool _visible = false;
  bool _forecastReportedForVisit = false;

  Cached<LevelsOverview>? levels;
  List<Building> buildings = const [];
  List<LevelForecast> _forecasts = const [];
  LevelRecommendation? recommendation;
  late DateTime arrivalAt;
  bool isLoading = false;
  String? errorMessage;

  bool campusFullPending = false;

  String get destination => _preferences.destination;

  bool get showOffline => !online || (levels?.fromCache ?? false);

  int get currentHour => _clock().hour;

  List<HourlyOccupancy> get forecast {
    if (_forecasts.isEmpty) return const [];
    final hourly = hourlyOccupancy(_forecasts);
    if (hourly.every((hour) => hour.occupancy == null)) return const [];
    final start = (currentHour - 1).clamp(0, 16);
    return hourly.sublist(start, start + 8);
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    await Future.wait([
      _loadLevels(),
      _loadBuildings(),
      _loadForecast(),
      _loadRecommendation(),
    ]);
    isLoading = false;
    notifyListeners();
  }

  /// Called by the screen when Home appears or disappears: when the driver
  /// changes tab, opens another screen on top or leaves the app.
  void setVisible(bool visible) {
    _timer?.cancel();
    _timer = null;
    if (!visible) {
      _hidden = true;
      _visible = false;
      _forecastReportedForVisit = false;
      return;
    }
    _visible = true;
    _reportForecastViewed();
    if (_hidden && online) refreshLevels();
    _hidden = false;
    _timer = Timer.periodic(refreshEvery, (_) {
      if (online) refreshLevels();
    });
  }

  /// Asks only for the level counts, without the loading spinner.
  Future<void> refreshLevels() async {
    await _loadLevels();
    notifyListeners();
  }

  Future<void> selectDestination(String buildingId) async {
    await _preferences.saveDestination(buildingId);
    notifyListeners();
  }

  Future<void> setArrivalTime(int hour, int minute) async {
    final now = _clock();
    var arrival = DateTime(now.year, now.month, now.day, hour, minute);
    if (arrival.isBefore(now)) arrival = arrival.add(const Duration(days: 1));
    arrivalAt = arrival;
    _telemetry.track('forecast_viewed', {'source': 'arrival_time_changed'});
    notifyListeners();
    await _loadRecommendation();
    notifyListeners();
  }

  void campusFullHandled() => campusFullPending = false;

  Future<void> _loadLevels() async {
    try {
      final result = await _parking.getLevels(zone: await _zone());
      final wasFull = levels?.data.campusFull ?? false;
      levels = result;
      if (result.data.campusFull && !wasFull) campusFullPending = true;
    } catch (e) {
      errorMessage = errorMessageFor(e);
    }
  }

  Future<String?> _zone() async {
    if (await _location.checkAccess() != LocationAccess.granted) return null;
    final position =
        await _location.lastKnownPosition() ??
        await _location.currentPosition();
    return position?.toZone();
  }

  Future<void> _loadBuildings() async {
    try {
      buildings = await _parking.getBuildings();
    } catch (e) {
      debugPrint('buildings failed: $e');
    }
  }

  Future<void> _loadForecast() async {
    try {
      _forecasts = await _parking.getPredictions();
      _reportForecastViewed();
    } catch (e) {
      debugPrint('predictions failed: $e');
    }
  }

  void _reportForecastViewed() {
    if (!_visible || _forecastReportedForVisit || forecast.isEmpty) return;
    _forecastReportedForVisit = true;
    _telemetry.track('forecast_viewed', {'source': 'home_forecast'});
  }

  Future<void> _loadRecommendation() async {
    try {
      recommendation = await _parking.getRecommendedLevel(arrivalAt);
    } catch (e) {
      recommendation = null;
      debugPrint('recommendation failed: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
