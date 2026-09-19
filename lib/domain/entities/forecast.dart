/// Pronóstico de ocupación de un parqueadero para una hora concreta.
///
/// Se muestra en `ForecastCard`.
class ForecastPoint {
  const ForecastPoint({required this.hour, required this.occupancy});

  /// Hora del día (0-23).
  final int hour;

  /// Ocupación estimada, entre 0.0 y 1.0.
  final double occupancy;
}

class Forecast {
  const Forecast({required this.lotId, required this.points});

  final String lotId;
  final List<ForecastPoint> points;
}
