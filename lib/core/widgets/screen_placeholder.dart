import 'package:flutter/material.dart';

import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

/// Placeholder temporal para pantallas aún no implementadas.
///
/// Borrar de cada pantalla cuando se implemente el diseño de Figma.
class ScreenPlaceholder extends StatelessWidget {
  const ScreenPlaceholder({super.key, required this.name, this.owner});

  final String name;

  /// Compañero responsable de esta pantalla.
  final String? owner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction, size: 48, color: Palette.textSecondary),
          const SizedBox(height: Spacing.md),
          Text(name, style: AppTypography.heading1),
          const SizedBox(height: Spacing.xs),
          Text(
            owner == null ? 'Pending' : 'Owner: $owner',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
