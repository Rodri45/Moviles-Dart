import 'geo_point.dart';

// lo que se guarda en el celular al hacer check-in, para que find my car
// funcione aunque se cierre la app o no haya red
class CarLocation {
  const CarLocation({
    required this.levelCode,
    required this.spotCode,
    required this.savedAt,
    this.position,
  });

  factory CarLocation.fromJson(Map<String, dynamic> json) => CarLocation(
    levelCode: json['levelCode'] as String,
    spotCode: json['spotCode'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
    position: json['position'] == null
        ? null
        : GeoPoint.fromJson(json['position'] as Map<String, dynamic>),
  );

  final String levelCode;
  final String spotCode;
  final DateTime savedAt;

  // null si no habia gps al parquear (por ejemplo en P2 o P3)
  final GeoPoint? position;

  Map<String, dynamic> toJson() => {
    'levelCode': levelCode,
    'spotCode': spotCode,
    'savedAt': savedAt.toIso8601String(),
    'position': position?.toJson(),
  };
}
