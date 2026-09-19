import 'parking_spot.dart';

// un piso del parqueadero con sus puestos
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
