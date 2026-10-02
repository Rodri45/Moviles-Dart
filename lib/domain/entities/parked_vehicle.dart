// donde quedo parqueado el carro segun el backend (GET /vehicle)
class ParkedVehicle {
  const ParkedVehicle({
    required this.spotId,
    required this.spotCode,
    required this.levelCode,
    required this.zone,
    required this.parkedAt,
  });

  factory ParkedVehicle.fromJson(Map<String, dynamic> json) => ParkedVehicle(
    spotId: json['spotId'] as String,
    spotCode: json['spotCode'] as String,
    levelCode: json['levelCode'] as String,
    zone: json['zone'] as String,
    parkedAt: DateTime.parse(json['parkedAt'] as String),
  );

  final String spotId;
  final String spotCode;
  final String levelCode;
  final String zone;
  final DateTime parkedAt;
}
