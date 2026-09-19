import 'parking_spot.dart';

/// Un nivel/piso dentro de un parqueadero (ej. "Level 2").
class ParkingLevel {
  const ParkingLevel({
    required this.id,
    required this.name,
    required this.spots,
  });

  final String id;
  final String name;
  final List<ParkingSpot> spots;

  int get totalSpots => spots.length;
  int get freeSpots => spots.where((s) => s.state == SpotState.free).length;
}
