import '../../domain/entities/building.dart';
import '../../domain/entities/level_forecast.dart';
import '../../domain/entities/levels_overview.dart';
import '../../domain/entities/nearby_lot.dart';
import '../../domain/entities/parking_level.dart';
import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/week_forecast.dart';

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
    Building(id: 'sd', name: 'Edificio Santo Domingo'),
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

  static final List<int> weekHours = [
    for (var hour = 6; hour < 20; hour++) hour,
  ];

  static WeekForecast week(String level, DateTime from) => WeekForecast(
    hours: weekHours,
    days: [
      for (var offset = 0; offset < 7; offset++)
        _weekDay(level, DateTime(from.year, from.month, from.day + offset)),
    ],
  );

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
      total:
          count(SpotStatus.free) +
          count(SpotStatus.reserved) +
          count(SpotStatus.occupied),
      free: count(SpotStatus.free),
      reserved: count(SpotStatus.reserved),
      occupied: count(SpotStatus.occupied),
      disabled: count(SpotStatus.disabled),
    );
  }

  static DayForecast _weekDay(String level, DateTime date) {
    const hourly = [
      0.30,
      0.62,
      0.88,
      0.94,
      0.90,
      0.84,
      0.72,
      0.70,
      0.76,
      0.72,
      0.60,
      0.48,
      0.38,
      0.28,
    ];
    const byWeekday = [1.0, 1.02, 0.97, 1.0, 0.84, 0.36, 0.14];
    final byLevel = switch (level) {
      'P2' => 0.9,
      'P3' => 0.75,
      _ => 1.0,
    };
    final factor = byWeekday[date.weekday - 1] * byLevel;
    return DayForecast(
      date: date,
      levels: {
        level: [for (final value in hourly) (value * factor).clamp(0.0, 1.0)],
      },
    );
  }

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
