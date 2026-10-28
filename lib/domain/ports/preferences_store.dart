abstract interface class PreferencesStore {
  String get destination;

  DateTime? get arrivalTime;

  String? get lastOpenedLevel;

  Future<void> saveDestination(String buildingId);

  Future<void> saveArrivalTime(DateTime arrivalTime);

  Future<void> saveLastOpenedLevel(String levelCode);
}
