class OutboxStatus {
  const OutboxStatus({required this.pending, this.rejected = const []});

  static const idle = OutboxStatus(pending: 0);

  final int pending;

  final List<String> rejected;
}

abstract interface class ReservationOutbox {
  Stream<OutboxStatus> get status;

  Future<int> pendingCount();

  Future<OutboxStatus> flush();

  Future<void> clear();
}
