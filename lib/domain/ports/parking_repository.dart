import '../entities/building.dart';
import '../entities/cached.dart';
import '../entities/level_forecast.dart';
import '../entities/level_recommendation.dart';
import '../entities/levels_overview.dart';
import '../entities/nearby_lot.dart';
import '../entities/parking_spot.dart';
import '../entities/spot_filter.dart';

// interfaz para pedir niveles, puestos, predicciones y recomendaciones.
// getLevels y getSpots pueden devolver la copia local si la red falla
abstract interface class ParkingRepository {
  Future<Cached<LevelsOverview>> getLevels({String? zone});

  Future<Cached<List<ParkingSpot>>> getSpots(
    String levelCode, {
    required String destination,
    Set<SpotFilter> filters = const {},
  });

  Future<List<Building>> getBuildings();

  Future<List<LevelForecast>> getPredictions({String? level, DateTime? date});

  Future<LevelRecommendation> getRecommendedLevel(DateTime arrivalAt);

  Future<List<NearbyLot>> getNearbyLots();
}
