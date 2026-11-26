import '../../domain/entities/saved.dart';
import '../../domain/entities/week_forecast.dart';
import '../../domain/ports/week_forecast_store.dart';

class MemoryWeekForecastStore implements WeekForecastStore {
  Saved<WeekForecast>? saved;

  @override
  Future<Saved<WeekForecast>?> read() async => saved;

  @override
  Future<void> write(WeekForecast week, {required DateTime savedAt}) async {
    saved = Saved(week, savedAt: savedAt, fromStorage: true);
  }
}
