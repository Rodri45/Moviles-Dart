import 'package:flutter/material.dart';

import '../../domain/entities/parking_level.dart';
import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'status_badge.dart';

// card de un nivel del parqueadero con cuantos puestos hay libres y la barrita
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.level,
    this.recommended = false,
    this.onTap,
  });

  final ParkingLevel level;

  // el nivel que sugiere el backend para la hora de llegada
  final bool recommended;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = level.status;
    final color = StatusBadge.colorOf(status);
    final free = level.free == 0 ? 'No spots' : '${level.free} free';

    return Card(
      shape: recommended
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.card),
              side: const BorderSide(color: Palette.primary, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StatusBadge.softOf(status),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  level.code,
                  style: AppTypography.monoId.copyWith(color: color),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recommended ? '${level.name} · best' : level.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.heading2,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text.rich(
                      TextSpan(
                        style: AppTypography.caption,
                        children: [
                          TextSpan(
                            text: free,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text:
                                '  ${level.reserved} reserved · ${level.total} total',
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: LinearProgressIndicator(
                        value: level.occupancy,
                        minHeight: 4,
                        backgroundColor: Palette.border,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              const Icon(Icons.chevron_right, size: 20, color: Palette.border),
            ],
          ),
        ),
      ),
    );
  }
}
