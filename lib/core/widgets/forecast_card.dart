import 'package:flutter/material.dart';

import '../../domain/entities/forecast.dart';
import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

/// Tarjeta con el pronóstico de ocupación por hora. Equivalente a
/// `ForecastCard.swift`. Dibuja barras simples sin dependencias externas.
class ForecastCard extends StatelessWidget {
  const ForecastCard({super.key, required this.forecast});

  final Forecast forecast;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s forecast', style: AppTypography.heading1),
            const SizedBox(height: Spacing.xs),
            Text('Expected occupancy by hour', style: AppTypography.caption),
            const SizedBox(height: Spacing.md),
            SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final point in forecast.points) ...[
                    Expanded(child: _Bar(point: point)),
                    const SizedBox(width: Spacing.xs),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.point});

  final ForecastPoint point;

  Color get _color {
    if (point.occupancy >= 0.85) return Palette.danger;
    if (point.occupancy >= 0.6) return Palette.warning;
    return Palette.success;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: point.occupancy.clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(Radii.badge),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text('${point.hour}', style: AppTypography.monoData),
      ],
    );
  }
}
