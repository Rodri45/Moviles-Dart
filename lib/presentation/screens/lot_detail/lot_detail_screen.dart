import 'package:flutter/material.dart';

import '../../../core/widgets/pw_scaffold.dart';
import '../../../core/widgets/screen_placeholder.dart';
import '../../../domain/entities/parking_lot.dart';
import '../../../infrastructure/mock/parking_mock_data.dart';

// pantalla 2, la de P1 · North. falta hacerla, por ahora solo placeholder
// en figma es la del mapa de puestos con la hoja que sale abajo al escoger uno
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
