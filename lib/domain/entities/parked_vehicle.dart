// donde quedo parqueado el carro, para la pantalla de find my car
class ParkedVehicle {
  const ParkedVehicle({
    required this.lotId,
    required this.lotName,
    required this.levelName,
    required this.spotCode,
    required this.parkedAt,
  });

  final String lotId;
  final String lotName;
  final String levelName;
  final String spotCode;
  final DateTime parkedAt;
}
