import '../entities/geo_point.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

abstract interface class LocationProvider {
  Future<LocationAccess> checkAccess();

  Future<LocationAccess> requestAccess();

  Future<void> openSettings();

  Future<GeoPoint?> currentPosition();

  Future<GeoPoint?> lastKnownPosition();

  Stream<GeoPoint> watchPosition();

  double distanceMeters(GeoPoint from, GeoPoint to);

  int walkingMinutes(GeoPoint from, GeoPoint to);
}
