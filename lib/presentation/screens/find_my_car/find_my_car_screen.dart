import 'package:flutter/material.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';

class FindMyCarScreen extends StatelessWidget {
  const FindMyCarScreen({super.key});

  static const String routeName = '/find-my-car';

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.md,
                  Spacing.md,
                  Spacing.lg,
                ),
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          label: 'SPOT',
                          value: 'B201',
                          mono: true,
                          caption: 'P1 · North',
                        ),
                      ),
                      SizedBox(width: Spacing.sm),
                      Expanded(
                        child: _InfoCard(
                          label: 'WALK',
                          value: '~2 min',
                          mono: false,
                          caption: 'via Entrance A',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  const _FloorViewCard(),
                  const SizedBox(height: Spacing.md),
                  const _RouteToggle(),
                  const SizedBox(height: Spacing.md),
                  for (final step in _steps) ...[
                    _StepCard(step: step),
                    const SizedBox(height: Spacing.sm),
                  ],
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

// datos de mentira de los pasos

typedef _Step = ({IconData icon, String text});

const List<_Step> _steps = [
  (icon: Icons.arrow_outward, text: 'Head north toward Zone B'),
  (icon: Icons.arrow_upward, text: 'Pass Zone A (30m)'),
  (icon: Icons.turn_left, text: 'Turn left at the ramp (60m)'),
  (icon: Icons.flag_outlined, text: 'Arrive at Entrance A'),
];

// titulo de arriba

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
        Spacing.lg,
        Spacing.md,
        Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find my car', style: AppTypography.display),
          const SizedBox(height: Spacing.xs),
          Text(
            'Parked today at 8:14 AM',
            style: AppTypography.body.copyWith(color: Palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

// las dos cards de arriba (spot y walk)

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.mono,
    required this.caption,
  });

  final String label;
  final String value;
  final bool mono;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.overline),
            const SizedBox(height: Spacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: mono
                    ? AppTypography.monoDisplay.copyWith(fontSize: 24)
                    : AppTypography.display.copyWith(fontSize: 24),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

// la card del mapita del piso

class _FloorViewCard extends StatelessWidget {
  const _FloorViewCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('P1 · NORTH — FLOOR VIEW', style: AppTypography.overline),
            const SizedBox(height: Spacing.md),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Palette.background,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: const _FloorMap(),
            ),
          ],
        ),
      ),
    );
  }
}

// el mapa: una cuadricula de puestos grises y encima la ruta, la etiqueta
// del carro y la de la entrada. todo se calcula con el ancho disponible
class _FloorMap extends StatelessWidget {
  const _FloorMap();

  static const int _cols = 6;
  static const int _rows = 8;
  static const double _gap = Spacing.sm;
  static const double _cellHeight = 22;

  // fila y columna del carro y de las celdas de la ruta (empezando en 0)
  static const _carRow = 2;
  static const _carCol = 0;
  static const _solidCell = (row: 3, col: 1);
  static const _pathCells = [
    (row: 4, col: 1),
    (row: 5, col: 1),
    (row: 6, col: 1),
    (row: 6, col: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - _gap * (_cols - 1)) / _cols;
        final gridHeight = _rows * _cellHeight + (_rows - 1) * _gap;
        // la etiqueta de entrance va debajo de la ultima fila
        const entranceSpace = 28.0;

        double left(int col) => col * (cellWidth + _gap);
        double top(int row) => row * (_cellHeight + _gap);
        final lineX = left(_carCol) + cellWidth / 2;

        return SizedBox(
          height: gridHeight + entranceSpace,
          child: Stack(
            children: [
              // la cuadricula
              for (var r = 0; r < _rows; r++)
                for (var c = 0; c < _cols; c++)
                  Positioned(
                    left: left(c),
                    top: top(r),
                    width: cellWidth,
                    height: _cellHeight,
                    child: _MapCell(
                      solid: r == _solidCell.row && c == _solidCell.col,
                      path: _pathCells.any((p) => p.row == r && p.col == c),
                      hidden: r == _carRow && c == _carCol,
                    ),
                  ),
              // la linea punteada azul del carro a la entrada
              Positioned(
                left: lineX - 1,
                top: top(_carRow) + _cellHeight,
                width: 2,
                height: gridHeight - top(_carRow) - _cellHeight + Spacing.sm,
                child: const _DashedLine(),
              ),
              // el "~120m" al lado de la linea
              Positioned(
                left: lineX + Spacing.sm,
                top: top(5) - 2,
                child: Text('~120m', style: AppTypography.monoData.copyWith(fontSize: 9)),
              ),
              // la etiqueta del carro
              Positioned(
                left: 0,
                top: top(_carRow) - 2,
                child: const _MapChip(
                  label: 'B201',
                  color: Palette.primary,
                  background: Palette.primarySoft,
                  icon: Icons.directions_car,
                ),
              ),
              // la etiqueta de la entrada
              Positioned(
                left: 0,
                top: gridHeight + Spacing.xs,
                child: const _MapChip(
                  label: 'ENTRANCE',
                  color: Palette.secondary,
                  background: Palette.secondarySoft,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// un puestico gris del mapa. solid = azul lleno, path = borde azul
class _MapCell extends StatelessWidget {
  const _MapCell({
    required this.solid,
    required this.path,
    required this.hidden,
  });

  final bool solid;
  final bool path;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (hidden) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: solid ? Palette.primary : Palette.border,
        borderRadius: BorderRadius.circular(Radii.badge),
        border: path ? Border.all(color: Palette.primary, width: 1.5) : null,
      ),
    );
  }
}

// las etiquetas del mapa (B201 y ENTRANCE)
class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(Radii.badge),
            border: Border.all(color: color),
          ),
          child: Text(
            label,
            style: AppTypography.monoId.copyWith(fontSize: 10, color: color),
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: Spacing.xs),
          Icon(icon, size: 12, color: color),
        ],
      ],
    );
  }
}

// linea vertical punteada
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashedLinePainter());
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.primary
      ..strokeWidth = size.width;
    const dash = 4.0;
    const space = 3.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + space;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
}

// los dos botones de direct route y lit route

class _RouteToggle extends StatelessWidget {
  const _RouteToggle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _RouteOption(label: 'Direct route', selected: true)),
        SizedBox(width: Spacing.sm),
        Expanded(child: _RouteOption(label: 'Lit route', selected: false)),
      ],
    );
  }
}

class _RouteOption extends StatelessWidget {
  const _RouteOption({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Palette.primarySoft : Palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        side: BorderSide(
          color: selected ? Palette.primary : Palette.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(Radii.sm),
        child: SizedBox(
          height: Spacing.touchTarget,
          child: Center(
            child: Text(
              label,
              style: AppTypography.button.copyWith(
                color: selected ? Palette.primary : Palette.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// cada paso de la ruta

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final _Step step;

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
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(color: Palette.border),
              ),
              child: Icon(step.icon, size: 14, color: Palette.textSecondary),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                step.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

