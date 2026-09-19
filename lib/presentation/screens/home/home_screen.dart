import 'package:flutter/material.dart';

import '../../../core/widgets/pw_scaffold.dart';
import '../../../core/widgets/screen_placeholder.dart';

// pantalla 1, home. falta hacerla, por ahora solo tiene el placeholder
// en figma es la del saludo, la grafica de ocupacion y las cards de los niveles
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return const PwScaffold(
      title: 'ParkWise',
      showBack: false,
      body: ScreenPlaceholder(name: 'Home'),
    );
  }
}
