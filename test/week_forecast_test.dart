import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/week_forecast.dart';

void main() {
  WeekForecast level(String code, List<DateTime> dates, double value) =>
      WeekForecast(
        hours: const [6, 7],
        days: [
          for (final date in dates)
            DayForecast(
              date: date,
              levels: {
                code: [value, value],
              },
            ),
        ],
      );

  test('the weeks of each level are joined by day', () {
    final monday = DateTime(2026, 11, 23);
    final tuesday = DateTime(2026, 11, 24);

    final week = WeekForecast.merge([
      level('P2', [tuesday, monday], 0.4),
      level('P1', [monday], 0.9),
    ]);

    expect(week.hours, [6, 7]);
    expect(week.days.map((day) => day.date), [monday, tuesday]);
    expect(week.days.first.levels.keys, unorderedEquals(['P1', 'P2']));
    expect(week.days.last.levels.keys, ['P2']);
    expect(week.days.first.number, 20261123);
  });

  test('a day is written as yyyy-mm-dd', () {
    expect(isoDay(DateTime(2026, 1, 5, 18)), '2026-01-05');
  });
}
