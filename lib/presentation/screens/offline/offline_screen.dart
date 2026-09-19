import 'package:flutter/material.dart';

import '../../../core/widgets/pw_scaffold.dart';
import '../../../core/widgets/screen_placeholder.dart';

/// Pantalla 7 — Offline.
///
/// Figma: banner o estado completo sin conexión. Muestra los últimos datos
/// conocidos (con marca de hora) y botón "Retry".
///
/// Datos: `ConnectivityPort.isOnline` (mock).
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
