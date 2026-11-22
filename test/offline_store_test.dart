import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:parkwise/infrastructure/storage/offline_store.dart';

void main() {
  late Directory directory;
  late Box<String> box;
  late OfflineStore store;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('parkwise_offline_store');
    Hive.init(directory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  setUp(() async {
    box = await Hive.openBox<String>('offline');
    store = OfflineStore(box);
  });

  tearDown(() => box.deleteFromDisk());

  test('keeps each response on disk with the time it was saved', () async {
    final savedAt = DateTime.utc(2026, 11, 21, 8, 30);
    await store.write('levels', {'free': 12}, savedAt: savedAt);

    final entry = store.read('levels');
    expect(entry?.data, {'free': 12});
    expect(entry?.savedAt, savedAt);
  });

  test('survives closing and opening the box again', () async {
    await store.write('levels', {'free': 3});
    await box.close();

    box = await Hive.openBox<String>('offline');
    store = OfflineStore(box);

    expect(store.read('levels')?.data, {'free': 3});
  });

  test('delete and clear remove what was saved', () async {
    await store.write('a', 1);
    await store.write('b', 2);

    await store.delete('a');
    expect(store.read('a'), isNull);
    expect(store.read('b')?.data, 2);

    await store.clear();
    expect(store.read('b'), isNull);
  });
}
