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
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';

class HomeViewModel extends ChangeNotifier with ConnectivityAware {
  HomeViewModel(
    this._parking,
    this._preferences,
    this._location,
    ConnectivityPort connectivity, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    arrivalAt = _clock().add(defaultLead);
    watchConnectivity(connectivity, load);
  }

  static const defaultLead = Duration(minutes: 20);

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final LocationProvider _location;
  final DateTime Function() _clock;

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
    final start = (currentHour - 1).clamp(0, 16);
    return hourlyOccupancy(_forecasts).sublist(start, start + 8);
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

  Future<void> selectDestination(String buildingId) async {
    await _preferences.saveDestination(buildingId);
    notifyListeners();
  }

  Future<void> setArrivalTime(int hour, int minute) async {
    final now = _clock();
    var arrival = DateTime(now.year, now.month, now.day, hour, minute);
    if (arrival.isBefore(now)) arrival = arrival.add(const Duration(days: 1));
    arrivalAt = arrival;
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
    } catch (e) {
      debugPrint('predictions failed: $e');
    }
  }

  Future<void> _loadRecommendation() async {
    try {
      recommendation = await _parking.getRecommendedLevel(arrivalAt);
    } catch (e) {
      recommendation = null;
      debugPrint('recommendation failed: $e');
    }
  }
}
