import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

abstract final class AppTypography {
  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    Color color = Palette.textPrimary,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.3,
  );

  static TextStyle _mono({
    required double size,
    required FontWeight weight,
    Color color = Palette.textPrimary,
  }) => GoogleFonts.dmMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.3,
  );

  static TextStyle get display => _inter(size: 20, weight: FontWeight.w700);

  static TextStyle get heading1 => _inter(size: 15, weight: FontWeight.w600);

  static TextStyle get heading2 => _inter(size: 14, weight: FontWeight.w600);

  static TextStyle get body => _inter(size: 13, weight: FontWeight.w400);

  static TextStyle get caption =>
      _inter(size: 12, weight: FontWeight.w500, color: Palette.textSecondary);

  static TextStyle get overline => _inter(
    size: 11,
    weight: FontWeight.w600,
    color: Palette.textSecondary,
  ).copyWith(letterSpacing: 0.6);

  static TextStyle get monoId => _mono(size: 13, weight: FontWeight.w500);

  static TextStyle get monoDisplay =>
      _mono(size: 36, weight: FontWeight.w500, color: Palette.primary);

  static TextStyle get monoCountdown =>
      _mono(size: 16, weight: FontWeight.w500);

  static TextStyle get monoData =>
      _mono(size: 12, weight: FontWeight.w400, color: Palette.textSecondary);

  static TextStyle get pill => _inter(size: 13, weight: FontWeight.w600);

  static TextStyle get button => _inter(size: 13, weight: FontWeight.w600);

  static TextStyle get tab => _inter(size: 11, weight: FontWeight.w500);
}
