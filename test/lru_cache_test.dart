import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/core/cache/lru_cache.dart';

void main() {
  test('evicts the least recently used entry when it is full', () {
    final cache = LruCache<String, int>(maxEntries: 2)
      ..put('a', 1)
      ..put('b', 2);

    expect(cache.get('a'), 1);
    cache.put('c', 3);

    expect(cache.get('b'), isNull);
    expect(cache.get('a'), 1);
    expect(cache.get('c'), 3);
    expect(cache.length, 2);
    expect(cache.evictions, 1);
  });

  test('writing an existing key refreshes it instead of adding one', () {
    final cache = LruCache<String, int>(maxEntries: 2)
      ..put('a', 1)
      ..put('b', 2)
      ..put('a', 10)
      ..put('c', 3);

    expect(cache.keys, ['a', 'c']);
    expect(cache.get('a'), 10);
  });

  test('entries older than the time to live are misses', () {
    var now = DateTime(2026, 10, 26, 8);
    final cache = LruCache<String, int>(
      maxEntries: 4,
      ttl: const Duration(seconds: 30),
      clock: () => now,
    )..put('spots', 1);

    now = now.add(const Duration(seconds: 29));
    expect(cache.get('spots'), 1);

    now = now.add(const Duration(seconds: 2));
    expect(cache.get('spots'), isNull);
    expect(cache.hits, 1);
    expect(cache.misses, 1);
    expect(cache.length, 0);
  });
}
