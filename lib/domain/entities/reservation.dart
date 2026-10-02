enum ReservationStatus { active, fulfilled, released, cancelled, expired }

// una reserva tal cual la devuelve el backend
class Reservation {
  const Reservation({
    required this.id,
    required this.spotId,
    required this.spotCode,
    required this.levelCode,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.checkedInAt,
    this.releasedAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: json['id'] as String,
    spotId: json['spotId'] as String,
    spotCode: json['spotCode'] as String,
    levelCode: json['levelCode'] as String,
    status: ReservationStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    checkedInAt: _dateOrNull(json['checkedInAt']),
    releasedAt: _dateOrNull(json['releasedAt']),
  );

  final String id;
  final String spotId;
  final String spotCode;
  final String levelCode;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? checkedInAt;
  final DateTime? releasedAt;

  // la misma regla que usa GET /reservations/active
  bool get isOpen =>
      status == ReservationStatus.active ||
      (status == ReservationStatus.fulfilled && releasedAt == null);

  Duration remaining(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'spotId': spotId,
    'spotCode': spotCode,
    'levelCode': levelCode,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'checkedInAt': checkedInAt?.toIso8601String(),
    'releasedAt': releasedAt?.toIso8601String(),
  };

  static DateTime? _dateOrNull(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}
