import 'package:flutter/material.dart';

import '../../domain/entities/parking_lot.dart';
import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

// la etiqueta de available / limited / full / offline con su color e icono
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final OccupancyStatus status;

  static Color colorOf(OccupancyStatus status) => switch (status) {
        OccupancyStatus.available => Palette.success,
        OccupancyStatus.limited => Palette.warning,
        OccupancyStatus.full => Palette.danger,
        OccupancyStatus.offline => Palette.textSecondary,
      };

  static String labelOf(OccupancyStatus status) => switch (status) {
        OccupancyStatus.available => 'Available',
        OccupancyStatus.limited => 'Limited',
        OccupancyStatus.full => 'Full',
        OccupancyStatus.offline => 'Offline',
      };

  static IconData iconOf(OccupancyStatus status) => switch (status) {
        OccupancyStatus.available => Icons.check_circle_outline,
        OccupancyStatus.limited => Icons.error_outline,
        OccupancyStatus.full => Icons.cancel_outlined,
        OccupancyStatus.offline => Icons.wifi_off_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconOf(status), size: 12, color: color),
          const SizedBox(width: Spacing.xs),
          Text(labelOf(status), style: AppTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
