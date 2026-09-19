import 'package:flutter/material.dart';

/// Colores de ParkWise según el design system (Atlassian-inspired).
/// Equivalente a `Palette.swift`.
///
/// Cada color tiene un significado; no se usa color decorativo.
abstract final class Palette {
  // Primary — acciones, estados activos, links
  static const Color primary = Color(0xFF0052CC); // Blue 700
  static const Color primaryHover = Color(0xFF0065FF); // Blue 500
  static const Color primarySoft = Color(0xFFDEEBFF); // Blue 100

  // Semánticos
  static const Color success = Color(0xFF36B37E); // celdas libres, reserva ok
  static const Color warning = Color(0xFFFFAB00); // poca disponibilidad, caché
  static const Color danger = Color(0xFFDE350B); // niveles llenos, destructivo
  static const Color secondary = Color(0xFF6554C0); // flujo Find my car

  // Fondos tintados para badges y banners semánticos
  static const Color successSoft = Color(0xFFE3FCEF);
  static const Color warningSoft = Color(0xFFFFF7D6);
  static const Color warningBorder = Color(0xFFFFE380);
  static const Color warningText = Color(0xFFFF8B00);
  static const Color dangerSoft = Color(0xFFFFEBE6);
  static const Color secondarySoft = Color(0xFFEAE6FF);

  // Superficies
  static const Color background = Color(0xFFF4F5F7); // page
  static const Color surface = Color(0xFFFFFFFF); // cards y sheets
  static const Color border = Color(0xFFEBECF0); // separadores 1px

  // Barra de navegación de desarrollo (RootScreen); no es parte del diseño.
  static const Color devBar = Color(0xFF172B4D);

  // Texto
  static const Color textPrimary = Color(0xFF172B4D);
  static const Color textSecondary = Color(0xFF6B778C);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Fondo del campo de búsqueda
  static const Color inputFill = Color(0xFFF4F5F7);
}
