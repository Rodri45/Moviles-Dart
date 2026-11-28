import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/core/cache/sparse_array_cache.dart';

void main() {
  late DateTime now;
  late SparseArrayCache<String> cache;

  setUp(() {
    now = DateTime(2026, 11, 21, 8);
    cache = SparseArrayCache(
      maxEntries: 3,
      ttl: const Duration(minutes: 10),
      clock: () => now,
    );
  });

  test('keeps the keys sorted whatever the insert order', () {
    cache.put(20261123, 'c');
    cache.put(20261121, 'a');
    cache.put(20261122, 'b');

    expect(cache.keys, [20261121, 20261122, 20261123]);
    expect(cache.get(20261122), 'b');
    expect(cache.hits, 1);
  });

  test('replaces the value of a key that is already there', () {
    cache.put(20261121, 'old');
    cache.put(20261121, 'new');

    expect(cache.length, 1);
    expect(cache.get(20261121), 'new');
  });

  test('when full it drops the smallest key, the oldest day', () {
    cache.put(20261121, 'a');
    cache.put(20261122, 'b');
    cache.put(20261123, 'c');
    cache.put(20261124, 'd');

    expect(cache.keys, [20261122, 20261123, 20261124]);
    expect(cache.evictions, 1);
    expect(cache.get(20261121), isNull);
  });

  test('an entry older than the time to live is a miss and is removed', () {
    cache.put(20261121, 'a');
    now = now.add(const Duration(minutes: 11));

    expect(cache.get(20261121), isNull);
    expect(cache.misses, 1);
    expect(cache.length, 0);
  });
}
