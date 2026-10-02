import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkwise/domain/entities/spot_filter.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/http/api_client.dart';
import 'package:parkwise/infrastructure/http/http_parking_repository.dart';
import 'package:parkwise/infrastructure/storage/local_cache.dart';

void main() {
  late Directory dir;
  late Box<String> box;
  late bool online;
  late int status;
  late HttpParkingRepository repository;
  final savedAt = DateTime(2026, 10, 2, 8, 3);

  final levelsJson = {
    'generatedAt': '2026-10-02T13:03:00.000Z',
    'campusFull': false,
    'levels': [
      {
        'code': 'P1',
        'name': 'Level P1',
        'underground': false,
        'total': 60,
        'free': 52,
        'reserved': 0,
        'occupied': 8,
      },
    ],
  };

  final spotsJson = [
    {
      'id': 'P1-A-01',
      'code': 'A-01',
      'zone': 'A',
      'levelCode': 'P1',
      'status': 'free',
      'isAccessible': true,
      'isEv': false,
      'isVip': false,
      'walkMinutes': 3,
      'mine': false,
    },
    {
      'id': 'P1-A-02',
      'code': 'A-02',
      'zone': 'A',
      'levelCode': 'P1',
      'status': 'occupied',
      'isAccessible': false,
      'isEv': true,
      'isVip': false,
      'walkMinutes': 3,
      'mine': false,
    },
  ];

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('parkwise_cache_test');
    Hive.init(dir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  setUp(() async {
    box = await Hive.openBox<String>('cache_${DateTime.now().microsecond}');
    online = true;
    status = 200;
    final client = MockClient((request) async {
      if (!online) throw http.ClientException('offline');
      final body = request.url.path.endsWith('/levels')
          ? levelsJson
          : spotsJson;
      return http.Response(
        status == 200 ? jsonEncode(body) : '{"error":"Level not found"}',
        status,
      );
    });
    repository = HttpParkingRepository(
      ApiClient(httpClient: client, readToken: () => null),
      LocalCache(box),
      clock: () => savedAt,
    );
  });

  tearDown(() => box.deleteFromDisk());

  test('returns live data and keeps a copy', () async {
    final result = await repository.getLevels();

    expect(result.fromCache, isFalse);
    expect(result.data.levels.single.free, 52);
    expect(box.containsKey('levels'), isTrue);
  });

  test(
    'returns the cached levels with their time when the network fails',
    () async {
      await repository.getLevels();
      online = false;

      final result = await repository.getLevels();

      expect(result.fromCache, isTrue);
      expect(result.savedAt, savedAt);
      expect(result.data.levels.single.code, 'P1');
    },
  );

  test('keeps serving the cache while the breaker is open', () async {
    await repository.getLevels();
    online = false;

    for (var i = 0; i < 5; i++) {
      final result = await repository.getLevels();
      expect(result.fromCache, isTrue);
    }
  });

  test('spots per level fall back to the cache, filtered locally', () async {
    await repository.getSpots('P1', destination: 'ml');
    online = false;

    final all = await repository.getSpots('P1', destination: 'ml');
    final free = await repository.getSpots(
      'P1',
      destination: 'ml',
      filters: {SpotFilter.available},
    );

    expect(all.fromCache, isTrue);
    expect(all.data, hasLength(2));
    expect(free.data.map((s) => s.code), ['A-01']);
  });

  test('without a cached copy the network error is rethrown', () async {
    online = false;
    expect(repository.getLevels(), throwsA(isA<NetworkException>()));
  });

  test('a 4xx is not hidden behind the cache', () async {
    await repository.getSpots('P1', destination: 'ml');
    status = 404;

    expect(
      repository.getSpots('P1', destination: 'ml'),
      throwsA(isA<ApiException>()),
    );
  });
}
