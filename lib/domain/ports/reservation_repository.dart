import '../entities/lead_time_advice.dart';
import '../entities/reservation.dart';

// interfaz para reservar, hacer check-in y soltar el puesto
abstract interface class ReservationRepository {
  Future<Reservation> create(String spotId);

  Future<Reservation> checkIn(String reservationId);

  Future<Reservation> release(String reservationId);

  // la reserva abierta del usuario, o null
  Future<Reservation?> active();

  Future<List<Reservation>> history();

  Future<LeadTimeAdvice> leadTime();
}
