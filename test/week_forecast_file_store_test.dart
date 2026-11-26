import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/infrastructure/mock/parking_mock_data.dart';
import 'package:parkwise/infrastructure/storage/week_forecast_file_store.dart';

void main() {
  late Directory directory;
  late WeekForecastFileStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('parkwise-week');
    store = WeekForecastFileStore(directory);
  });

  tearDown(() => directory.delete(recursive: true));

  test('the week is written whole and read back with its date', () async {
    final savedAt = DateTime.utc(2026, 11, 23, 12, 2);
    final week = ParkingMockData.week('P2', DateTime(2026, 11, 23));

    await store.write(week, savedAt: savedAt);
    final saved = await store.read();

    expect(saved?.fromStorage, isTrue);
    expect(saved?.savedAt, savedAt);
    expect(saved?.data.hours, week.hours);
    expect(saved?.data.days.map((day) => day.date), [
      for (final day in week.days) day.date,
    ]);
    expect(saved?.data.days.first.levels['P2'], week.days.first.levels['P2']);
    expect(
      File('${directory.path}/${WeekForecastFileStore.fileName}').existsSync(),
      isTrue,
    );
  });

  test('there is nothing to read before the first save', () async {
    expect(await store.read(), isNull);
  });

  test('a damaged file is reported', () async {
    await File(
      '${directory.path}/${WeekForecastFileStore.fileName}',
    ).writeAsString('[1, 2]');

    expect(store.read(), throwsFormatException);
  });
}
