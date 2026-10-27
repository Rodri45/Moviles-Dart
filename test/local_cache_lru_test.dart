import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:parkwise/infrastructure/storage/local_cache.dart';

void main() {
  late Directory directory;
  late Box<String> box;
  late LocalCache cache;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('parkwise_lru_test');
    Hive.init(directory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  setUp(() async {
    box = await Hive.openBox<String>('cache');
    cache = LocalCache(box);
  });

  tearDown(() => box.deleteFromDisk());

  test(
    'decoded entries use access-order eviction with a fixed memory bound',
    () async {
      await cache.write('recent', {'value': 'original'});
      cache.read('recent');
      for (var index = 0; index < LocalCache.maxMemoryEntries - 1; index++) {
        await cache.write('entry-$index', {'value': index});
      }

      cache.read('recent');
      await box.put(
        'recent',
        jsonEncode({
          'savedAt': DateTime.utc(2026).toIso8601String(),
          'data': {'value': 'disk'},
        }),
      );
      await cache.write('overflow', {'value': 'new'});

      expect(cache.read('recent')?.data, {'value': 'original'});

      for (var index = 0; index < LocalCache.maxMemoryEntries; index++) {
        await cache.write('overflow-$index', {'value': index});
      }
      expect(cache.read('recent')?.data, {'value': 'disk'});
    },
  );
}
