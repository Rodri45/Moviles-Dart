import 'package:flutter/foundation.dart';

import '../../../domain/entities/reservation.dart';
import '../../../domain/ports/reservation_repository.dart';
import '../../shared/error_messages.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._reservations);

  final ReservationRepository _reservations;

  List<Reservation> history = const [];
  bool isLoading = false;
  bool historyFromCache = false;
  String? errorMessage;

  void reset() {
    history = const [];
    historyFromCache = false;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _reservations.history();
      history = result.data;
      historyFromCache = result.fromCache;
    } catch (e) {
      errorMessage = errorMessageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
