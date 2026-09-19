import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

/// Escala tipográfica de ParkWise. Equivalente a `Typography.swift`.
///
/// Inter para todo el UI, DM Mono para datos legibles por máquina
/// (códigos de celda, countdowns, timestamps).
abstract final class AppTypography {
  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    Color color = Palette.textPrimary,
  }) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: 1.3);

  static TextStyle _mono({
    required double size,
    required FontWeight weight,
    Color color = Palette.textPrimary,
  }) =>
      GoogleFonts.dmMono(fontSize: size, fontWeight: weight, color: color, height: 1.3);

  /// 20 / 700 — títulos de pantalla.
  static TextStyle get display => _inter(size: 20, weight: FontWeight.w700);

  /// 15 / 600 — títulos de sección y de card.
  static TextStyle get heading1 => _inter(size: 15, weight: FontWeight.w600);

  /// 14 / 600 — labels de ítems de lista.
  static TextStyle get heading2 => _inter(size: 14, weight: FontWeight.w600);

  /// 13 / 400 — texto descriptivo.
  static TextStyle get body => _inter(size: 13, weight: FontWeight.w400);

  /// 12 / 500 — info secundaria, metadata.
  static TextStyle get caption =>
      _inter(size: 12, weight: FontWeight.w500, color: Palette.textSecondary);

  /// 11 / 600 — labels de sección en mayúsculas.
  static TextStyle get overline => _inter(
        size: 11,
        weight: FontWeight.w600,
        color: Palette.textSecondary,
      ).copyWith(letterSpacing: 0.6);

  /// 13 / 500 mono — códigos de celda: B201, A103.
  static TextStyle get monoId => _mono(size: 13, weight: FontWeight.w500);

  /// 36 / 500 mono — código de celda protagonista (pantalla Reserve).
  static TextStyle get monoDisplay =>
      _mono(size: 36, weight: FontWeight.w500, color: Palette.primary);

  /// 16 / 500 mono — countdown dentro del anillo (15:00).
  static TextStyle get monoCountdown => _mono(size: 16, weight: FontWeight.w500);

  /// 12 / 400 mono — timestamps, distancias.
  static TextStyle get monoData =>
      _mono(size: 12, weight: FontWeight.w400, color: Palette.textSecondary);

  /// 13 / 600 — texto de pills/chips.
  static TextStyle get pill => _inter(size: 13, weight: FontWeight.w600);

  /// 13 / 600 — texto de botones.
  static TextStyle get button => _inter(size: 13, weight: FontWeight.w600);

  /// 11 / 500 — labels del bottom nav.
  static TextStyle get tab => _inter(size: 11, weight: FontWeight.w500);
}
