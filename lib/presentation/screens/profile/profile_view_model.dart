import 'package:flutter/foundation.dart';

import '../../../domain/entities/reservation.dart';
import '../../../domain/ports/reservation_repository.dart';
import '../login/auth_view_model.dart';

// el historial de reservas del perfil
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._reservations);

  final ReservationRepository _reservations;

  List<Reservation> history = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      history = await _reservations.history();
    } catch (e) {
      errorMessage = AuthViewModel.messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
