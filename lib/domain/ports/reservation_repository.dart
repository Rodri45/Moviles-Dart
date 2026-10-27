import '../entities/lead_time_advice.dart';
import '../entities/reservation.dart';
import '../entities/cached.dart';

abstract interface class ReservationRepository {
  Future<Reservation> create(String spotId);

  Future<Reservation> checkIn(String reservationId);

  Future<Reservation> release(String reservationId);

  Future<Reservation?> active();

  Future<Cached<List<Reservation>>> history();

  Future<LeadTimeAdvice> leadTime();
}
