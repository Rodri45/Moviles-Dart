import '../../domain/ports/preferences_store.dart';

class MockPreferencesStore implements PreferencesStore {
  MockPreferencesStore({
    this.destination = 'sd',
    this.arrivalTime,
    this.lastOpenedLevel,
  });

  @override
  String destination;

  @override
  DateTime? arrivalTime;

  @override
  String? lastOpenedLevel;

  @override
  Future<void> saveDestination(String buildingId) async =>
      destination = buildingId;

  @override
  Future<void> saveArrivalTime(DateTime value) async {
    arrivalTime = value;
  }

  @override
  Future<void> saveLastOpenedLevel(String value) async {
    lastOpenedLevel = value;
  }
}
