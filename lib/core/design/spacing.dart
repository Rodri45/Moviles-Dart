import 'package:flutter/material.dart';

/// Espaciados de ParkWise. Grid de 8px, 4px para pares ajustados.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Padding horizontal de todas las pantallas (16px).
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: md);

  /// Área táctil mínima.
  static const double touchTarget = 48;
}

abstract final class Radii {
  static const double badge = 3;
  static const double sm = 6;
  static const double card = 8;
  static const double pill = 999;
}
