abstract interface class PreferencesStore {
  String get destination;

  Future<void> saveDestination(String buildingId);
}
