import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/core/cache/array_map_cache.dart';

class _SameHash {
  const _SameHash(this.name);

  final String name;

  @override
  int get hashCode => 7;

  @override
  bool operator ==(Object other) => other is _SameHash && other.name == name;
}

void main() {
  late DateTime now;

  setUp(() => now = DateTime(2026, 11, 21, 8));

  ArrayMapCache<K, String> cacheOf<K>(int maxEntries) => ArrayMapCache(
    maxEntries: maxEntries,
    ttl: const Duration(seconds: 60),
    clock: () => now,
  );

  test('finds each key by its hash with binary search', () {
    final cache = cacheOf<String>(4)
      ..put('user-b', 'b')
      ..put('user-a', 'a')
      ..put('user-c', 'c');

    expect(cache.get('user-a'), 'a');
    expect(cache.get('user-b'), 'b');
    expect(cache.get('user-c'), 'c');
    expect(cache.get('user-d'), isNull);
    expect(cache.hits, 3);
    expect(cache.misses, 1);
  });

  test('keeps different keys that share the same hash', () {
    final cache = cacheOf<_SameHash>(4)
      ..put(const _SameHash('a'), 'first')
      ..put(const _SameHash('b'), 'second');

    expect(cache.length, 2);
    expect(cache.get(const _SameHash('a')), 'first');
    expect(cache.get(const _SameHash('b')), 'second');
  });

  test('when full it drops the entry saved longest ago', () {
    final cache = cacheOf<String>(2)..put('old', '1');
    now = now.add(const Duration(seconds: 5));
    cache.put('new', '2');
    now = now.add(const Duration(seconds: 5));
    cache.put('newest', '3');

    expect(cache.get('old'), isNull);
    expect(cache.get('new'), '2');
    expect(cache.evictions, 1);
  });

  test('an entry older than the time to live is a miss', () {
    final cache = cacheOf<String>(2)..put('user', 'history');
    now = now.add(const Duration(seconds: 61));

    expect(cache.get('user'), isNull);
    expect(cache.length, 0);
  });
}
