import '../entities/lead_time_advice.dart';
import '../entities/reservation.dart';

abstract interface class ReservationRepository {
  Future<Reservation> create(String spotId);

  Future<Reservation> checkIn(String reservationId);

  Future<Reservation> release(String reservationId);

  Future<Reservation?> active();

  Future<List<Reservation>> history();

  Future<LeadTimeAdvice> leadTime();
}
