import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/nearby_lot.dart';
import '../../../domain/ports/directions_launcher.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../shared/error_messages.dart';

class NoSpotsViewModel extends ChangeNotifier {
  NoSpotsViewModel(
    this._parking,
    this._directions, {
    this.checkEvery = const Duration(seconds: 30),
  });

  final ParkingRepository _parking;
  final DirectionsLauncher _directions;
  final Duration checkEvery;
  Timer? _timer;

  List<NearbyLot> lots = const [];
  bool isLoading = false;
  String? errorMessage;

  bool watching = false;

  bool campusOpened = false;

  String? get closestId => lots.isEmpty ? null : lots.first.id;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      lots = [...await _parking.getNearbyLots()]
        ..sort((a, b) => a.walkMinutes.compareTo(b.walkMinutes));
    } catch (e) {
      errorMessage = errorMessageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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

  Future<void> _checkCampus() async {
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
