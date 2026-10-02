import '../../domain/entities/lead_time_advice.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/errors.dart';
import '../../domain/ports/reservation_repository.dart';
import 'parking_mock_data.dart';

// version de mentira, guarda la reserva en una variable y ya.
// createError sirve para simular el 409 del backend
class MockReservationRepository implements ReservationRepository {
  MockReservationRepository({this.clock});

  DateTime Function()? clock;
  Reservation? current;
  Object? createError;
  final List<Reservation> past = [];

  DateTime get _now => (clock ?? DateTime.now)();

  @override
  Future<Reservation> create(String spotId) async {
    final error = createError;
    if (error != null) throw error;
    if (current?.isOpen ?? false) {
      throw const ApiException(409, 'An active reservation already exists');
    }
    return current = ParkingMockData.reservation(
      spotId: spotId,
      createdAt: _now,
    );
  }

  @override
  Future<Reservation> checkIn(String reservationId) async =>
      current = _copy(ReservationStatus.fulfilled, checkedInAt: _now);

  @override
  Future<Reservation> release(String reservationId) async {
    final next = current?.status == ReservationStatus.fulfilled
        ? ReservationStatus.released
        : ReservationStatus.cancelled;
    final closed = _copy(next, releasedAt: _now);
    past.insert(0, closed);
    current = null;
    return closed;
  }

  @override
  Future<Reservation?> active() async => current;

  @override
  Future<List<Reservation>> history() async => [?current, ...past];

  @override
  Future<LeadTimeAdvice> leadTime() async => const LeadTimeAdvice(
    holdMinutes: 15,
    suggestedMinutes: null,
    message: 'Reserve when you leave home.',
  );

  Reservation _copy(
    ReservationStatus status, {
    DateTime? checkedInAt,
    DateTime? releasedAt,
  }) {
    final r = current;
    if (r == null) throw const ApiException(404, 'Reservation not found');
    return Reservation(
      id: r.id,
      spotId: r.spotId,
      spotCode: r.spotCode,
      levelCode: r.levelCode,
      status: status,
      createdAt: r.createdAt,
      expiresAt: r.expiresAt,
      checkedInAt: checkedInAt ?? r.checkedInAt,
      releasedAt: releasedAt,
    );
  }
}
