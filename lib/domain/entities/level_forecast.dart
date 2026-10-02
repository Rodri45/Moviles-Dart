// un punto de la prediccion: en el slot "08:15" el nivel va a estar asi de
// lleno (de 0 a 1). null si no hay historia para ese slot
class ForecastPoint {
  const ForecastPoint({required this.slot, required this.occupancy});

  factory ForecastPoint.fromJson(Map<String, dynamic> json) => ForecastPoint(
    slot: json['slot'] as String,
    occupancy: (json['occupancy'] as num?)?.toDouble(),
  );

  final String slot;
  final double? occupancy;

  int get hour => int.parse(slot.substring(0, 2));
}

// la prediccion del dia para un nivel, 96 puntos de 15 minutos
class LevelForecast {
  const LevelForecast({required this.code, required this.points});

  factory LevelForecast.fromJson(Map<String, dynamic> json) => LevelForecast(
    code: json['code'] as String,
    points: [
      for (final point in json['points'] as List)
        ForecastPoint.fromJson(point as Map<String, dynamic>),
    ],
  );

  final String code;
  final List<ForecastPoint> points;
}

// una barra de la grafica de home
class HourlyOccupancy {
  const HourlyOccupancy({required this.hour, required this.occupancy});

  final int hour;
  final double? occupancy;
}

// junta los slots de 15 min de todos los niveles en un promedio por hora.
// los slots sin datos no cuentan en el promedio
List<HourlyOccupancy> hourlyOccupancy(List<LevelForecast> forecasts) {
  final sums = List<double>.filled(24, 0);
  final counts = List<int>.filled(24, 0);
  for (final forecast in forecasts) {
    for (final point in forecast.points) {
      final value = point.occupancy;
      if (value == null) continue;
      sums[point.hour] += value;
      counts[point.hour]++;
    }
  }
  return [
    for (var hour = 0; hour < 24; hour++)
      HourlyOccupancy(
        hour: hour,
        occupancy: counts[hour] == 0 ? null : sums[hour] / counts[hour],
      ),
  ];
}
