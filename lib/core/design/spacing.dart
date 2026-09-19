import 'package:flutter/material.dart';

// espacios estandar para no poner numeros a mano por todo lado
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  // el margen de los lados de todas las pantallas
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: md);

  // tamaño minimo de un boton para que se pueda tocar bien
  static const double touchTarget = 48;
}

// los bordes redondeados
abstract final class Radii {
  static const double badge = 3;
  static const double sm = 6;
  static const double card = 8;
  static const double pill = 999;
}
