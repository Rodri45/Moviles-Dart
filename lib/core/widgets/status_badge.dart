import 'package:flutter/material.dart';

import '../../domain/entities/parking_level.dart';
import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final OccupancyStatus status;

  static Color colorOf(OccupancyStatus status) => switch (status) {
    OccupancyStatus.available => Palette.success,
    OccupancyStatus.limited => Palette.warning,
    OccupancyStatus.full => Palette.danger,
    OccupancyStatus.offline => Palette.textSecondary,
  };

  static Color softOf(OccupancyStatus status) => switch (status) {
    OccupancyStatus.available => Palette.successSoft,
    OccupancyStatus.limited => Palette.warningSoft,
    OccupancyStatus.full => Palette.dangerSoft,
    OccupancyStatus.offline => Palette.background,
  };

  static String labelOf(OccupancyStatus status) => switch (status) {
    OccupancyStatus.available => 'Available',
    OccupancyStatus.limited => 'Limited',
    OccupancyStatus.full => 'Full',
    OccupancyStatus.offline => 'Offline',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: softOf(status),
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Text(
        labelOf(status),
        style: AppTypography.caption.copyWith(
          color: colorOf(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
