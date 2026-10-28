import 'dart:collection';

class LruCache<K, V> {
  LruCache({required this.maxEntries, this.ttl, DateTime Function()? clock})
    : assert(maxEntries > 0, 'maxEntries must be positive'),
      _clock = clock ?? DateTime.now;

  final int maxEntries;

  final Duration? ttl;

  final DateTime Function() _clock;
  final LinkedHashMap<K, _Entry<V>> _entries = LinkedHashMap<K, _Entry<V>>();

  int hits = 0;
  int misses = 0;
  int evictions = 0;

  int get length => _entries.length;

  Iterable<K> get keys => _entries.keys;

  V? get(K key) {
    final entry = _entries.remove(key);
    if (entry == null || _isExpired(entry)) {
      misses++;
      return null;
    }
    _entries[key] = entry;
    hits++;
    return entry.value;
  }

  void put(K key, V value) {
    _entries.remove(key);
    _entries[key] = _Entry(value, _clock());
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
      evictions++;
    }
  }

  void remove(K key) => _entries.remove(key);

  void clear() => _entries.clear();

  bool _isExpired(_Entry<V> entry) {
    final limit = ttl;
    return limit != null && _clock().difference(entry.storedAt) > limit;
  }
}

class _Entry<V> {
  _Entry(this.value, this.storedAt);

  final V value;
  final DateTime storedAt;
}
