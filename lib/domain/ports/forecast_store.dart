import '../entities/cached.dart';
import '../entities/level_forecast.dart';

abstract interface class ForecastStore {
  Future<Cached<List<LevelForecast>>?> read(DateTime date);

  Future<void> write(DateTime date, List<LevelForecast> forecasts);
}
