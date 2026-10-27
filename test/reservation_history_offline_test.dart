import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkwise/infrastructure/http/api_client.dart';
import 'package:parkwise/infrastructure/http/http_reservation_repository.dart';
import 'package:parkwise/infrastructure/storage/local_cache.dart';
import 'package:parkwise/infrastructure/storage/reservation_history_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  late Box<String> cacheBox;
  late ReservationHistoryStore historyStore;
  late HttpReservationRepository repository;
  var online = true;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    directory = await Directory.systemTemp.createTemp('parkwise_history_test');
    Hive.init(directory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  setUp(() async {
    cacheBox = await Hive.openBox<String>('cache');
    historyStore = await ReservationHistoryStore.open(
      databasePath: inMemoryDatabasePath,
    );
    online = true;
    final client = MockClient((request) async {
      if (!online) throw http.ClientException('offline');
      return http.Response(
        '[{"id":"reservation-1","spotId":"P1-A-01","spotCode":"A-01",'
        '"levelCode":"P1","status":"fulfilled",'
        '"createdAt":"2026-10-12T12:00:00.000Z",'
        '"expiresAt":"2026-10-12T12:15:00.000Z",'
        '"checkedInAt":"2026-10-12T12:10:00.000Z","releasedAt":null}]',
        200,
      );
    });
    repository = HttpReservationRepository(
      ApiClient(
        httpClient: client,
        readToken: () => 'session-token',
        baseUrl: 'https://test.example',
      ),
      LocalCache(cacheBox),
      historyStore,
      () => 'user-a',
    );
  });

  tearDown(() async {
    await historyStore.close();
    await cacheBox.deleteFromDisk();
  });

  test('reservation history falls back to the signed-in user SQLite cache', () async {
    expect((await repository.history()).data.single.id, 'reservation-1');
    online = false;

    final offlineHistory = await repository.history();
    expect(offlineHistory.data.single.id, 'reservation-1');
    expect(offlineHistory.data.single.status.name, 'fulfilled');
    expect(offlineHistory.fromCache, isTrue);
    expect(await historyStore.read('user-b'), isNull);
  });

  test('offline history does not pretend an unprimed cache is real data', () async {
    online = false;
    await expectLater(repository.history(), throwsA(isA<Exception>()));
  });
}
