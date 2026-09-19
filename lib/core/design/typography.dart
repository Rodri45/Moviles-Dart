import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

// las fuentes de la app. inter para todo el texto normal y dm mono para
// los codigos de los puestos, los relojes y las fechas
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

  // titulo de la pantalla
  static TextStyle get display => _inter(size: 20, weight: FontWeight.w700);

  // titulos de seccion y de cards
  static TextStyle get heading1 => _inter(size: 15, weight: FontWeight.w600);

  // nombres en las listas
  static TextStyle get heading2 => _inter(size: 14, weight: FontWeight.w600);

  // texto normal
  static TextStyle get body => _inter(size: 13, weight: FontWeight.w400);

  // texto chiquito gris
  static TextStyle get caption =>
      _inter(size: 12, weight: FontWeight.w500, color: Palette.textSecondary);

  // los titulitos en mayuscula tipo "DESTINATION"
  static TextStyle get overline => _inter(
        size: 11,
        weight: FontWeight.w600,
        color: Palette.textSecondary,
      ).copyWith(letterSpacing: 0.6);

  // codigos de puesto tipo B201
  static TextStyle get monoId => _mono(size: 13, weight: FontWeight.w500);

  // el codigo grande de la pantalla de reserve
  static TextStyle get monoDisplay =>
      _mono(size: 36, weight: FontWeight.w500, color: Palette.primary);

  // el 15:00 del circulo
  static TextStyle get monoCountdown => _mono(size: 16, weight: FontWeight.w500);

  // fechas y horas chiquitas
  static TextStyle get monoData =>
      _mono(size: 12, weight: FontWeight.w400, color: Palette.textSecondary);

  static TextStyle get pill => _inter(size: 13, weight: FontWeight.w600);

  static TextStyle get button => _inter(size: 13, weight: FontWeight.w600);

  // texto de la barra de abajo
  static TextStyle get tab => _inter(size: 11, weight: FontWeight.w500);
}
