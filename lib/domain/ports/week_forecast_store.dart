import '../entities/saved.dart';
import '../entities/week_forecast.dart';

abstract interface class WeekForecastStore {
  Future<Saved<WeekForecast>?> read();

  Future<void> write(WeekForecast week, {required DateTime savedAt});
}
