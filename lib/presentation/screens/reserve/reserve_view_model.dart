import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/car_location.dart';
import '../../../domain/entities/geo_point.dart';
import '../../../domain/entities/lead_time_advice.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/reservation.dart';
import '../../../domain/errors.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/location_provider.dart';
import '../../../domain/ports/reservation_repository.dart';
import '../../../domain/ports/vehicle_locator.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';

class ReserveViewModel extends ChangeNotifier with ConnectivityAware {
  ReserveViewModel(
    this._reservations,
    this._vehicles,
    this._location,
    ConnectivityPort connectivity, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    watchConnectivity(connectivity, load);
  }

  static const warnBefore = Duration(minutes: 3);
  static const warnDistanceMeters = 1000;

  final ReservationRepository _reservations;
  final VehicleLocator _vehicles;
  final LocationProvider _location;
  final DateTime Function() _clock;
  Timer? _ticker;
  final Set<String> _warned = {};

  ParkingSpot? pendingSpot;
  Reservation? reservation;
  List<Reservation> history = const [];
  LeadTimeAdvice? advice;
  bool isBusy = false;
  String? errorMessage;

  bool expiryAlert = false;

  bool get isActive => reservation?.status == ReservationStatus.active;
  bool get isParked => reservation?.status == ReservationStatus.fulfilled;
  int get holdMinutes => advice?.holdMinutes ?? 15;

  Duration get remaining => reservation?.remaining(_clock()) ?? Duration.zero;

  Future<void> load() async {
    await Future.wait([_loadActive(), _loadHistory(), _loadAdvice()]);
    notifyListeners();
  }

  void selectSpot(ParkingSpot spot) {
    pendingSpot = spot;
    errorMessage = reservation == null
        ? null
        : 'You already have a reservation. Cancel it to pick another spot.';
    notifyListeners();
  }

  Future<void> confirm() async {
    final spot = pendingSpot;
    if (spot == null) return;
    await _run(() async {
      _setReservation(await _reservations.create(spot.id));
      pendingSpot = null;
    });
  }

  Future<void> checkIn() async {
    final current = reservation;
    if (current == null) return;
    await _run(() async {
      final parked = await _reservations.checkIn(current.id);
      _setReservation(parked);
      await _saveCarLocation(parked);
    });
  }

  Future<bool> shouldExplainLocation() async =>
      await _location.checkAccess() == LocationAccess.denied;

  Future<void> requestLocation() => _location.requestAccess();

  Future<void> release() async {
    final current = reservation;
    if (current == null) return;
    await _run(() async {
      await _reservations.release(current.id);
      await _vehicles.clearLocation();
      _setReservation(null);
      await _loadHistory();
    });
  }

  void dismissExpiryAlert() {
    expiryAlert = false;
    notifyListeners();
  }

  void reset() {
    _setReservation(null);
    pendingSpot = null;
    history = const [];
    advice = null;
    errorMessage = null;
    expiryAlert = false;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (e) {
      errorMessage = _conflictMessage(e) ?? errorMessageFor(e);
      if (e.statusCode == 409) await _loadActive();
    } catch (e) {
      errorMessage = errorMessageFor(e);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  String? _conflictMessage(ApiException e) {
    if (e.statusCode != 409) return null;
    final message = e.message.toLowerCase();
    if (message.contains('not available')) {
      pendingSpot = null;
      return 'Spot taken, choose another.';
    }
    if (message.contains('active reservation')) {
      return 'You already have a reservation.';
    }
    if (message.contains('expired')) return 'Your reservation expired.';
    return e.message;
  }

  Future<void> _saveCarLocation(Reservation parked) async {
    final position = await _location.currentPosition();
    await _vehicles.saveLocation(
      CarLocation(
        levelCode: parked.levelCode,
        spotCode: parked.spotCode,
        savedAt: parked.checkedInAt ?? _clock(),
        position: position,
      ),
    );
  }

  Future<void> _loadActive() async {
    try {
      _setReservation(await _reservations.active());
    } catch (e) {
      debugPrint('active reservation failed: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      history = await _reservations.history();
    } catch (e) {
      debugPrint('history failed: $e');
    }
  }

  Future<void> _loadAdvice() async {
    try {
      advice = await _reservations.leadTime();
    } catch (e) {
      debugPrint('lead time failed: $e');
    }
  }

  void _setReservation(Reservation? value) {
    reservation = (value?.isOpen ?? false) ? value : null;
    _ticker?.cancel();
    _ticker = isActive
        ? Timer.periodic(const Duration(seconds: 1), (_) => _tick())
        : null;
  }

  void _tick() {
    final current = reservation;
    if (current == null) return;
    if (remaining == Duration.zero) {
      _setReservation(null);
      errorMessage = 'Your reservation for ${current.spotCode} expired.';
      _loadHistory().then((_) => notifyListeners());
    } else if (remaining <= warnBefore && _warned.add(current.id)) {
      _checkDistance();
    }
    notifyListeners();
  }

  Future<void> _checkDistance() async {
    if (await _location.checkAccess() != LocationAccess.granted) return;
    final position = await _location.currentPosition();
    if (position == null) return;
    final meters = _location.distanceMeters(position, GeoPoint.campus);
    if (meters > warnDistanceMeters && isActive) {
      expiryAlert = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
