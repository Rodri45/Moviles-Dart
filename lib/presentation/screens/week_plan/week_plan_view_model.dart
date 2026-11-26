import 'package:flutter/foundation.dart';

import '../../../domain/entities/week_forecast.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../shared/error_messages.dart';
import 'week_heat_map.dart';

class WeekPlanViewModel extends ChangeNotifier {
  WeekPlanViewModel(
    this._parking,
    this._preferences, {
    this._buildHeatMap = buildHeatMapInBackground,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const levelCodes = ['P1', 'P2', 'P3'];

  static const weekLength = 7;

  static const defaultLead = Duration(minutes: 20);

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final HeatMapBuilder _buildHeatMap;
  final DateTime Function() _clock;
  Map<int, DayForecast> _days = const {};
  int _generation = 0;

  String level = levelCodes.first;
  late DateTime arrivalAt = _clock().add(defaultLead);
  List<int> hours = const [];
  WeekHeatMap heatMap = WeekHeatMap.empty;
  DateTime? updatedAt;
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

  Future<void> open() {
    arrivalAt = _preferences.arrivalTime ?? _clock().add(defaultLead);
    return load();
  }

  Future<void> refresh() => load();

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    await _fetchWeek(days.first);
    isLoading = false;
    await _updateHeatMap();
    notifyListeners();
  }

  Future<void> selectLevel(String code) async {
    if (code == level) return;
    level = code;
    notifyListeners();
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

    if (parts.isEmpty) {
      errorMessage = errorMessageFor(failed.values.first);
      return;
    }
    _show(WeekForecast.merge(parts), at: _clock());
    if (failed.isNotEmpty) {
      errorMessage =
          'The week of ${failed.keys.join(', ')} could not be loaded. '
          'Pull down to try again.';
    }
  }

  void _show(WeekForecast week, {required DateTime at}) {
    hours = week.hours;
    _days = {for (final day in week.days) day.number: day};
    updatedAt = at;
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
}
