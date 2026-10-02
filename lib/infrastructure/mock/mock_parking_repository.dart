import '../../domain/entities/building.dart';
import '../../domain/entities/cached.dart';
import '../../domain/entities/level_forecast.dart';
import '../../domain/entities/level_recommendation.dart';
import '../../domain/entities/levels_overview.dart';
import '../../domain/entities/nearby_lot.dart';
import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/spot_filter.dart';
import '../../domain/ports/parking_repository.dart';
import 'parking_mock_data.dart';

class MockParkingRepository implements ParkingRepository {
  MockParkingRepository({LevelsOverview? levels})
    : levels = levels ?? ParkingMockData.levels;

  LevelsOverview levels;

  @override
  Future<Cached<LevelsOverview>> getLevels({String? zone}) async {
    return Cached(levels, savedAt: ParkingMockData.now);
  }

  @override
  Future<Cached<List<ParkingSpot>>> getSpots(
    String levelCode, {
    required String destination,
    Set<SpotFilter> filters = const {},
  }) async {
    final spots = (ParkingMockData.spots[levelCode] ?? const <ParkingSpot>[])
        .where((spot) => filters.every((f) => f.matches(spot)))
        .toList();
    return Cached(spots, savedAt: ParkingMockData.now);
  }

  @override
  Future<List<Building>> getBuildings() async {
    return ParkingMockData.buildings;
  }

  @override
  Future<List<LevelForecast>> getPredictions({
    String? level,
    DateTime? date,
  }) async {
    return ParkingMockData.forecasts;
  }

  @override
  Future<LevelRecommendation> getRecommendedLevel(DateTime arrivalAt) async {
    return LevelRecommendation(
      arrivalAt: arrivalAt,
      slot: '08:00',
      recommended: 'P2',
      predictions: const {'P1': 0.9, 'P2': 0.6, 'P3': 0.7},
    );
  }

  @override
  Future<List<NearbyLot>> getNearbyLots() async {
    return ParkingMockData.nearbyLots;
  }
}
