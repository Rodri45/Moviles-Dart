import 'package:flutter/material.dart';

import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

enum NoticeTone { warning, danger }

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = NoticeTone.warning,
    this.icon = Icons.info_outline,
  });

  final String message;
  final String? title;
  final NoticeTone tone;
  final IconData icon;

  ({Color text, Color background, Color border}) get _colors => switch (tone) {
    NoticeTone.warning => (
      text: Palette.warningText,
      background: Palette.warningSoft,
      border: Palette.warningBorder,
    ),
    NoticeTone.danger => (
      text: Palette.danger,
      background: Palette.dangerSoft,
      border: Palette.danger.withValues(alpha: 0.3),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _colors;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: colors.text),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppTypography.heading2.copyWith(color: colors.text),
                  ),
                  const SizedBox(height: Spacing.xs),
                ],
                Text(
                  message,
                  style: AppTypography.body.copyWith(
                    color: Palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
