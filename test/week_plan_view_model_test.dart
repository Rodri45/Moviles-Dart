import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/week_forecast.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/presentation/screens/week_plan/week_heat_map.dart';
import 'package:parkwise/presentation/screens/week_plan/week_plan_view_model.dart';

class _WeekParking extends MockParkingRepository {
  final List<String> asked = [];
  final Set<String> failing = {};
  final Map<String, Completer<void>> gates = {};

  @override
  Future<WeekForecast> getWeekForecast(
    String level, {
    required DateTime from,
  }) async {
    asked.add(level);
    await gates[level]?.future;
    if (failing.contains(level)) throw const NetworkException('offline');
    return super.getWeekForecast(level, from: from);
  }
}

void main() {
  final now = DateTime(2026, 11, 23, 6);
  late _WeekParking parking;
  late MockPreferencesStore preferences;
  late WeekPlanViewModel week;

  setUp(() {
    parking = _WeekParking();
    preferences = MockPreferencesStore(
      arrivalTime: DateTime(2026, 11, 20, 8, 30),
    );
    week = WeekPlanViewModel(
      parking,
      preferences,
      buildHeatMap: buildHeatMapInline,
      clock: () => now,
    );
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

  test('without any level the error is shown', () async {
    parking.failing.addAll(WeekPlanViewModel.levelCodes);

    await week.open();

    expect(week.hasWeek, isFalse);
    expect(week.errorMessage, isNotNull);
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
}
