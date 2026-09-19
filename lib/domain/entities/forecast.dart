// un punto de la grafica: a tal hora va a estar tal porcentaje de lleno
class ForecastPoint {
  const ForecastPoint({required this.hour, required this.occupancy});

  // hora de 0 a 23
  final int hour;

  // de 0.0 a 1.0
  final double occupancy;
}

// la grafica completa de un parqueadero
class Forecast {
  const Forecast({required this.lotId, required this.points});

  final String lotId;
  final List<ForecastPoint> points;
}
