import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/saved.dart';
import 'package:parkwise/domain/entities/week_forecast.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/mock/memory_week_forecast_store.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/infrastructure/mock/parking_mock_data.dart';
import 'package:parkwise/presentation/screens/week_plan/week_heat_map.dart';
import 'package:parkwise/presentation/screens/week_plan/week_plan_view_model.dart';

class _WeekParking extends MockParkingRepository {
  final List<String> asked = [];
  final Set<String> failing = {};
  final Map<String, Completer<void>> gates = {};
  Exception error = const NetworkException('offline');

  @override
  Future<WeekForecast> getWeekForecast(
    String level, {
    required DateTime from,
  }) async {
    asked.add(level);
    await gates[level]?.future;
    if (failing.contains(level)) throw error;
    return super.getWeekForecast(level, from: from);
  }
}

class _BrokenStore extends MemoryWeekForecastStore {
  @override
  Future<void> write(WeekForecast week, {required DateTime savedAt}) async {
    throw const FileSystemException('disk full');
  }
}

void main() {
  late DateTime now;
  late _WeekParking parking;
  late MockPreferencesStore preferences;
  late MemoryWeekForecastStore store;
  late MockConnectivity connectivity;
  late WeekPlanViewModel week;

  WeekPlanViewModel planner() => WeekPlanViewModel(
    parking,
    preferences,
    store,
    connectivity,
    buildHeatMap: buildHeatMapInline,
    clock: () => now,
  );

  setUp(() {
    now = DateTime(2026, 11, 23, 6);
    parking = _WeekParking();
    preferences = MockPreferencesStore(
      arrivalTime: DateTime(2026, 11, 20, 8, 30),
    );
    store = MemoryWeekForecastStore();
    connectivity = MockConnectivity();
    week = planner();
  });

  tearDown(() => week.dispose());

  test('the three levels are asked at the same time', () async {
    for (final code in WeekPlanViewModel.levelCodes) {
      parking.gates[code] = Completer<void>();
    }

    final opening = week.open();
    await pumpEventQueue();
    expect(parking.asked, ['P1', 'P2', 'P3']);
    expect(week.isLoading, isTrue);

    for (final gate in parking.gates.values.toList().reversed) {
      gate.complete();
    }
    await opening;

    expect(week.isLoading, isFalse);
    expect(week.hasWeek, isTrue);
  });

  test('the plan starts today and follows the arrival time', () async {
    await week.open();

    expect(week.hours.first, 6);
    expect(week.heatMap.rows, hasLength(7));
    expect(week.heatMap.rows.first.date, DateTime(2026, 11, 23));
    expect(week.heatMap.best, hasLength(bestTimesShown));
    for (final time in week.heatMap.best) {
      expect(time.start.weekday, lessThanOrEqualTo(DateTime.friday));
      expect((time.start.hour - 8).abs(), lessThanOrEqualTo(1));
    }
    expect(week.updatedAt, now);
  });

  test('a level that fails does not hide the other two', () async {
    parking.failing.add('P3');

    await week.open();

    expect(week.errorMessage, contains('P3'));
    expect(week.heatMap.rows.first.saved, isTrue);

    await week.selectLevel('P3');
    expect(week.heatMap.rows.every((row) => !row.saved), isTrue);
    expect(week.heatMap.best, isEmpty);
  });

  test('a server answer that is not a network failure is shown', () async {
    parking
      ..error = const ApiException(400, 'Invalid date')
      ..failing.addAll(WeekPlanViewModel.levelCodes);

    await week.open();

    expect(week.hasWeek, isFalse);
    expect(week.unreachable, isFalse);
    expect(week.errorMessage, 'Invalid date');
  });

  test('changing the level or the arrival builds the plan again', () async {
    await week.open();
    final busiest = week.heatMap.best.first.occupancy;

    await week.selectLevel('P3');
    expect(week.level, 'P3');
    expect(week.heatMap.best.first.occupancy, lessThan(busiest));

    await week.setArrivalTime(14, 0);
    for (final time in week.heatMap.best) {
      expect(time.start.hour, inInclusiveRange(13, 15));
    }
    expect(parking.asked, hasLength(3));
  });

  test('coming back within ten minutes uses the days in memory', () async {
    await week.open();
    now = now.add(const Duration(minutes: 9));
    await week.open();
    expect(parking.asked, hasLength(3));
    expect(week.updatedAt, DateTime(2026, 11, 23, 6));

    now = now.add(const Duration(minutes: 2));
    await week.open();
    expect(parking.asked, hasLength(6));

    await week.refresh();
    expect(parking.asked, hasLength(9));
  });

  test('the chosen level is kept for the next visit', () async {
    await week.open();
    await week.selectLevel('P2');
    expect(preferences.plannerLevel, 'P2');

    final next = planner();
    addTearDown(next.dispose);
    await next.open();
    expect(next.level, 'P2');
  });

  test('the week is saved in the file without waiting for it', () async {
    await week.open();
    await pumpEventQueue();

    expect(store.saved?.savedAt, now);
    expect(store.saved?.data.days, hasLength(7));
    expect(week.savedOnPhone, isTrue);
  });

  test('a file that cannot be written does not stop the plan', () async {
    store = _BrokenStore();
    week.dispose();
    week = planner();

    await week.open();
    await pumpEventQueue();

    expect(week.heatMap.best, isNotEmpty);
    expect(week.savedOnPhone, isFalse);
    expect(week.errorMessage, isNull);
  });

  test('without signal the saved days are shown with their date', () async {
    final savedAt = DateTime(2026, 11, 20, 7, 2);
    store.saved = Saved(
      WeekForecast.merge([
        for (final code in WeekPlanViewModel.levelCodes)
          ParkingMockData.week(code, DateTime(2026, 11, 20)),
      ]),
      savedAt: savedAt,
      fromStorage: true,
    );
    parking.failing.addAll(WeekPlanViewModel.levelCodes);

    await week.open();

    expect(week.fromStorage, isTrue);
    expect(week.showingSavedData, isTrue);
    expect(week.updatedAt, savedAt);
    expect(week.missingDays, [
      DateTime(2026, 11, 27),
      DateTime(2026, 11, 28),
      DateTime(2026, 11, 29),
    ]);
    expect(week.heatMap.rows.map((row) => row.saved), [
      true,
      true,
      true,
      true,
      false,
      false,
      false,
    ]);
    expect(
      week.heatMap.best.every((time) => time.start.day <= 26),
      isTrue,
    );
  });

  test('without signal and without a saved week it says so', () async {
    parking.failing.addAll(WeekPlanViewModel.levelCodes);

    await week.open();

    expect(week.unreachable, isTrue);
    expect(week.hasWeek, isFalse);
    expect(week.showingSavedData, isTrue);
  });

  test('when the signal returns the week is asked again', () async {
    connectivity = MockConnectivity(online: false);
    week.dispose();
    week = planner();
    await pumpEventQueue();
    parking.failing.addAll(WeekPlanViewModel.levelCodes);
    await week.open();
    expect(week.unreachable, isTrue);

    parking.failing.clear();
    connectivity.setOnline(true);
    await pumpEventQueue();

    expect(week.unreachable, isFalse);
    expect(week.fromStorage, isFalse);
    expect(week.hasWeek, isTrue);
  });
}
