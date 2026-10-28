abstract interface class FormDraftStore {
  Map<String, String> read(String form);

  Future<void> save(String form, Map<String, String> fields);

  Future<void> clear(String form);
}
