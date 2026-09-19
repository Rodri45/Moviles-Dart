import 'package:flutter/material.dart';

import '../../../core/widgets/pw_scaffold.dart';
import '../../../core/widgets/screen_placeholder.dart';

// pantalla 6, find my car. falta hacerla, por ahora solo placeholder
// en figma es la del mapa del piso con la ruta y los pasos para llegar al carro
class FindMyCarScreen extends StatelessWidget {
  const FindMyCarScreen({super.key});

  static const String routeName = '/find-my-car';

  @override
  Widget build(BuildContext context) {
    return const PwScaffold(
      title: 'Find my car',
      body: ScreenPlaceholder(name: 'Find my car'),
    );
  }
}
