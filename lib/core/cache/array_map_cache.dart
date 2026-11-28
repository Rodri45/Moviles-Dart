class ArrayMapCache<K, V> {
  ArrayMapCache({
    required this.maxEntries,
    required this.ttl,
    DateTime Function()? clock,
  }) : assert(maxEntries > 0, 'maxEntries must be positive'),
       _clock = clock ?? DateTime.now;

  final int maxEntries;

  final Duration ttl;

  final DateTime Function() _clock;
  final List<int> _hashes = [];
  final List<K> _keys = [];
  final List<V> _values = [];
  final List<DateTime> _storedAt = [];

  int hits = 0;
  int misses = 0;
  int evictions = 0;

  int get length => _keys.length;

  V? get(K key) {
    final index = _indexOf(key);
    if (index < 0) {
      misses++;
      return null;
    }
    if (_clock().difference(_storedAt[index]) > ttl) {
      _removeAt(index);
      misses++;
      return null;
    }
    hits++;
    return _values[index];
  }

  void put(K key, V value) {
    final index = _indexOf(key);
    if (index >= 0) {
      _values[index] = value;
      _storedAt[index] = _clock();
      return;
    }
    if (_keys.length >= maxEntries) {
      _removeAt(_oldestIndex());
      evictions++;
    }
    final at = ~_indexOf(key);
    _hashes.insert(at, key.hashCode);
    _keys.insert(at, key);
    _values.insert(at, value);
    _storedAt.insert(at, _clock());
  }

  void remove(K key) {
    final index = _indexOf(key);
    if (index >= 0) _removeAt(index);
  }

  void clear() {
    _hashes.clear();
    _keys.clear();
    _values.clear();
    _storedAt.clear();
  }

  int _indexOf(K key) {
    final hash = key.hashCode;
    var low = 0;
    var high = _hashes.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midHash = _hashes[mid];
      if (midHash < hash) {
        low = mid + 1;
      } else if (midHash > hash) {
        high = mid - 1;
      } else {
        return _scanSameHash(mid, hash, key);
      }
    }
    return ~low;
  }

  int _scanSameHash(int found, int hash, K key) {
    if (_keys[found] == key) return found;
    var end = found + 1;
    while (end < _hashes.length && _hashes[end] == hash) {
      if (_keys[end] == key) return end;
      end++;
    }
    for (var i = found - 1; i >= 0 && _hashes[i] == hash; i--) {
      if (_keys[i] == key) return i;
    }
    return ~end;
  }

  int _oldestIndex() {
    var oldest = 0;
    for (var i = 1; i < _storedAt.length; i++) {
      if (_storedAt[i].isBefore(_storedAt[oldest])) oldest = i;
    }
    return oldest;
  }

  void _removeAt(int index) {
    _hashes.removeAt(index);
    _keys.removeAt(index);
    _values.removeAt(index);
    _storedAt.removeAt(index);
  }
}
