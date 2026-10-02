import 'dart:math';

import '../../domain/entities/geo_point.dart';
import '../../domain/ports/location_provider.dart';

class MockLocationProvider implements LocationProvider {
  MockLocationProvider({
    this.access = LocationAccess.granted,
    this.position = GeoPoint.campus,
  });

  LocationAccess access;
  GeoPoint? position;

  @override
  Future<LocationAccess> checkAccess() async => access;

  @override
  Future<LocationAccess> requestAccess() async => access;

  @override
  Future<void> openSettings() async {}

  @override
  Future<GeoPoint?> currentPosition() async =>
      access == LocationAccess.granted ? position : null;

  @override
  Future<GeoPoint?> lastKnownPosition() async => position;

  @override
  Stream<GeoPoint> watchPosition() => const Stream.empty();

  @override
  double distanceMeters(GeoPoint from, GeoPoint to) {
    const metersPerDegree = 111320.0;
    final dLat = (to.latitude - from.latitude) * metersPerDegree;
    final dLng =
        (to.longitude - from.longitude) *
        metersPerDegree *
        cos(from.latitude * pi / 180);
    return sqrt(dLat * dLat + dLng * dLng);
  }

  @override
  int walkingMinutes(GeoPoint from, GeoPoint to) =>
      (distanceMeters(from, to) / 1.3 / 60).ceil();
}
