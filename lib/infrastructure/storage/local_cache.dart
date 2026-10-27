import 'dart:collection';
import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

class LocalCache {
  LocalCache(this._box);

  static const maxMemoryEntries = 32;

  final Box<String> _box;
  final _memory = LinkedHashMap<
    String,
    ({Object? data, DateTime savedAt})
  >();

  Future<void> write(String key, Object? data, {DateTime? savedAt}) {
    final timestamp = savedAt ?? DateTime.now();
    final entry = {
      'savedAt': timestamp.toIso8601String(),
      'data': data,
    };
    _remember(key, (data: data, savedAt: timestamp));
    return _box.put(key, jsonEncode(entry));
  }

  ({Object? data, DateTime savedAt})? read(String key) {
    final cached = _memory.remove(key);
    if (cached != null) {
      _memory[key] = cached;
      return cached;
    }
    final raw = _box.get(key);
    if (raw == null) return null;
    final entry = jsonDecode(raw) as Map<String, dynamic>;
    final value = (
      data: entry['data'],
      savedAt: DateTime.parse(entry['savedAt'] as String),
    );
    _remember(key, value);
    return value;
  }

  Future<void> delete(String key) {
    _memory.remove(key);
    return _box.delete(key);
  }

  Future<void> clear() async {
    _memory.clear();
    await _box.clear();
  }

  void _remember(String key, ({Object? data, DateTime savedAt}) value) {
    _memory.remove(key);
    _memory[key] = value;
    if (_memory.length > maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }
}
