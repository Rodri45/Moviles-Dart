class SparseArrayCache<V> {
  SparseArrayCache({
    required this.maxEntries,
    required this.ttl,
    DateTime Function()? clock,
  }) : assert(maxEntries > 0, 'maxEntries must be positive'),
       _clock = clock ?? DateTime.now;

  final int maxEntries;

  final Duration ttl;

  final DateTime Function() _clock;
  final List<int> _keys = [];
  final List<V> _values = [];
  final List<DateTime> _storedAt = [];

  int hits = 0;
  int misses = 0;
  int evictions = 0;

  int get length => _keys.length;

  List<int> get keys => List.unmodifiable(_keys);

  V? get(int key) {
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

  DateTime? storedAt(int key) {
    final index = _indexOf(key);
    return index < 0 ? null : _storedAt[index];
  }

  void put(int key, V value) {
    final index = _indexOf(key);
    if (index >= 0) {
      _values[index] = value;
      _storedAt[index] = _clock();
      return;
    }
    final at = ~index;
    _keys.insert(at, key);
    _values.insert(at, value);
    _storedAt.insert(at, _clock());
    if (_keys.length > maxEntries) {
      _removeAt(0);
      evictions++;
    }
  }

  void remove(int key) {
    final index = _indexOf(key);
    if (index >= 0) _removeAt(index);
  }

  void clear() {
    _keys.clear();
    _values.clear();
    _storedAt.clear();
  }

  int _indexOf(int key) {
    var low = 0;
    var high = _keys.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midKey = _keys[mid];
      if (midKey < key) {
        low = mid + 1;
      } else if (midKey > key) {
        high = mid - 1;
      } else {
        return mid;
      }
    }
    return ~low;
  }

  void _removeAt(int index) {
    _keys.removeAt(index);
    _values.removeAt(index);
    _storedAt.removeAt(index);
  }
}
