import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/presentation/screens/week_plan/week_heat_map.dart';

void main() {
  final monday = DateTime(2026, 11, 23);
  final tuesday = DateTime(2026, 11, 24);
  final wednesday = DateTime(2026, 11, 25);
  final saturday = DateTime(2026, 11, 28);

  HeatMapRequest request({int arrivalHour = 8}) => HeatMapRequest(
    hours: const [7, 8, 9, 10],
    days: [
      (date: monday, occupancy: const [0.9, 0.5, 0.1, 0.0]),
      (date: tuesday, occupancy: const [0.3, 0.2, 0.95, 0.0]),
      (date: wednesday, occupancy: null),
      (date: saturday, occupancy: const [0.0, 0.0, 0.0, 0.0]),
    ],
    arrivalHour: arrivalHour,
    now: DateTime(2026, 11, 23, 7, 30),
  );

  test('best times are the emptiest weekday hours near the arrival', () {
    final heatMap = buildHeatMap(request());

    expect(heatMap.best.map((time) => time.start), [
      DateTime(2026, 11, 23, 9),
      DateTime(2026, 11, 24, 8),
      DateTime(2026, 11, 24, 7),
    ]);
    expect(heatMap.best.first.occupancy, 0.1);
  });

  test('hours that already started and weekends are never suggested', () {
    final heatMap = buildHeatMap(request(arrivalHour: 7));

    expect(
      heatMap.best.map((time) => time.start),
      isNot(contains(DateTime(2026, 11, 23, 7))),
    );
    expect(heatMap.best.every((time) => time.start.day != 28), isTrue);
  });

  test('each hour gets a color step and the best ones are marked', () {
    final heatMap = buildHeatMap(request());
    final mondayRow = heatMap.rows.first;

    expect(heatMap.rows.map((row) => row.date), [
      monday,
      tuesday,
      wednesday,
      saturday,
    ]);
    expect(mondayRow.cells.map((cell) => cell.step), [5, 2, 0, 0]);
    expect(mondayRow.cells.map((cell) => cell.best), [
      false,
      false,
      true,
      false,
    ]);
    expect(heatMap.rows[2].saved, isFalse);
    expect(heatMap.rows[2].cells.every((cell) => cell.step == null), isTrue);
  });

  test('the background and inline builders give the same plan', () async {
    final inBackground = await buildHeatMapInBackground(request());
    final inline = await buildHeatMapInline(request());

    expect(
      inBackground.best.map((time) => time.start),
      inline.best.map((time) => time.start),
    );
  });
}
