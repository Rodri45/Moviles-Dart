import 'package:flutter/material.dart';

import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

// los botoncitos de filtro tipo "Available", "VIP". si esta seleccionado
// se pone azul clarito, si no queda blanco
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? Palette.primary : Palette.border;
    final textColor = selected ? Palette.primary : Palette.textPrimary;
    final background = selected ? Palette.primarySoft : Palette.surface;

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(size: 16, color: textColor),
                  child: leading!,
                ),
                const SizedBox(width: Spacing.xs),
              ],
              Text(label, style: AppTypography.pill.copyWith(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}

// varios pills juntos donde solo uno queda seleccionado
class PillGroup extends StatelessWidget {
  const PillGroup({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        for (var i = 0; i < labels.length; i++)
          Pill(
            label: labels[i],
            selected: i == selectedIndex,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}
