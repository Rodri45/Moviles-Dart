import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/building.dart';
import '../../../domain/entities/cached.dart';
import '../../../domain/errors.dart';
import '../../../domain/entities/level_forecast.dart';
import '../../../domain/entities/level_recommendation.dart';
import '../../../domain/entities/levels_overview.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/location_provider.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/telemetry.dart';
import '../../../infrastructure/storage/forecast_file_store.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';

class HomeViewModel extends ChangeNotifier with ConnectivityAware {
  HomeViewModel(
    this._parking,
    this._preferences,
    this._location,
    this._telemetry,
    ConnectivityPort connectivity, {
    this._forecastStore,
    DateTime Function()? clock,
    this.refreshEvery = const Duration(seconds: 15),
  }) : _clock = clock ?? DateTime.now {
    arrivalAt = _restoreArrivalTime(_preferences.arrivalTime, _clock());
    watchConnectivity(connectivity, load);
  }

  static const defaultLead = Duration(minutes: 20);

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final LocationProvider _location;
  final Telemetry _telemetry;
  final DateTime Function() _clock;
  final ForecastFileStore? _forecastStore;

  final Duration refreshEvery;
  Timer? _timer;
  bool _hidden = false;
  bool _visible = false;
  bool _forecastReportedForVisit = false;

  Cached<LevelsOverview>? levels;
  List<Building> buildings = const [];
  List<LevelForecast> _forecasts = const [];
  List<LevelForecast> get forecasts => _forecasts;
  LevelRecommendation? recommendation;
  bool forecastFromCache = false;
  DateTime? forecastSavedAt;
  String? forecastErrorMessage;
  String? _forecastDateKey;
  late DateTime arrivalAt;
  bool isLoading = false;
  String? errorMessage;

  bool campusFullPending = false;

  String get destination => _preferences.destination;

  bool get showOffline => !online || (levels?.fromCache ?? false);

  int get currentHour => _clock().hour;

  int get forecastHour => arrivalAt.hour;

  List<HourlyOccupancy> get forecast {
    if (_forecasts.isEmpty) return const [];
    final hourly = hourlyOccupancy(_forecasts);
    if (hourly.every((hour) => hour.occupancy == null)) return const [];
    final start = (arrivalAt.hour - 1).clamp(0, 16);
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
      _prefetchLevels(),
    ]);
    isLoading = false;
    notifyListeners();
  }

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
    if (_hidden && online) {
      refreshLevels();
      unawaited(_prefetchLevels());
    }
    _hidden = false;
    _timer = Timer.periodic(refreshEvery, (_) {
      if (online) refreshLevels();
    });
  }

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
    String? preferenceError;
    try {
      await _preferences.saveArrivalTime(arrivalAt);
    } catch (e) {
      preferenceError = errorMessageFor(e);
      debugPrint('arrival time could not be saved: $e');
    }
    _telemetry.track('forecast_viewed', {'source': 'arrival_time_changed'});
    notifyListeners();
    await _loadForecast();
    forecastErrorMessage ??= preferenceError;
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
    final requestDate = _dateKey(arrivalAt);
    if (_forecastDateKey != requestDate) {
      _forecasts = const [];
      recommendation = null;
      forecastSavedAt = null;
      forecastFromCache = false;
      _forecastDateKey = requestDate;
    }
    forecastErrorMessage = null;
    try {
      _forecasts = await _parking.getPredictions(date: arrivalAt);
      forecastFromCache = false;
      forecastSavedAt = _clock();
      recommendation = _recommendFromForecast(_forecasts, arrivalAt);
      try {
        await _forecastStore?.write(arrivalAt, _forecasts);
      } catch (e) {
        forecastErrorMessage = errorMessageFor(e);
        debugPrint('forecast cache write failed: $e');
      }
      _reportForecastViewed();
    } catch (e) {
      if (e is! NetworkException &&
          !(e is ApiException && e.statusCode >= 500)) {
        forecastErrorMessage = errorMessageFor(e);
        debugPrint('predictions request failed: $e');
        return;
      }
      try {
        final cached = await _forecastStore?.read(arrivalAt);
        if (cached == null) {
          forecastErrorMessage = errorMessageFor(e);
          debugPrint('predictions failed without a saved copy: $e');
          return;
        }
        _forecasts = cached.data;
        forecastFromCache = true;
        forecastSavedAt = cached.savedAt;
        recommendation = _recommendFromForecast(_forecasts, arrivalAt);
        _reportForecastViewed();
      } catch (cacheError) {
        forecastErrorMessage = errorMessageFor(cacheError);
        debugPrint('saved forecast could not be read: $cacheError');
      }
    }
  }

  Future<void> _prefetchLevels() async {
    await Future.wait([
      for (final code in ['P1', 'P2', 'P3'])
        () async {
          try {
            await _parking.getSpots(
              code,
              destination: _preferences.destination,
            );
          } catch (e) {
            debugPrint('level $code prefetch failed: $e');
          }
        }(),
    ]);
  }

  static DateTime _restoreArrivalTime(DateTime? savedAt, DateTime now) {
    if (savedAt == null) return now.add(defaultLead);
    if (savedAt.isAfter(now)) return savedAt;
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      savedAt.hour,
      savedAt.minute,
    );
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  static LevelRecommendation _recommendFromForecast(
    List<LevelForecast> forecasts,
    DateTime arrivalAt,
  ) {
    final minute = arrivalAt.minute - arrivalAt.minute % 15;
    final slot =
        '${arrivalAt.hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
    final predictions = {
      for (final level in forecasts)
        level.code: level.points
            .where((point) => point.slot == slot)
            .firstOrNull
            ?.occupancy,
    };
    final ranked = predictions.entries
        .where((entry) => entry.value != null)
        .toList()
      ..sort((a, b) {
        final occupancyOrder = a.value!.compareTo(b.value!);
        return occupancyOrder != 0
            ? occupancyOrder
            : a.key.compareTo(b.key);
      });
    return LevelRecommendation(
      arrivalAt: arrivalAt,
      slot: slot,
      recommended: ranked.firstOrNull?.key,
      predictions: predictions,
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _reportForecastViewed() {
    if (!_visible || _forecastReportedForVisit || forecast.isEmpty) return;
    _forecastReportedForVisit = true;
    _telemetry.track('forecast_viewed', {'source': 'home_forecast'});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
