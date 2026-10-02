import 'package:flutter/material.dart';

import '../design/palette.dart';

// la rueda chiquita que va dentro del boton mientras carga
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Palette.textOnPrimary,
      ),
    );
  }
}
