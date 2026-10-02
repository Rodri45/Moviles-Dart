class LevelRecommendation {
  const LevelRecommendation({
    required this.arrivalAt,
    required this.slot,
    required this.recommended,
    required this.predictions,
  });

  factory LevelRecommendation.fromJson(Map<String, dynamic> json) =>
      LevelRecommendation(
        arrivalAt: DateTime.parse(json['arrivalAt'] as String),
        slot: json['slot'] as String,
        recommended: json['recommended'] as String?,
        predictions: {
          for (final level in json['levels'] as List)
            level['code'] as String: (level['predictedOccupancy'] as num?)
                ?.toDouble(),
        },
      );

  final DateTime arrivalAt;
  final String slot;

  final String? recommended;

  final Map<String, double?> predictions;
}
