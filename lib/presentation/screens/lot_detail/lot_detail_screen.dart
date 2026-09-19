import 'package:flutter/material.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/pill.dart';

// pantalla 2, la de P1 · North. solo es la vista, nada funciona
// arriba el titulo con los botones P1 P2 P3 y la leyenda, en la mitad el mapa
// de puestos por zonas y abajo la hoja blanca con el puesto seleccionado
class LotDetailScreen extends StatelessWidget {
  const LotDetailScreen({super.key});

  static const String routeName = '/lot';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    // el padding de abajo es para que la hoja no tape el mapa
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.md,
                      Spacing.md,
                      Spacing.md,
                      200,
                    ),
                    children: [
                      const _EntranceCard(),
                      const SizedBox(height: Spacing.md),
                      for (final zone in _zones) ...[
                        _ZoneSection(zone: zone),
                        const SizedBox(height: Spacing.md),
                      ],
                    ],
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _SelectedSpotSheet(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppTabBar(current: AppTab.map),
    );
  }
}

// datos de mentira del mapa

enum _Cell { free, taken, reserved, you, car }

typedef _Zone = ({String name, List<List<_Cell>> rows});

const List<_Zone> _zones = [
  (
  name: 'Zone A',
  rows: [
    [_Cell.taken, _Cell.taken, _Cell.free, _Cell.free, _Cell.taken, _Cell.free],
    [_Cell.taken, _Cell.free, _Cell.free, _Cell.free, _Cell.free, _Cell.free],
    [_Cell.reserved, _Cell.free, _Cell.taken, _Cell.free, _Cell.free, _Cell.free],
  ],
  ),
  (
  name: 'Zone B',
  rows: [
    [_Cell.free, _Cell.you, _Cell.free, _Cell.taken, _Cell.taken, _Cell.free],
    [_Cell.car, _Cell.taken, _Cell.reserved, _Cell.free, _Cell.free, _Cell.free],
    [_Cell.free, _Cell.taken, _Cell.free, _Cell.free, _Cell.taken, _Cell.free],
  ],
  ),
];

// la parte blanca de arriba: titulo, botones de nivel y la leyenda

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Palette.surface,
        border: Border(bottom: BorderSide(color: Palette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LEVEL', style: AppTypography.overline),
                    const SizedBox(height: 2),
                    Text(
                      'P1 · North',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              const Row(
                children: [
                  Pill(label: 'P1', selected: true),
                  SizedBox(width: Spacing.xs),
                  Pill(label: 'P2'),
                  SizedBox(width: Spacing.xs),
                  Pill(label: 'P3'),
                ],
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.xs,
            children: [
              _LegendItem(label: 'Free', fill: Palette.successSoft, border: Palette.success),
              _LegendItem(label: 'Taken', fill: Palette.background, border: Palette.border),
              _LegendItem(label: 'Reserved', fill: Palette.warningSoft, border: Palette.warning),
              _LegendItem(label: 'You', fill: Palette.primarySoft, border: Palette.primary),
            ],
          ),
        ],
      ),
    );
  }
}

// cuadrito de la leyenda con su nombre
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.fill,
    required this.border,
  });

  final String label;
  final Color fill;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

// la card de "ENTRANCE / EXIT" con la flechita del norte

class _EntranceCard extends StatelessWidget {
  const _EntranceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            const Icon(Icons.sync_alt, size: 16, color: Palette.textSecondary),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'ENTRANCE / EXIT',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.overline.copyWith(color: Palette.textPrimary),
              ),
            ),
            const Icon(Icons.arrow_forward, size: 12, color: Palette.textSecondary),
            const SizedBox(width: 2),
            Text('N', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

// una zona completa: el titulo, la rayita punteada y las filas de puestos

class _ZoneSection extends StatelessWidget {
  const _ZoneSection({required this.zone});

  final _Zone zone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: Palette.primary),
            const SizedBox(width: Spacing.sm),
            Text(
              zone.name,
              style: AppTypography.heading2.copyWith(color: Palette.primary),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        const _RoadLine(),
        const SizedBox(height: Spacing.sm),
        for (var i = 0; i < zone.rows.length; i++) ...[
          _SpotRow(number: i + 1, cells: zone.rows[i]),
          if (i < zone.rows.length - 1) const SizedBox(height: Spacing.sm),
        ],
      ],
    );
  }
}

// la linea gris punteada que hace como la via
class _RoadLine extends StatelessWidget {
  const _RoadLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        color: Palette.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 6; i++)
            Container(
              width: 14,
              height: 2,
              color: Palette.textSecondary.withValues(alpha: 0.4),
            ),
        ],
      ),
    );
  }
}

// una fila de puestos con su numerito a la izquierda
class _SpotRow extends StatelessWidget {
  const _SpotRow({required this.number, required this.cells});

  final int number;
  final List<_Cell> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text('$number', style: AppTypography.monoData),
        ),
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: Spacing.xs),
          Expanded(child: _SpotCell(cell: cells[i])),
        ],
      ],
    );
  }
}

// cada puestico del mapa, cambia de color segun el estado
class _SpotCell extends StatelessWidget {
  const _SpotCell({required this.cell});

  final _Cell cell;

  Color get _fill => switch (cell) {
    _Cell.free => Palette.successSoft,
    _Cell.taken => Palette.surface,
    _Cell.reserved => Palette.warningSoft,
    _Cell.you => Palette.primarySoft,
    _Cell.car => Palette.border,
  };

  Color get _border => switch (cell) {
    _Cell.free => Palette.success.withValues(alpha: 0.4),
    _Cell.taken => Palette.border,
    _Cell.reserved => Palette.warning.withValues(alpha: 0.6),
    _Cell.you => Palette.primary,
    _Cell.car => Palette.border,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(Radii.badge),
        border: Border.all(color: _border, width: cell == _Cell.you ? 1.5 : 1),
      ),
      child: switch (cell) {
        _Cell.free => const _Dot(color: Palette.success),
        _Cell.you => const _Dot(color: Palette.primary),
        _Cell.car => const Icon(
          Icons.directions_car,
          size: 14,
          color: Palette.textSecondary,
        ),
        _ => null,
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// la hoja blanca de abajo con el puesto seleccionado y el boton de reservar

class _SelectedSpotSheet extends StatelessWidget {
  const _SelectedSpotSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Spacing.md)),
        border: Border(top: BorderSide(color: Palette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm,
        Spacing.md,
        Spacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // la rayita gris de arriba de la hoja
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Palette.border,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SELECTED SPOT', style: AppTypography.overline),
                    const SizedBox(height: 2),
                    Text(
                      'B201',
                      style: AppTypography.monoDisplay.copyWith(fontSize: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Walk from entrance', style: AppTypography.caption),
                  const SizedBox(height: 2),
                  Text(
                    '~2 min',
                    style: AppTypography.heading1.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Reserve this spot'),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // el boton de la x para cerrar
              SizedBox(
                width: Spacing.touchTarget,
                height: Spacing.touchTarget,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    side: const BorderSide(color: Palette.border),
                    foregroundColor: Palette.textSecondary,
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
