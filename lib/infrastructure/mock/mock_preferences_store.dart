import '../../domain/ports/preferences_store.dart';

// version de mentira, guarda el destino en memoria
class MockPreferencesStore implements PreferencesStore {
  MockPreferencesStore({this.destination = 'ml'});

  @override
  String destination;

  @override
  Future<void> saveDestination(String buildingId) async =>
      destination = buildingId;
}
