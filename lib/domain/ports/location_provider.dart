import '../entities/geo_point.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

// interfaz para el gps del celular
abstract interface class LocationProvider {
  // revisa el permiso sin preguntarle nada al usuario
  Future<LocationAccess> checkAccess();

  // muestra el dialogo del sistema para pedir permiso
  Future<LocationAccess> requestAccess();

  Future<void> openSettings();

  // null si no hay permiso o no hay señal (por ejemplo bajo tierra)
  Future<GeoPoint?> currentPosition();

  Future<GeoPoint?> lastKnownPosition();

  Stream<GeoPoint> watchPosition();

  double distanceMeters(GeoPoint from, GeoPoint to);

  // caminando a 1,3 m/s, redondeado hacia arriba
  int walkingMinutes(GeoPoint from, GeoPoint to);
}
