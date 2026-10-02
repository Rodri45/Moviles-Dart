import '../../domain/entities/building.dart';
import '../../domain/entities/level_forecast.dart';
import '../../domain/entities/levels_overview.dart';
import '../../domain/entities/nearby_lot.dart';
import '../../domain/entities/parking_level.dart';
import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/reservation.dart';

// datos inventados con la misma forma que el backend, para pruebas
abstract final class ParkingMockData {
  static final DateTime now = DateTime(2026, 10, 2, 8);

  static final Map<String, List<ParkingSpot>> spots = {
    'P1': [..._zone('P1', 'A', 20, 6), ..._zone('P1', 'B', 20, 3)],
    'P2': _zone('P2', 'A', 24, 2),
    'P3': _zone('P3', 'A', 24, 0),
  };

  static LevelsOverview get levels => LevelsOverview(
    generatedAt: now,
    campusFull: false,
    levels: [
      _level('P1', underground: false),
      _level('P2', underground: true),
      _level('P3', underground: true),
    ],
  );

  static const List<Building> buildings = [
    Building(id: 'ml', name: 'Edificio Mario Laserna'),
    Building(id: 'sd', name: 'Edificio Santo Domingo'),
    Building(id: 'biblioteca', name: 'Biblioteca General'),
  ];

  static final List<LevelForecast> forecasts = [
    LevelForecast(
      code: 'P1',
      points: [
        for (var hour = 0; hour < 24; hour++)
          ForecastPoint(
            slot: '${hour.toString().padLeft(2, '0')}:00',
            occupancy: hour < 6 ? null : (hour % 10) / 10,
          ),
      ],
    ),
  ];

  static const List<NearbyLot> nearbyLots = [
    NearbyLot(
      id: 'nearby-1',
      name: 'Park Central',
      address: 'Calle ejercito 18',
      ratePerHour: 6000,
      currency: 'COP',
      walkMinutes: 6,
    ),
    NearbyLot(
      id: 'nearby-2',
      name: 'City Parking',
      address: 'Carrera 1 19-20',
      ratePerHour: 7500,
      currency: 'COP',
      walkMinutes: 9,
    ),
  ];

  static Reservation reservation({
    ReservationStatus status = ReservationStatus.active,
    DateTime? createdAt,
    String spotId = 'P1-A-01',
  }) {
    final created = createdAt ?? now;
    return Reservation(
      id: 'res-1',
      spotId: spotId,
      spotCode: spotId.substring(3),
      levelCode: spotId.substring(0, 2),
      status: status,
      createdAt: created,
      expiresAt: created.add(const Duration(minutes: 15)),
    );
  }

  static ParkingLevel _level(String code, {required bool underground}) {
    final list = spots[code]!;
    int count(SpotStatus s) => list.where((spot) => spot.status == s).length;
    return ParkingLevel(
      code: code,
      name: 'Level $code',
      underground: underground,
      total: list.length,
      free: count(SpotStatus.free),
      reserved: count(SpotStatus.reserved),
      occupied: count(SpotStatus.occupied),
    );
  }

  // arma una zona como la del seed del backend: el puesto 1 es accesible,
  // el 2 electrico y el 3 vip. los primeros [free] quedan libres
  static List<ParkingSpot> _zone(
    String level,
    String zone,
    int count,
    int free,
  ) {
    return List.generate(count, (i) {
      final code = '$zone-${(i + 1).toString().padLeft(2, '0')}';
      return ParkingSpot(
        id: '$level-$code',
        code: code,
        zone: zone,
        levelCode: level,
        status: i < free ? SpotStatus.free : SpotStatus.occupied,
        walkMinutes: 2 + i ~/ 4,
        isAccessible: i == 0,
        isEv: i == 1,
        isVip: i == 2,
      );
    });
  }
}
