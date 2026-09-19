import 'package:flutter/material.dart';

import '../../../core/widgets/pw_scaffold.dart';
import '../../../core/widgets/screen_placeholder.dart';

/// Pantalla 6 — Find my car.
///
/// Figma: tarjeta grande con parqueadero, nivel y código de la celda donde
/// quedó el carro, tiempo transcurrido y botón "Navigate" / "I found it".
///
/// Datos: `ParkingMockData.parkedVehicle` (o `VehicleLocator`).
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
