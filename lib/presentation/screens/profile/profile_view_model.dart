import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/reservation.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/reservation_outbox.dart';
import '../../../domain/ports/reservation_repository.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';

class ProfileViewModel extends ChangeNotifier with ConnectivityAware {
  ProfileViewModel(
    this._reservations,
    this._outbox, [
    ConnectivityPort? connectivity,
  ]) {
    _outboxSub = _outbox.status.listen((status) {
      pendingActions = status.pending;
      notifyListeners();
    });
    if (connectivity != null) watchConnectivity(connectivity, load);
  }

  final ReservationRepository _reservations;
  final ReservationOutbox _outbox;
  StreamSubscription<OutboxStatus>? _outboxSub;

  List<Reservation> history = const [];
  DateTime? historySavedAt;
  bool isLoading = false;
  bool historyFromStorage = false;
  int pendingActions = 0;
  String? errorMessage;

  @override
  bool get showingSavedData => historyFromStorage || pendingActions > 0;

  void reset() {
    history = const [];
    historySavedAt = null;
    historyFromStorage = false;
    pendingActions = 0;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    pendingActions = await _outbox.pendingCount();
    try {
      final result = await _reservations.history();
      history = result.data;
      historySavedAt = result.savedAt;
      historyFromStorage = result.fromStorage;
    } catch (e) {
      errorMessage = errorMessageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _outboxSub?.cancel();
    super.dispose();
  }
}
