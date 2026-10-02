import 'package:flutter/material.dart';

import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import '../format.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.savedAt,
    this.online = false,
    this.onTap,
  });

  final DateTime? savedAt;

  final bool online;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = AppTypography.body.copyWith(color: Palette.textSecondary);
    final bold = body.copyWith(
      color: Palette.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final saved = savedAt;

    return Material(
      color: Palette.warningSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: const BorderSide(color: Palette.warningBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Palette.warningText,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(
                  online ? Icons.cloud_off : Icons.wifi_off,
                  size: 18,
                  color: Palette.textOnPrimary,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      online ? 'Server unreachable' : 'No signal',
                      style: AppTypography.heading2.copyWith(
                        color: Palette.warningText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (saved == null)
                      Text('No saved data yet', style: body)
                    else
                      Text.rich(
                        TextSpan(
                          style: body,
                          children: [
                            const TextSpan(text: 'Showing cached data from '),
                            TextSpan(text: formatTime(saved), style: bold),
                            TextSpan(text: ' · ${formatDate(saved)}'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Palette.warningText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
