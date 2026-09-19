import '../../domain/entities/reservation.dart';
import '../../domain/ports/reservation_repository.dart';

// version de mentira, guarda la reserva en una variable y ya
class MockReservationRepository implements ReservationRepository {
  Reservation? _active;

  @override
  Future<Reservation?> getActiveReservation() async => _active;

  @override
  Future<Reservation> reserve({
    required String lotId,
    required String spotId,
    required Duration duration,
  }) async {
    final now = DateTime.now();
    _active = Reservation(
      id: 'res-${now.millisecondsSinceEpoch}',
      lotId: lotId,
      spotId: spotId,
      spotCode: spotId,
      startsAt: now,
      endsAt: now.add(duration),
    );
    return _active!;
  }

  @override
  Future<void> cancel(String reservationId) async {
    if (_active?.id == reservationId) _active = null;
  }
}
