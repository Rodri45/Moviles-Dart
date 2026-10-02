enum OccupancyStatus { available, limited, full, offline }

// un piso del parqueadero (P1, P2, P3) con el conteo que manda el backend
class ParkingLevel {
  const ParkingLevel({
    required this.code,
    required this.name,
    required this.underground,
    required this.total,
    required this.free,
    required this.reserved,
    required this.occupied,
  });

  factory ParkingLevel.fromJson(Map<String, dynamic> json) => ParkingLevel(
    code: json['code'] as String,
    name: json['name'] as String,
    underground: json['underground'] as bool,
    total: (json['total'] as num).toInt(),
    free: (json['free'] as num).toInt(),
    reserved: (json['reserved'] as num).toInt(),
    occupied: (json['occupied'] as num).toInt(),
  );

  final String code;
  final String name;
  final bool underground;
  final int total;
  final int free;
  final int reserved;
  final int occupied;

  double get occupancy => total == 0 ? 0 : (reserved + occupied) / total;

  OccupancyStatus get status {
    if (total == 0) return OccupancyStatus.offline;
    if (free == 0) return OccupancyStatus.full;
    if (free / total < 0.15) return OccupancyStatus.limited;
    return OccupancyStatus.available;
  }
}
