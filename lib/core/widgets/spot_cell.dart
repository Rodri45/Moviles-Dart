import 'package:flutter/material.dart';

import '../../domain/entities/parking_spot.dart';
import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

class SpotCell extends StatelessWidget {
  const SpotCell({
    super.key,
    required this.spot,
    this.selected = false,
    this.recommended = false,
    this.highlightColor,
    this.onTap,
  });

  final ParkingSpot spot;
  final bool selected;
  final bool recommended;
  final Color? highlightColor;
  final VoidCallback? onTap;

  Color get _fill {
    if (spot.mine) return Palette.primarySoft;
    return switch (spot.status) {
      SpotStatus.free => Palette.successSoft,
      SpotStatus.reserved => Palette.warningSoft,
      SpotStatus.occupied => Palette.surface,
      SpotStatus.disabled => Palette.inputFill,
    };
  }

  Color get _border {
    if (selected || spot.mine) return Palette.primary;
    if (highlightColor != null) return highlightColor!;
    if (recommended) return Palette.success;
    return switch (spot.status) {
      SpotStatus.free => Palette.success.withValues(alpha: 0.4),
      SpotStatus.reserved => Palette.warning.withValues(alpha: 0.6),
      SpotStatus.occupied => Palette.border,
      SpotStatus.disabled => Palette.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final emphasized =
        selected || recommended || spot.mine || highlightColor != null;

    return Material(
      color: highlightColor == null
          ? _fill
          : Color.alphaBlend(highlightColor!.withValues(alpha: 0.12), _fill),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.badge),
        side: BorderSide(
          color: _border,
          width: highlightColor != null && !selected && !spot.mine
              ? 2.5
              : emphasized
              ? 1.5
              : 1,
        ),
      ),
      child: InkWell(
        onTap: spot.isFree ? onTap : null,
        borderRadius: BorderRadius.circular(Radii.badge),
        child: SizedBox(
          height: 30,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              spot.code,
              maxLines: 1,
              style: AppTypography.monoData.copyWith(
                color: spot.status == SpotStatus.disabled
                    ? Palette.textSecondary
                    : Palette.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
          label: 'Unavailable',
          fill: Palette.inputFill,
          border: Palette.textSecondary,
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
