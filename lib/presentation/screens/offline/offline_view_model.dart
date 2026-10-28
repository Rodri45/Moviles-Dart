import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/cached.dart';
import '../../../domain/entities/levels_overview.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/reservation.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/reservation_outbox.dart';
import '../../../domain/ports/reservation_repository.dart';
import '../../shared/connectivity_aware.dart';

class OfflineViewModel extends ChangeNotifier with ConnectivityAware {
  OfflineViewModel(
    this._parking,
    this._reservations,
    this._preferences,
    this._outbox,
    ConnectivityPort connectivity, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    watchConnectivity(connectivity, load);
    _outboxSub = _outbox.status.listen((status) {
      pendingActions = status.pending;
      notifyListeners();
    });
  }

  final ParkingRepository _parking;
  final ReservationRepository _reservations;
  final PreferencesStore _preferences;
  final ReservationOutbox _outbox;
  final DateTime Function() _clock;
  StreamSubscription<OutboxStatus>? _outboxSub;

  Cached<LevelsOverview>? levels;
  Cached<List<ParkingSpot>>? map;
  Reservation? reservation;
  int pendingActions = 0;
  bool isLoading = false;

  String get mapLevel => reservation?.levelCode ?? 'P1';

  bool get recovered => online && levels != null && !levels!.fromCache;

  int? get minutesSinceSync {
    final saved = levels?.savedAt;
    return saved == null ? null : _clock().difference(saved).inMinutes;
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      levels = await _parking.getLevels();
    } catch (e) {
      debugPrint('offline levels failed: $e');
    }
    try {
      reservation = await _reservations.active();
    } catch (e) {
      debugPrint('offline reservation failed: $e');
    }
    try {
      map = await _parking.getSpots(
        mapLevel,
        destination: _preferences.destination,
      );
    } catch (e) {
      debugPrint('offline map failed: $e');
    }
    pendingActions = await _outbox.pendingCount();
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _outboxSub?.cancel();
    super.dispose();
  }
}
