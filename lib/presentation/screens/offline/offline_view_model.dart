import 'package:flutter/foundation.dart';

import '../../../domain/entities/cached.dart';
import '../../../domain/entities/levels_overview.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/reservation.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/reservation_repository.dart';
import '../../shared/connectivity_aware.dart';

// lo que se alcanzo a guardar: niveles, la reserva y el mapa de su nivel
class OfflineViewModel extends ChangeNotifier with ConnectivityAware {
  OfflineViewModel(
    this._parking,
    this._reservations,
    this._preferences,
    ConnectivityPort connectivity, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    watchConnectivity(connectivity, load);
  }

  final ParkingRepository _parking;
  final ReservationRepository _reservations;
  final PreferencesStore _preferences;
  final DateTime Function() _clock;

  Cached<LevelsOverview>? levels;
  Cached<List<ParkingSpot>>? map;
  Reservation? reservation;
  bool isLoading = false;

  String get mapLevel => reservation?.levelCode ?? 'P1';

  // ya hay red y el backend respondio, se puede volver a la app
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
    isLoading = false;
    notifyListeners();
  }
}
