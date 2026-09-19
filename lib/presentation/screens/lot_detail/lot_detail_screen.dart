import 'package:flutter/material.dart';

import '../../../core/widgets/pw_scaffold.dart';
import '../../../core/widgets/screen_placeholder.dart';
import '../../../domain/entities/parking_lot.dart';
import '../../../infrastructure/mock/parking_mock_data.dart';

/// Pantalla 2 — Detalle de parqueadero ("P1 · North").
///
/// Figma: header con nombre y estado, lista de niveles (`LevelCard`),
/// pronóstico del día (`ForecastCard`) y botón para ir al mapa / reservar.
///
/// Datos: recibe un [ParkingLot]; por defecto usa el primero del mock.
class LotDetailScreen extends StatelessWidget {
  const LotDetailScreen({super.key, this.lot});

  static const String routeName = '/lot';

  final ParkingLot? lot;

  @override
  Widget build(BuildContext context) {
    final current = lot ?? ParkingMockData.lots.first;

    return PwScaffold(
      title: current.name,
      body: ScreenPlaceholder(name: current.name),
    );
  }
}
