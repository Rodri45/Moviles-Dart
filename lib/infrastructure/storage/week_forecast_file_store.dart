import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../domain/entities/saved.dart';
import '../../domain/entities/week_forecast.dart';
import '../../domain/ports/week_forecast_store.dart';

class WeekForecastFileStore implements WeekForecastStore {
  WeekForecastFileStore(this._directory);

  static const fileName = 'week_forecast.json';

  final Directory _directory;

  File get _file => File(path.join(_directory.path, fileName));

  @override
  Future<Saved<WeekForecast>?> read() async {
    final file = _file;
    if (!await file.exists()) return null;

    final value = jsonDecode(await file.readAsString());
    if (value is! Map<String, dynamic> || value['savedAt'] is! String) {
      throw const FormatException('Saved week has an invalid shape');
    }
    return Saved(
      WeekForecast.fromJson(value),
      savedAt: DateTime.parse(value['savedAt'] as String),
      fromStorage: true,
    );
  }

  @override
  Future<void> write(WeekForecast week, {required DateTime savedAt}) async {
    await _directory.create(recursive: true);
    final file = _file;
    final pending = File('${file.path}.tmp');
    await pending.writeAsString(
      jsonEncode({
        'savedAt': savedAt.toUtc().toIso8601String(),
        ...week.toJson(),
      }),
      flush: true,
    );
    await pending.rename(file.path);
  }
}
