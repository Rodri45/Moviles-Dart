enum PendingActionType {
  checkIn('check_in'),
  release('release');

  const PendingActionType(this.code);

  final String code;

  static PendingActionType fromCode(String code) =>
      values.firstWhere((type) => type.code == code);
}

class PendingAction {
  const PendingAction({
    this.id,
    required this.reservationId,
    required this.spotCode,
    required this.type,
    required this.createdAt,
  });

  final int? id;
  final String reservationId;
  final String spotCode;
  final PendingActionType type;
  final DateTime createdAt;
}
