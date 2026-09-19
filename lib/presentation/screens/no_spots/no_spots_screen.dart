import 'package:flutter/material.dart';

import '../../../core/widgets/pw_scaffold.dart';
import '../../../core/widgets/screen_placeholder.dart';

/// Pantalla 5 — No campus spots.
///
/// Figma: estado vacío cuando todos los parqueaderos están llenos. Ilustración
/// o ícono, mensaje, hora estimada de liberación (usar `ForecastCard`) y
/// botón secundario "Notify me" / "Try again".
class NoSpotsScreen extends StatelessWidget {
  const NoSpotsScreen({super.key});

  static const String routeName = '/no-spots';

  @override
  Widget build(BuildContext context) {
    return const PwScaffold(
      title: 'No campus spots',
      body: ScreenPlaceholder(name: 'No campus spots'),
    );
  }
}
