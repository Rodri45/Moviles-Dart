// una reserva de un puesto
class Reservation {
  const Reservation({
    required this.id,
    required this.lotId,
    required this.spotId,
    required this.spotCode,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String lotId;
  final String spotId;
  final String spotCode;
  final DateTime startsAt;
  final DateTime endsAt;

  Duration get duration => endsAt.difference(startsAt);
}
