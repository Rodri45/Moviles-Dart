class LotRedirect {
  const LotRedirect({
    required this.id,
    required this.lotId,
    required this.lotName,
    required this.redirectedAt,
    this.answeredAt,
    this.parked,
  });

  final int id;
  final String lotId;
  final String lotName;
  final DateTime redirectedAt;
  final DateTime? answeredAt;
  final bool? parked;

  bool get answered => answeredAt != null;
}
