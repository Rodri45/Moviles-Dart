import '../entities/reservation.dart';

/// Puerto de salida para crear y consultar reservas.
abstract interface class ReservationRepository {
  Future<Reservation?> getActiveReservation();

  Future<Reservation> reserve({
    required String lotId,
    required String spotId,
    required Duration duration,
  });

  Future<void> cancel(String reservationId);
}
