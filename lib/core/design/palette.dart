import 'package:flutter/material.dart';

// los colores de la app, sacados del documento de diseño
// si falta alguno se agrega aqui y no se pone el hex directo en la pantalla
abstract final class Palette {
  // azul principal, para botones y cosas seleccionadas
  static const Color primary = Color(0xFF0052CC);
  static const Color primaryHover = Color(0xFF0065FF);
  static const Color primarySoft = Color(0xFFDEEBFF);

  // verde = hay puestos, amarillo = pocos, rojo = lleno, morado = find my car
  static const Color success = Color(0xFF36B37E);
  static const Color warning = Color(0xFFFFAB00);
  static const Color danger = Color(0xFFDE350B);
  static const Color secondary = Color(0xFF6554C0);

  // versiones clarita de los de arriba para fondos de badges y avisos
  static const Color successSoft = Color(0xFFE3FCEF);
  static const Color warningSoft = Color(0xFFFFF7D6);
  static const Color warningBorder = Color(0xFFFFE380);
  static const Color warningText = Color(0xFFFF8B00);
  static const Color dangerSoft = Color(0xFFFFEBE6);

  // fondo de la pantalla, fondo de las cards y color de los bordes
  static const Color background = Color(0xFFF4F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEBECF0);

  // color de la barrita de arriba del root screen, no es del diseño
  static const Color devBar = Color(0xFF172B4D);

  // textos
  static const Color textPrimary = Color(0xFF172B4D);
  static const Color textSecondary = Color(0xFF6B778C);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // fondo del buscador
  static const Color inputFill = Color(0xFFF4F5F7);
}
