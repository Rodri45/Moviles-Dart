class DayForecast {
  const DayForecast({required this.date, required this.levels});

  final DateTime date;
  final Map<String, List<double?>> levels;

  int get number => dayNumber(date);
}

class WeekForecast {
  const WeekForecast({required this.hours, required this.days});

  factory WeekForecast.fromApi(Map<String, dynamic> json) {
    final days = <String, Map<String, List<double?>>>{};
    for (final item in json['levels'] as List) {
      final level = item as Map<String, dynamic>;
      final code = level['code'] as String;
      for (final entry in level['days'] as List) {
        final day = entry as Map<String, dynamic>;
        days.putIfAbsent(day['date'] as String, () => {})[code] = _occupancy(
          day['occupancy'] as List,
        );
      }
    }
    return WeekForecast(
      hours: _hours(json['hours'] as List),
      days: [
        for (final entry in days.entries)
          DayForecast(date: DateTime.parse(entry.key), levels: entry.value),
      ]..sort((a, b) => a.date.compareTo(b.date)),
    );
  }

  factory WeekForecast.merge(Iterable<WeekForecast> parts) {
    final days = <int, DayForecast>{};
    var hours = const <int>[];
    for (final part in parts) {
      hours = part.hours;
      for (final day in part.days) {
        final known = days[day.number];
        days[day.number] = DayForecast(
          date: day.date,
          levels: {...?known?.levels, ...day.levels},
        );
      }
    }
    return WeekForecast(
      hours: hours,
      days: days.values.toList()..sort((a, b) => a.date.compareTo(b.date)),
    );
  }

  final List<int> hours;
  final List<DayForecast> days;

  static List<int> _hours(List<dynamic> values) => [
    for (final hour in values) (hour as num).toInt(),
  ];

  static List<double?> _occupancy(List<dynamic> values) => [
    for (final value in values) (value as num?)?.toDouble(),
  ];
}

int dayNumber(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;

String isoDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
