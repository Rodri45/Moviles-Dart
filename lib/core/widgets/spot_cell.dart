import 'package:flutter/material.dart';

import '../../domain/entities/parking_spot.dart';
import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

// un puesto del mapa del nivel. el color depende del estado y adentro van
// los minutos a pie hasta el edificio destino
class SpotCell extends StatelessWidget {
  const SpotCell({
    super.key,
    required this.spot,
    this.selected = false,
    this.recommended = false,
    this.onTap,
  });

  final ParkingSpot spot;
  final bool selected;
  final bool recommended;
  final VoidCallback? onTap;

  Color get _fill {
    if (spot.mine) return Palette.primarySoft;
    return switch (spot.status) {
      SpotStatus.free => Palette.successSoft,
      SpotStatus.reserved => Palette.warningSoft,
      SpotStatus.occupied || SpotStatus.disabled => Palette.surface,
    };
  }

  Color get _border {
    if (selected || spot.mine) return Palette.primary;
    if (recommended) return Palette.success;
    return switch (spot.status) {
      SpotStatus.free => Palette.success.withValues(alpha: 0.4),
      SpotStatus.reserved => Palette.warning.withValues(alpha: 0.6),
      SpotStatus.occupied || SpotStatus.disabled => Palette.border,
    };
  }

  Color get _text {
    if (spot.mine) return Palette.primary;
    if (spot.isFree) return Palette.success;
    return Palette.textSecondary.withValues(alpha: 0.6);
  }

  @override
  Widget build(BuildContext context) {
    final emphasized = selected || recommended || spot.mine;

    return Material(
      color: _fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.badge),
        side: BorderSide(color: _border, width: emphasized ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: spot.isFree ? onTap : null,
        borderRadius: BorderRadius.circular(Radii.badge),
        child: SizedBox(
          height: 30,
          child: Center(
            child: Text(
              '${spot.walkMinutes}m',
              maxLines: 1,
              style: AppTypography.monoData.copyWith(
                fontSize: 10,
                color: _text,
                fontWeight: emphasized ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// la explicacion de los colores de SpotCell
class SpotLegend extends StatelessWidget {
  const SpotLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: Spacing.md,
      runSpacing: Spacing.xs,
      children: [
        _LegendItem(
          label: 'Free',
          fill: Palette.successSoft,
          border: Palette.success,
        ),
        _LegendItem(
          label: 'Taken',
          fill: Palette.surface,
          border: Palette.border,
        ),
        _LegendItem(
          label: 'Reserved',
          fill: Palette.warningSoft,
          border: Palette.warning,
        ),
        _LegendItem(
          label: 'You',
          fill: Palette.primarySoft,
          border: Palette.primary,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.fill,
    required this.border,
  });

  final String label;
  final Color fill;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
