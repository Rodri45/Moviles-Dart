import 'package:flutter/material.dart';

import '../../domain/entities/level_forecast.dart';
import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

class ForecastCard extends StatelessWidget {
  const ForecastCard({
    super.key,
    required this.hours,
    this.currentHour,
    this.live = true,
  });

  final List<HourlyOccupancy> hours;
  final int? currentHour;

  final bool live;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Occupancy forecast · today',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading1,
                  ),
                ),
                if (live) ...[
                  const SizedBox(width: Spacing.sm),
                  const _LiveBadge(),
                ],
              ],
            ),
            const SizedBox(height: Spacing.md),
            SizedBox(
              height: 72,
              child: hours.isEmpty
                  ? Center(
                      child: Text(
                        'No forecast yet',
                        style: AppTypography.caption,
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < hours.length; i++) ...[
                          if (i > 0) const SizedBox(width: Spacing.xs),
                          Expanded(
                            child: _Bar(
                              bar: hours[i],
                              now: hours[i].hour == currentHour,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: Spacing.md),
            const Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.xs,
              children: [
                _LegendItem(color: Palette.success, label: 'Low < 55%'),
                _LegendItem(color: Palette.warning, label: 'Med 55-80%'),
                _LegendItem(color: Palette.danger, label: 'High > 80%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: Palette.successSoft,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Text(
        'LIVE',
        style: AppTypography.overline.copyWith(color: Palette.success),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bar, required this.now});

  final HourlyOccupancy bar;
  final bool now;

  Color get _base {
    final value = bar.occupancy;
    if (value == null) return Palette.textSecondary;
    if (value < 0.55) return Palette.success;
    if (value <= 0.8) return Palette.warning;
    return Palette.danger;
  }

  String get _label {
    final hour = bar.hour % 12;
    return hour == 0 ? '12' : '$hour';
  }

  @override
  Widget build(BuildContext context) {
    final fill = now ? _base : _base.withValues(alpha: 0.25);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: (bar.occupancy ?? 0).clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(Radii.badge),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          _label,
          style: AppTypography.monoData.copyWith(
            color: now ? Palette.textPrimary : Palette.textSecondary,
            fontWeight: now ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
