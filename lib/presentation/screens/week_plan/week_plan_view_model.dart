import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/cache/sparse_array_cache.dart';
import '../../../domain/entities/week_forecast.dart';
import '../../../domain/errors.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/week_forecast_store.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';
import 'week_heat_map.dart';

class WeekPlanViewModel extends ChangeNotifier with ConnectivityAware {
  WeekPlanViewModel(
    this._parking,
    this._preferences,
    this._store,
    ConnectivityPort connectivity, {
    this._buildHeatMap = buildHeatMapInBackground,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _memory = SparseArrayCache(
         maxEntries: memoryDays,
         ttl: memoryTtl,
         clock: clock,
       ) {
    watchConnectivity(connectivity, load);
  }

  static const levelCodes = ['P1', 'P2', 'P3'];

  static const weekLength = 7;

  static const defaultLead = Duration(minutes: 20);

  static const memoryDays = 7;

  static const memoryTtl = Duration(minutes: 10);

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final WeekForecastStore _store;
  final HeatMapBuilder _buildHeatMap;
  final DateTime Function() _clock;
  final SparseArrayCache<DayForecast> _memory;
  Map<int, DayForecast> _days = const {};
  int _generation = 0;
  bool _disposed = false;

  String level = levelCodes.first;
  late DateTime arrivalAt = _clock().add(defaultLead);
  List<int> hours = const [];
  WeekHeatMap heatMap = WeekHeatMap.empty;
  DateTime? updatedAt;
  bool fromStorage = false;
  bool unreachable = false;
  bool savedOnPhone = false;
  bool isLoading = false;
  String? errorMessage;

  List<DateTime> get days {
    final now = _clock();
    return [
      for (var offset = 0; offset < weekLength; offset++)
        DateTime(now.year, now.month, now.day + offset),
    ];
  }

  bool get hasWeek => _days.isNotEmpty;

  List<DateTime> get missingDays => [
    for (final date in days)
      if (_days[dayNumber(date)]?.levels[level] == null) date,
  ];

  @override
  bool get showingSavedData => fromStorage || unreachable;

  Future<void> open() {
    arrivalAt = _preferences.arrivalTime ?? _clock().add(defaultLead);
    final saved = _preferences.plannerLevel;
    if (saved != null && levelCodes.contains(saved)) level = saved;
    return load();
  }

  Future<void> refresh() => load(refresh: true);

  Future<void> load({bool refresh = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final remembered = refresh ? null : _fromMemory();
    if (remembered != null) {
      unreachable = false;
      _show(
        remembered,
        at: _memory.storedAt(dayNumber(days.first)) ?? _clock(),
      );
    } else {
      await _fetchWeek(days.first);
    }
    isLoading = false;
    await _updateHeatMap();
    notifyListeners();
  }

  Future<void> selectLevel(String code) async {
    if (code == level) return;
    level = code;
    notifyListeners();
    unawaited(
      _preferences
          .savePlannerLevel(code)
          .catchError((Object e) => debugPrint('level not saved: $e')),
    );
    await _updateHeatMap();
    notifyListeners();
  }

  Future<void> setArrivalTime(int hour, int minute) async {
    final now = _clock();
    arrivalAt = DateTime(now.year, now.month, now.day, hour, minute);
    notifyListeners();
    await _updateHeatMap();
    notifyListeners();
  }

  WeekForecast? _fromMemory() {
    final remembered = <DayForecast>[];
    for (final date in days) {
      final day = _memory.get(dayNumber(date));
      if (day == null || !levelCodes.every(day.levels.containsKey)) {
        return null;
      }
      remembered.add(day);
    }
    return WeekForecast(hours: hours, days: remembered);
  }

  Future<void> _fetchWeek(DateTime from) async {
    final parts = <WeekForecast>[];
    final failed = <String, Object>{};

    Future<void> fetchLevel(String code) async {
      try {
        parts.add(await _parking.getWeekForecast(code, from: from));
      } catch (e) {
        failed[code] = e;
        debugPrint('week of $code failed: $e');
      }
    }

    await Future.wait([for (final code in levelCodes) fetchLevel(code)]);

    unreachable = parts.isEmpty && failed.values.every(_isUnreachable);
    if (unreachable) {
      await _showSaved();
      return;
    }
    if (parts.isEmpty) {
      errorMessage = errorMessageFor(failed.values.first);
      return;
    }
    final week = WeekForecast.merge(parts);
    _show(week, at: _clock());
    for (final day in week.days) {
      _memory.put(day.number, day);
    }
    if (failed.isEmpty) {
      _save(week);
    } else {
      errorMessage =
          'The week of ${failed.keys.join(', ')} could not be loaded. '
          'Pull down to try again.';
    }
  }

  Future<void> _showSaved() async {
    try {
      final saved = await _store.read();
      if (saved != null) {
        _show(saved.data, at: saved.savedAt, fromStorage: true);
        return;
      }
    } catch (e) {
      debugPrint('saved week could not be read: $e');
    }
    fromStorage = hasWeek;
  }

  void _show(
    WeekForecast week, {
    required DateTime at,
    bool fromStorage = false,
  }) {
    hours = week.hours;
    _days = {for (final day in week.days) day.number: day};
    updatedAt = at;
    this.fromStorage = fromStorage;
  }

  void _save(WeekForecast week) {
    unawaited(
      _store
          .write(week, savedAt: _clock())
          .then<void>((_) => _markSaved(true))
          .catchError((Object e) {
            debugPrint('week file not saved: $e');
            _markSaved(false);
          }),
    );
  }

  void _markSaved(bool saved) {
    if (_disposed) return;
    savedOnPhone = saved;
    notifyListeners();
  }

  Future<void> _updateHeatMap() async {
    final generation = ++_generation;
    final request = HeatMapRequest(
      hours: hours,
      days: [
        for (final date in days)
          (date: date, occupancy: _days[dayNumber(date)]?.levels[level]),
      ],
      arrivalHour: arrivalAt.hour,
      now: _clock(),
    );
    final result = await _buildHeatMap(request);
    if (generation == _generation) heatMap = result;
  }

  static bool _isUnreachable(Object error) =>
      error is NetworkException ||
      (error is ApiException && error.statusCode >= 500);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
