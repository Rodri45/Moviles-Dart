import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/car_location.dart';
import '../../../domain/entities/geo_point.dart';
import '../../../domain/entities/parked_vehicle.dart';
import '../../../domain/ports/location_provider.dart';
import '../../../domain/ports/vehicle_locator.dart';

class FindMyCarViewModel extends ChangeNotifier {
  FindMyCarViewModel(this._vehicles, this._location);

  final VehicleLocator _vehicles;
  final LocationProvider _location;
  StreamSubscription<GeoPoint>? _positionSub;

  ParkedVehicle? vehicle;
  CarLocation? saved;
  LocationAccess? access;
  GeoPoint? me;
  bool isLoading = false;

  bool offline = false;

  bool usingLastKnown = false;

  String? get spotCode => vehicle?.spotCode ?? saved?.spotCode;
  String? get levelCode => vehicle?.levelCode ?? saved?.levelCode;
  String? get zone => vehicle?.zone;
  DateTime? get parkedAt => vehicle?.parkedAt ?? saved?.savedAt;
  bool get hasCar => spotCode != null;

  double? get distanceMeters {
    final from = me;
    final to = saved?.position;
    if (from == null || to == null) return null;
    return _location.distanceMeters(from, to);
  }

  int? get walkingMinutes {
    final from = me;
    final to = saved?.position;
    if (from == null || to == null) return null;
    return _location.walkingMinutes(from, to);
  }

  Future<void> start() async {
    await load();
    await refreshAccess();
  }

  void stop() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      vehicle = await _vehicles.getParkedVehicle();
      offline = false;
      if (vehicle == null) await _vehicles.clearLocation();
    } catch (e) {
      offline = true;
      debugPrint('vehicle failed: $e');
    }
    saved = await _vehicles.savedLocation();
    final current = vehicle;
    if (current != null &&
        (saved?.spotCode != current.spotCode ||
            saved?.levelCode != current.levelCode)) {
      saved = null;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshAccess() async {
    access = await _location.checkAccess();
    notifyListeners();
    if (access == LocationAccess.granted && _positionSub == null) {
      await _track();
    }
  }

  Future<void> requestAccess() async {
    access = await _location.requestAccess();
    notifyListeners();
    if (access == LocationAccess.granted) await _track();
  }

  Future<void> openSettings() => _location.openSettings();

  Future<void> _track() async {
    final current = await _location.currentPosition();
    if (current != null) {
      me = current;
      usingLastKnown = false;
    } else {
      me = await _location.lastKnownPosition();
      usingLastKnown = me != null;
    }
    notifyListeners();
    _positionSub?.cancel();
    _positionSub = _location.watchPosition().listen(
      (point) {
        me = point;
        usingLastKnown = false;
        notifyListeners();
      },
      onError: (Object e) {
        usingLastKnown = me != null;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
