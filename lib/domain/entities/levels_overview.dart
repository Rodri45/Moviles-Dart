import 'parking_level.dart';

// la respuesta de GET /levels: los niveles y si el campus esta lleno
class LevelsOverview {
  const LevelsOverview({
    required this.generatedAt,
    required this.campusFull,
    required this.levels,
  });

  factory LevelsOverview.fromJson(Map<String, dynamic> json) => LevelsOverview(
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    campusFull: json['campusFull'] as bool,
    levels: [
      for (final level in json['levels'] as List)
        ParkingLevel.fromJson(level as Map<String, dynamic>),
    ],
  );

  final DateTime generatedAt;
  final bool campusFull;
  final List<ParkingLevel> levels;

  Map<String, dynamic> toJson() => {
    'generatedAt': generatedAt.toIso8601String(),
    'campusFull': campusFull,
    'levels': [for (final level in levels) level.toJson()],
  };
}
