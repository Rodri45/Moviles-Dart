import 'package:flutter/foundation.dart';

import '../../../domain/entities/reservation.dart';
import '../../../domain/ports/reservation_repository.dart';
import '../../shared/error_messages.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._reservations);

  final ReservationRepository _reservations;

  List<Reservation> history = const [];
  bool isLoading = false;
  String? errorMessage;

  void reset() {
    history = const [];
    errorMessage = null;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      history = await _reservations.history();
    } catch (e) {
      errorMessage = errorMessageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
