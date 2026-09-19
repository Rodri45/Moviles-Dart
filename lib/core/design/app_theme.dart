import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';
import 'spacing.dart';
import 'typography.dart';

/// ThemeData de ParkWise construido a partir de [Palette] y [AppTypography].
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Palette.primary,
      primary: Palette.primary,
      surface: Palette.surface,
      error: Palette.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Palette.background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Palette.surface,
        foregroundColor: Palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.display,
      ),
      cardTheme: CardThemeData(
        color: Palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: const BorderSide(color: Palette.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.primary,
          foregroundColor: Palette.textOnPrimary,
          minimumSize: const Size.fromHeight(Spacing.touchTarget),
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.primary,
          minimumSize: const Size.fromHeight(Spacing.touchTarget),
          textStyle: AppTypography.button,
          side: const BorderSide(color: Palette.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Palette.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
