import '../entities/building.dart';
import '../entities/level_forecast.dart';
import '../entities/level_recommendation.dart';
import '../entities/levels_overview.dart';
import '../entities/nearby_lot.dart';
import '../entities/parking_spot.dart';
import '../entities/saved.dart';
import '../entities/spot_filter.dart';
import '../entities/week_forecast.dart';

abstract interface class ParkingRepository {
  Future<Saved<LevelsOverview>> getLevels({String? zone});

  Future<Saved<List<ParkingSpot>>> getSpots(
    String levelCode, {
    required String destination,
    Set<SpotFilter> filters = const {},
  });

  Future<List<Building>> getBuildings();

  Future<List<LevelForecast>> getPredictions({String? level, DateTime? date});

  Future<LevelRecommendation> getRecommendedLevel(DateTime arrivalAt);

  Future<WeekForecast> getWeekForecast(String level, {required DateTime from});

  Future<List<NearbyLot>> getNearbyLots();
}
