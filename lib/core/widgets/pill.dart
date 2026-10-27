import 'package:flutter/material.dart';

import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.selected = false,
    this.selectedColor,
    this.onTap,
  });

  final String label;
  final bool selected;
  final Color? selectedColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = this.selectedColor ?? Palette.primary;
    final borderColor = selected ? selectedColor : Palette.border;
    final textColor = selected ? selectedColor : Palette.textPrimary;
    final background = !selected
        ? Palette.surface
        : this.selectedColor == null
        ? Palette.primarySoft
        : selectedColor.withValues(alpha: 0.14);

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: Spacing.sm,
          ),
          child: Text(
            label,
            style: AppTypography.pill.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}
