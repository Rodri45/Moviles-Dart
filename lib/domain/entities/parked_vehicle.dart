/// Dónde quedó parqueado el carro del usuario. Se usa en "Find my car".
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
