import 'package:flutter/material.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/pill.dart';

// pantalla 3, find a spot. solo es la vista, los botones no hacen nada
// arriba va el buscador con los filtros y abajo la lista de puestos
class FindSpotScreen extends StatelessWidget {
  const FindSpotScreen({super.key});

  static const String routeName = '/find-spot';

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
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                ),
                children: [
                  Text('6 spots found', style: AppTypography.caption),
                  const SizedBox(height: Spacing.md),
                  for (final spot in _spots) ...[
                    _SpotResultCard(spot: spot),
                    const SizedBox(height: Spacing.md),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppTabBar(current: AppTab.home),
    );
  }
}

// datos de mentira para que se vea algo en la lista

typedef _SpotRow = ({String code, String lot, String walk, String type});

const List<_SpotRow> _spots = [
  (code: 'A103', lot: 'P1 · North', walk: '1 min', type: 'Standard'),
  (code: 'A205', lot: 'P1 · North', walk: '2 min', type: 'Standard'),
  (code: 'B201', lot: 'P1 · North', walk: '2 min', type: 'Standard'),
  (code: 'B108', lot: 'P1 · North', walk: '3 min', type: 'Electric'),
  (code: 'C012', lot: 'P2 · Central', walk: '5 min', type: 'VIP'),
  (code: 'D304', lot: 'P2 · Central', walk: '6 min', type: 'Accessible'),
];

// la parte blanca de arriba: titulo, buscador y los filtros

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.surface,
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.lg,
        Spacing.md,
        Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find a spot', style: AppTypography.display),
          const SizedBox(height: Spacing.md),
          const Row(
            children: [
              Expanded(child: _SearchField()),
              SizedBox(width: Spacing.sm),
              _MicButton(),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              Pill(label: 'Available', selected: true),
              Pill(label: 'VIP'),
              Pill(label: 'Electric'),
              Pill(label: 'Accessible'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Spacing.touchTarget,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        color: Palette.inputFill,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: Palette.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Palette.textSecondary),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Spot code, zone, level...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(color: Palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Spacing.touchTarget,
      height: Spacing.touchTarget,
      decoration: BoxDecoration(
        color: Palette.primarySoft,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: Palette.primary),
      ),
      child: const Icon(Icons.mic_none, size: 20, color: Palette.primary),
    );
  }
}

// cada tarjetica de la lista

class _SpotResultCard extends StatelessWidget {
  const _SpotResultCard({required this.spot});

  final _SpotRow spot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            _CodeBadge(code: spot.code),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.lot, style: AppTypography.heading2),
                  const SizedBox(height: Spacing.xs),
                  _MetaRow(walk: spot.walk, type: spot.type),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            const _ReserveButton(),
          ],
        ),
      ),
    );
  }
}

// el cuadrito azul con el codigo del puesto
class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.primarySoft,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: Palette.primary.withValues(alpha: 0.4)),
      ),
      child: Text(
        code,
        style: AppTypography.monoId.copyWith(color: Palette.primary),
      ),
    );
  }
}

// la linea de "1 min · Standard" con su iconito si es electrico o accesible
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.walk, required this.type});

  final String walk;
  final String type;

  IconData? get _typeIcon => switch (type) {
        'Electric' => Icons.bolt,
        'Accessible' => Icons.accessible,
        _ => null,
      };

  Color get _typeIconColor => switch (type) {
        'Electric' => Palette.warning,
        'Accessible' => Palette.primary,
        _ => Palette.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.schedule, size: 12, color: Palette.textSecondary),
        const SizedBox(width: Spacing.xs),
        Flexible(
          child: Text(
            '$walk  ·  $type',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption,
          ),
        ),
        if (_typeIcon != null) ...[
          const SizedBox(width: Spacing.xs),
          Icon(_typeIcon, size: 12, color: _typeIconColor),
        ],
      ],
    );
  }
}

class _ReserveButton extends StatelessWidget {
  const _ReserveButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(80, 36),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      ),
      onPressed: () {},
      child: const Text('Reserve'),
    );
  }
}
