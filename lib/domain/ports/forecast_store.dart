import '../entities/level_forecast.dart';
import '../entities/saved.dart';

abstract interface class ForecastStore {
  Future<Saved<List<LevelForecast>>?> read(DateTime date);

  Future<void> write(DateTime date, List<LevelForecast> forecasts);
}
