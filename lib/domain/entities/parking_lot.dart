import 'parking_level.dart';

enum OccupancyStatus { available, limited, full, offline }

// un parqueadero, tipo "P1 · North", con sus niveles
class ParkingLot {
  const ParkingLot({
    required this.id,
    required this.name,
    required this.zone,
    required this.levels,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String zone;
  final List<ParkingLevel> levels;
  final int? distanceMeters;

  int get totalSpots => levels.fold(0, (sum, l) => sum + l.totalSpots);
  int get freeSpots => levels.fold(0, (sum, l) => sum + l.freeSpots);

  OccupancyStatus get status {
    if (totalSpots == 0) return OccupancyStatus.offline;
    if (freeSpots == 0) return OccupancyStatus.full;
    if (freeSpots / totalSpots < 0.15) return OccupancyStatus.limited;
    return OccupancyStatus.available;
  }
}
