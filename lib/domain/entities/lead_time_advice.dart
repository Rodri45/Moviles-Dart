// el consejo de cuando reservar segun los viajes del usuario (BQ6)
class LeadTimeAdvice {
  const LeadTimeAdvice({
    required this.holdMinutes,
    required this.suggestedMinutes,
    required this.message,
  });

  factory LeadTimeAdvice.fromJson(Map<String, dynamic> json) => LeadTimeAdvice(
    holdMinutes: (json['holdMinutes'] as num).toInt(),
    suggestedMinutes: (json['suggestedReserveAfterLeavingMinutes'] as num?)
        ?.toInt(),
    message: json['message'] as String,
  );

  final int holdMinutes;

  // null con menos de 3 reservas
  final int? suggestedMinutes;
  final String message;
}
