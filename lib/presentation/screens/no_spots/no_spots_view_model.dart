import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/nearby_lot.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/directions_launcher.dart';
import '../../../domain/ports/nearby_lot_repository.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';

class NoSpotsViewModel extends ChangeNotifier with ConnectivityAware {
  NoSpotsViewModel(
    this._parking,
    this._lots,
    this._directions,
    ConnectivityPort connectivity, {
    this.checkEvery = const Duration(seconds: 30),
  }) {
    watchConnectivity(connectivity, _onReconnect);
  }

  final ParkingRepository _parking;
  final NearbyLotRepository _lots;
  final DirectionsLauncher _directions;
  final Duration checkEvery;
  Timer? _timer;

  List<NearbyLot> lots = const [];
  DateTime? savedAt;
  bool fromCache = false;
  bool isLoading = false;
  String? errorMessage;

  bool watching = false;

  bool campusOpened = false;

  String? get closestId => lots.isEmpty ? null : lots.first.id;

  bool get notifyPaused => watching && !online;

  Future<void> load({bool refresh = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _lots.lots(refresh: refresh);
      lots = [...result.data]
        ..sort((a, b) => a.walkMinutes.compareTo(b.walkMinutes));
      savedAt = result.savedAt;
      fromCache = result.fromCache;
    } catch (e) {
      errorMessage = errorMessageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<bool> navigate(NearbyLot lot) =>
      _directions.openDirections('${lot.name}, ${lot.address}, Bogota');

  void toggleNotify() {
    if (watching) return stopWatching();
    watching = true;
    notifyListeners();
    _checkCampus();
    _timer = Timer.periodic(checkEvery, (_) => _checkCampus());
  }

  void stopWatching() {
    _timer?.cancel();
    _timer = null;
    if (!watching) return;
    watching = false;
    notifyListeners();
  }

  void dismissCampusOpened() {
    campusOpened = false;
    notifyListeners();
  }

  Future<void> _onReconnect() async {
    if (watching) await _checkCampus();
    if (fromCache) await load();
  }

  Future<void> _checkCampus() async {
    if (!online) return;
    try {
      final result = await _parking.getLevels();
      if (!watching || result.fromCache || result.data.campusFull) return;
      stopWatching();
      campusOpened = true;
      notifyListeners();
    } catch (e) {
      debugPrint('campus check failed: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
