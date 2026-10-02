// preferencias del usuario que se guardan en el celular
abstract interface class PreferencesStore {
  // id del edificio destino, se usa en todas las consultas de puestos
  String get destination;

  Future<void> saveDestination(String buildingId);
}
