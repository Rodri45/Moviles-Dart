import 'package:geolocator/geolocator.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/ports/location_provider.dart';

// el gps real. es el unico archivo de la app que conoce geolocator
class GeolocatorLocationProvider implements LocationProvider {
  // velocidad caminando promedio, la misma que usa el backend
  static const _walkingSpeed = 1.3;

  // bajo tierra el gps puede no responder nunca, no se espera mas que esto
  static const _fixTimeout = Duration(seconds: 5);

  @override
  Future<LocationAccess> checkAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> requestAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    return _map(await Geolocator.requestPermission());
  }

  @override
  Future<void> openSettings() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Future<GeoPoint?> currentPosition() async {
    if (await checkAccess() != LocationAccess.granted) return null;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _fixTimeout,
        ),
      );
      return _toPoint(position);
    } on Exception {
      return null;
    }
  }

  @override
  Future<GeoPoint?> lastKnownPosition() async {
    if (await checkAccess() != LocationAccess.granted) return null;
    final position = await Geolocator.getLastKnownPosition();
    return position == null ? null : _toPoint(position);
  }

  @override
  Stream<GeoPoint> watchPosition() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    ),
  ).map(_toPoint);

  @override
  double distanceMeters(GeoPoint from, GeoPoint to) =>
      Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );

  @override
  int walkingMinutes(GeoPoint from, GeoPoint to) =>
      (distanceMeters(from, to) / _walkingSpeed / 60).ceil();

  static GeoPoint _toPoint(Position p) => GeoPoint(p.latitude, p.longitude);

  static LocationAccess _map(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => LocationAccess.denied,
      };
}
