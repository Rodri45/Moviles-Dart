import '../../domain/ports/preferences_store.dart';

class MockPreferencesStore implements PreferencesStore {
  MockPreferencesStore({this.destination = 'ml'});

  @override
  String destination;

  @override
  Future<void> saveDestination(String buildingId) async =>
      destination = buildingId;
}
