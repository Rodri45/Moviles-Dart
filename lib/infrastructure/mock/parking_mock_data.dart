import '../../domain/entities/forecast.dart';
import '../../domain/entities/parked_vehicle.dart';
import '../../domain/entities/parking_level.dart';
import '../../domain/entities/parking_lot.dart';
import '../../domain/entities/parking_spot.dart';

// datos inventados mientras no hay backend
abstract final class ParkingMockData {
  static final List<ParkingLot> lots = [
    ParkingLot(
      id: 'p1',
      name: 'P1 · North',
      zone: 'North campus',
      distanceMeters: 120,
      levels: [
        ParkingLevel(id: 'p1-l1', name: 'Level 1', spots: _spots('A', 20, 4)),
        ParkingLevel(id: 'p1-l2', name: 'Level 2', spots: _spots('B', 20, 11)),
        ParkingLevel(id: 'p1-l3', name: 'Level 3', spots: _spots('C', 20, 17)),
      ],
    ),
    ParkingLot(
      id: 'p2',
      name: 'P2 · Library',
      zone: 'Central campus',
      distanceMeters: 340,
      levels: [
        ParkingLevel(id: 'p2-l1', name: 'Level 1', spots: _spots('A', 16, 1)),
        ParkingLevel(id: 'p2-l2', name: 'Level 2', spots: _spots('B', 16, 0)),
      ],
    ),
    ParkingLot(
      id: 'p3',
      name: 'P3 · South',
      zone: 'South campus',
      distanceMeters: 610,
      levels: [
        ParkingLevel(id: 'p3-l1', name: 'Level 1', spots: _spots('A', 24, 0)),
      ],
    ),
  ];

  static final Forecast forecastP1 = Forecast(
    lotId: 'p1',
    points: const [
      ForecastPoint(hour: 7, occupancy: 0.30),
      ForecastPoint(hour: 8, occupancy: 0.65),
      ForecastPoint(hour: 9, occupancy: 0.90),
      ForecastPoint(hour: 10, occupancy: 0.95),
      ForecastPoint(hour: 11, occupancy: 0.92),
      ForecastPoint(hour: 12, occupancy: 0.80),
      ForecastPoint(hour: 13, occupancy: 0.75),
      ForecastPoint(hour: 14, occupancy: 0.85),
      ForecastPoint(hour: 15, occupancy: 0.70),
      ForecastPoint(hour: 16, occupancy: 0.50),
      ForecastPoint(hour: 17, occupancy: 0.35),
      ForecastPoint(hour: 18, occupancy: 0.20),
    ],
  );

  static final ParkedVehicle parkedVehicle = ParkedVehicle(
    lotId: 'p1',
    lotName: 'P1 · North',
    levelName: 'Level 2',
    spotCode: 'B-07',
    parkedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 14)),
  );

  // arma una lista de puestos, los primeros [free] quedan libres y el resto ocupados
  static List<ParkingSpot> _spots(String row, int count, int free) {
    return List.generate(count, (i) {
      final number = (i + 1).toString().padLeft(2, '0');
      return ParkingSpot(
        id: '$row-$number',
        code: '$row-$number',
        state: i < free ? SpotState.free : SpotState.occupied,
        isAccessible: i == 0,
        isEv: i == 1,
      );
    });
  }
}
