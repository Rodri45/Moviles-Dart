import 'package:flutter/material.dart';

import '../../domain/entities/parking_spot.dart';
import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

// un puesto del mapa de parqueo, cambia de color segun si esta libre u ocupado
class SpotCell extends StatelessWidget {
  const SpotCell({
    super.key,
    required this.spot,
    this.selected = false,
    this.onTap,
  });

  final ParkingSpot spot;
  final bool selected;
  final VoidCallback? onTap;

  Color get _fill => switch (spot.state) {
        SpotState.free => Palette.success,
        SpotState.occupied => Palette.danger,
        SpotState.reserved => Palette.warning,
        SpotState.disabled => Palette.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = spot.state == SpotState.free && onTap != null;

    return Material(
      color: _fill.withValues(alpha: selected ? 0.35 : 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        side: BorderSide(
          color: selected ? Palette.primary : _fill.withValues(alpha: 0.5),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: SizedBox(
          width: 56,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(spot.code, style: AppTypography.monoId),
              if (spot.isAccessible || spot.isEv)
                Positioned(
                  top: 2,
                  right: 4,
                  child: Icon(
                    spot.isEv ? Icons.bolt : Icons.accessible,
                    size: 12,
                    color: Palette.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
