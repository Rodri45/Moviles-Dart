import 'package:flutter/foundation.dart';

import '../../../domain/entities/nearby_lot.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../shared/error_messages.dart';

// los parqueaderos de afuera para cuando el campus esta lleno
class NoSpotsViewModel extends ChangeNotifier {
  NoSpotsViewModel(this._parking);

  final ParkingRepository _parking;

  List<NearbyLot> lots = const [];
  bool isLoading = false;
  String? errorMessage;

  // el mas cercano a pie va primero y con borde azul
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
}
