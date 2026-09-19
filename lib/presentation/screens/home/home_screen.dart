import 'package:flutter/material.dart';

import '../../../core/widgets/pw_scaffold.dart';
import '../../../core/widgets/screen_placeholder.dart';

/// Pantalla 1 — Home.
///
/// Figma: lista de parqueaderos del campus con estado (Available / Limited /
/// Full), distancia y acceso rápido a "Find a spot" y "Find my car".
///
/// Datos: `ParkingMockData.lots` (o `ParkingRepository.getLots()`).
/// Componentes sugeridos: `StatusBadge`, `Pill`, `Card`.
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
