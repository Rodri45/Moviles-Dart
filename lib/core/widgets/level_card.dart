import 'package:flutter/material.dart';

import '../../domain/entities/parking_level.dart';
import '../../domain/entities/parking_lot.dart';
import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'status_badge.dart';

// card de un nivel del parqueadero con cuantos puestos hay libres y la barrita
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.level, this.onTap});

  final ParkingLevel level;
  final VoidCallback? onTap;

  OccupancyStatus get _status {
    if (level.totalSpots == 0) return OccupancyStatus.offline;
    if (level.freeSpots == 0) return OccupancyStatus.full;
    if (level.freeSpots / level.totalSpots < 0.15) return OccupancyStatus.limited;
    return OccupancyStatus.available;
  }

  @override
  Widget build(BuildContext context) {
    final occupancy =
        level.totalSpots == 0 ? 0.0 : 1 - level.freeSpots / level.totalSpots;
    final color = StatusBadge.colorOf(_status);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(level.name, style: AppTypography.heading1)),
                  StatusBadge(status: _status),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                '${level.freeSpots} free of ${level.totalSpots}',
                style: AppTypography.caption,
              ),
              const SizedBox(height: Spacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: LinearProgressIndicator(
                  value: occupancy,
                  minHeight: 6,
                  backgroundColor: Palette.border,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
