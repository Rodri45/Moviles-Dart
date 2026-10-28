import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../domain/entities/cached.dart';
import '../../domain/entities/level_forecast.dart';

class ForecastFileStore {
  ForecastFileStore(this._directory);

  final Directory _directory;

  Future<Cached<List<LevelForecast>>?> read(DateTime date) async {
    final key = _dateKey(date);
    final file = File(path.join(_directory.path, 'forecast.json'));
    if (!await file.exists()) return null;

    final value = jsonDecode(await file.readAsString());
    if (value is! Map) {
      throw const FormatException('Saved forecast must be a JSON object');
    }
    final savedAt = value['savedAt'];
    final rawLevels = value['levels'];
    final savedDate = value['date'];
    if (savedDate is! String || savedAt is! String || rawLevels is! List) {
      throw const FormatException('Saved forecast has an invalid shape');
    }
    if (savedDate != key) return null;

    return Cached(
      [
        for (final level in rawLevels)
          if (level is Map)
            LevelForecast.fromJson(Map<String, dynamic>.from(level))
          else
            throw const FormatException(
              'Saved forecast level must be an object',
            ),
      ],
      savedAt: DateTime.parse(savedAt),
      fromCache: true,
    );
  }

  Future<void> write(DateTime date, List<LevelForecast> forecasts) async {
    await _directory.create(recursive: true);
    final key = _dateKey(date);
    final file = File(path.join(_directory.path, 'forecast.json'));
    final pending = File('${file.path}.tmp');
    await pending.writeAsString(
      jsonEncode({
        'date': key,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'levels': [for (final forecast in forecasts) forecast.toJson()],
      }),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await pending.rename(file.path);
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
