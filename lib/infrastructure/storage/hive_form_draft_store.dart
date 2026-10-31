import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

import '../../domain/ports/form_draft_store.dart';

class HiveFormDraftStore implements FormDraftStore {
  HiveFormDraftStore(this._box);

  static const blocked = {'password', 'confirmPassword'};

  final Box<String> _box;

  @override
  Map<String, String> read(String form) {
    final raw = _box.get(form);
    if (raw == null) return const {};
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return json.map((key, value) => MapEntry(key, value as String));
  }

  @override
  Future<void> save(String form, Map<String, String> fields) {
    final safe = {
      for (final entry in fields.entries)
        if (!blocked.contains(entry.key) && entry.value.isNotEmpty)
          entry.key: entry.value,
    };
    return safe.isEmpty ? _box.delete(form) : _box.put(form, jsonEncode(safe));
  }

  @override
  Future<void> clear(String form) => _box.delete(form);
}
