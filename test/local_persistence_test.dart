import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:parkwise/domain/entities/level_forecast.dart';
import 'package:parkwise/infrastructure/storage/car_location_file_store.dart';
import 'package:parkwise/infrastructure/storage/forecast_file_store.dart';
import 'package:parkwise/infrastructure/storage/reservation_history_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'SQLite reservation history is indexed by account and survives empty syncs',
    () async {
      final store = await ReservationHistoryStore.open(
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(store.close);

      expect(await store.read('user-a'), isNull);
      await store.replace('user-a', [
        {
          'reservation_id': 'reservation-1',
          'spot_id': 'P1-A-01',
          'spot_code': 'A-01',
          'level_code': 'P1',
          'status': 'fulfilled',
          'created_at': '2026-10-12T12:00:00.000Z',
          'expires_at': '2026-10-12T12:15:00.000Z',
          'checked_in_at': '2026-10-12T12:10:00.000Z',
          'released_at': null,
        },
      ]);

      expect(
        (await store.read('user-a'))?.reservations.single['reservation_id'],
        'reservation-1',
      );
      expect(await store.read('user-b'), isNull);

      await store.replace('user-a', const []);
      expect((await store.read('user-a'))?.reservations, isEmpty);
    },
  );

  test(
    'car location is persisted as an app-private JSON file and can be cleared',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'parkwise-car-file',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File(path.join(directory.path, 'parked_vehicle.json'));
      final store = CarLocationFileStore(file);
      const savedLocation = {
        'levelCode': 'P2',
        'spotCode': 'B-04',
        'savedAt': '2026-10-12T12:00:00.000Z',
        'position': null,
      };

      expect(await store.read(), isNull);
      await store.write(savedLocation);
      expect(await store.read(), savedLocation);
      await store.clear();
      expect(await store.read(), isNull);
    },
  );

  test('forecast JSON file is scoped to its date and restores real points', () async {
    final directory = await Directory.systemTemp.createTemp(
      'parkwise-forecast-file',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = ForecastFileStore(directory);
    final date = DateTime(2026, 10, 12, 8);
    final forecast = [
      LevelForecast(
        code: 'P2',
        points: const [ForecastPoint(slot: '08:15', occupancy: 0.42)],
      ),
    ];

    await store.write(date, forecast);

    final cached = await store.read(date);
    expect(cached?.fromCache, isTrue);
    expect(cached?.data.single.code, 'P2');
    expect(cached?.data.single.points.single.occupancy, 0.42);
    expect(await store.read(date.add(const Duration(days: 1))), isNull);
  });
}
