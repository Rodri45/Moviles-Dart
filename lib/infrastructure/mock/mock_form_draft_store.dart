import '../../domain/ports/form_draft_store.dart';
import '../storage/hive_form_draft_store.dart';

class MockFormDraftStore implements FormDraftStore {
  final Map<String, Map<String, String>> forms = {};

  @override
  Map<String, String> read(String form) => forms[form] ?? const {};

  @override
  Future<void> save(String form, Map<String, String> fields) async {
    final safe = {
      for (final entry in fields.entries)
        if (!HiveFormDraftStore.blocked.contains(entry.key) &&
            entry.value.isNotEmpty)
          entry.key: entry.value,
    };
    if (safe.isEmpty) {
      forms.remove(form);
    } else {
      forms[form] = safe;
    }
  }

  @override
  Future<void> clear(String form) async => forms.remove(form);
}
