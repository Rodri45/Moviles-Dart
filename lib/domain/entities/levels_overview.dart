import 'parking_level.dart';

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
}
