import 'dart:async';

import '../../domain/ports/reservation_outbox.dart';

class MockReservationOutbox implements ReservationOutbox {
  final _status = StreamController<OutboxStatus>.broadcast();
  int pending = 0;
  int flushes = 0;
  List<String> rejected = const [];

  void emit(OutboxStatus value) {
    pending = value.pending;
    _status.add(value);
  }

  @override
  Stream<OutboxStatus> get status => _status.stream;

  @override
  Future<int> pendingCount() async => pending;

  @override
  Future<OutboxStatus> flush() async {
    flushes++;
    return OutboxStatus(pending: pending, rejected: rejected);
  }

  @override
  Future<void> clear() async {
    pending = 0;
    _status.add(OutboxStatus.idle);
  }
}
