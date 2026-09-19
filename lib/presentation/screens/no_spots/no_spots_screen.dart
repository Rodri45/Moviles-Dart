import 'package:flutter/material.dart';

import '../../../core/widgets/pw_scaffold.dart';
import '../../../core/widgets/screen_placeholder.dart';

// pantalla 5, no campus spots. falta hacerla, por ahora solo placeholder
// en figma es la que sale cuando todo esta lleno, con los parqueaderos de afuera
// y el boton de notify me
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
