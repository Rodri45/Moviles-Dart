import 'package:flutter/material.dart';

import '../../../core/widgets/pw_scaffold.dart';
import '../../../core/widgets/screen_placeholder.dart';

// pantalla 7, offline. falta hacerla, por ahora solo placeholder
// en figma es la que sale sin internet, con los datos guardados y el boton retry
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  static const String routeName = '/offline';

  @override
  Widget build(BuildContext context) {
    return const PwScaffold(
      title: 'Offline',
      body: ScreenPlaceholder(name: 'Offline'),
    );
  }
}
