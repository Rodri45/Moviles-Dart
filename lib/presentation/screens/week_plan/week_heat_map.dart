import 'package:flutter/foundation.dart';

class HeatMapRequest {
  const HeatMapRequest({
    required this.hours,
    required this.days,
    required this.arrivalHour,
    required this.now,
  });

  final List<int> hours;
  final List<({DateTime date, List<double?>? occupancy})> days;
  final int arrivalHour;
  final DateTime now;
}

class HeatCell {
  const HeatCell({this.step, this.occupancy, this.best = false});

  final int? step;
  final double? occupancy;
  final bool best;
}

class HeatRow {
  const HeatRow({required this.date, required this.saved, required this.cells});

  final DateTime date;
  final bool saved;
  final List<HeatCell> cells;
}

class BestTime {
  const BestTime({required this.start, required this.occupancy});

  final DateTime start;
  final double occupancy;
}

class WeekHeatMap {
  const WeekHeatMap({required this.rows, required this.best});

  static const empty = WeekHeatMap(rows: [], best: []);

  final List<HeatRow> rows;
  final List<BestTime> best;
}

typedef HeatMapBuilder = Future<WeekHeatMap> Function(HeatMapRequest request);

const heatSteps = [0.20, 0.40, 0.60, 0.75, 0.90];

const nearArrivalHours = 1;

const bestTimesShown = 3;

Future<WeekHeatMap> buildHeatMapInBackground(HeatMapRequest request) =>
    compute(buildHeatMap, request, debugLabel: 'week-heat-map');

Future<WeekHeatMap> buildHeatMapInline(HeatMapRequest request) async =>
    buildHeatMap(request);

WeekHeatMap buildHeatMap(HeatMapRequest request) {
  final candidates = <BestTime>[];
  for (final day in request.days) {
    final values = day.occupancy;
    if (values == null || day.date.weekday > DateTime.friday) continue;
    for (var index = 0; index < request.hours.length; index++) {
      final hour = request.hours[index];
      final value = index < values.length ? values[index] : null;
      final start = DateTime(
        day.date.year,
        day.date.month,
        day.date.day,
        hour,
      );
      if (value == null ||
          (hour - request.arrivalHour).abs() > nearArrivalHours ||
          !start.isAfter(request.now)) {
        continue;
      }
      candidates.add(BestTime(start: start, occupancy: value));
    }
  }
  candidates.sort((a, b) {
    final byOccupancy = a.occupancy.compareTo(b.occupancy);
    return byOccupancy != 0 ? byOccupancy : a.start.compareTo(b.start);
  });
  final best = candidates.take(bestTimesShown).toList();

  return WeekHeatMap(
    best: best,
    rows: [
      for (final day in request.days)
        HeatRow(
          date: day.date,
          saved: day.occupancy != null,
          cells: [
            for (var index = 0; index < request.hours.length; index++)
              _cell(day, request.hours[index], index, best),
          ],
        ),
    ],
  );
}

HeatCell _cell(
  ({DateTime date, List<double?>? occupancy}) day,
  int hour,
  int index,
  List<BestTime> best,
) {
  final values = day.occupancy;
  final value = values != null && index < values.length ? values[index] : null;
  if (value == null) return const HeatCell();
  return HeatCell(
    step: heatSteps.where((limit) => value >= limit).length,
    occupancy: value,
    best: best.any(
      (time) =>
          time.start.hour == hour &&
          time.start.year == day.date.year &&
          time.start.month == day.date.month &&
          time.start.day == day.date.day,
    ),
  );
}
