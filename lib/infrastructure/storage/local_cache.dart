import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

class LocalCache {
  LocalCache(this._box);

  final Box<String> _box;

  Future<void> write(String key, Object? data, {DateTime? savedAt}) {
    final entry = {
      'savedAt': (savedAt ?? DateTime.now()).toIso8601String(),
      'data': data,
    };
    return _box.put(key, jsonEncode(entry));
  }

  ({Object? data, DateTime savedAt})? read(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    final entry = jsonDecode(raw) as Map<String, dynamic>;
    return (
      data: entry['data'],
      savedAt: DateTime.parse(entry['savedAt'] as String),
    );
  }

  Future<void> delete(String key) => _box.delete(key);

  Future<void> clear() async {
    await _box.clear();
  }
}
