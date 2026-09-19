import 'package:flutter/material.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';


class NoSpotsScreen extends StatelessWidget {
  const NoSpotsScreen({super.key});

  static const String routeName = '/no-spots';

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
                  const _FullBanner(),
                  const SizedBox(height: Spacing.lg),
                  Text('Nearby parking', style: AppTypography.heading1),
                  const SizedBox(height: Spacing.sm),
                  for (final lot in _nearby) ...[
                    _NearbyCard(lot: lot),
                    const SizedBox(height: Spacing.sm),
                  ],
                  const SizedBox(height: Spacing.sm),
                  const _NotifyCard(),
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

// datos de mentira de los parqueaderos cercanos

typedef _Nearby = ({
  String name,
  String walk,
  String free,
  List<String> tags,
  String price,
  bool closest,
});

const List<_Nearby> _nearby = [
  (
    name: 'Parque Central Salitre',
    walk: '4 min',
    free: '22 free',
    tags: ['Lit', 'Guarded'],
    price: '\$3.500/hr',
    closest: true,
  ),
  (
    name: 'Parking Av. El Dorado',
    walk: '6 min',
    free: '8 free',
    tags: ['Lit'],
    price: '\$2.800/hr',
    closest: false,
  ),
  (
    name: 'Zona Azul — Bloque 14',
    walk: '8 min',
    free: '3 free',
    tags: [],
    price: '\$2.000/hr',
    closest: false,
  ),
  (
    name: 'CC Metropolis P3',
    walk: '11 min',
    free: '45 free',
    tags: ['Lit', 'Guarded'],
    price: '\$4.000/hr',
    closest: false,
  ),
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
          Text('No campus spots', style: AppTypography.display),
          const SizedBox(height: Spacing.xs),
          Text(
            'All levels at capacity',
            style: AppTypography.body.copyWith(color: Palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

// el aviso rojo de "campus is full"

class _FullBanner extends StatelessWidget {
  const _FullBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Palette.dangerSoft,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: Palette.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Palette.danger,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: const Icon(Icons.close, size: 18, color: Palette.textOnPrimary),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campus is full',
                  style: AppTypography.heading2.copyWith(color: Palette.danger),
                ),
                const SizedBox(height: 2),
                Text(
                  'All 3 levels at capacity. Verified nearby options below.',
                  style: AppTypography.body.copyWith(color: Palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// cada card de parqueadero cercano. la primera tiene borde azul y "CLOSEST"

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.lot});

  final _Nearby lot;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: lot.closest ? Palette.primary : Palette.border,
          width: lot.closest ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lot.closest) ...[
              const _ClosestBadge(),
              const SizedBox(height: Spacing.sm),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.heading2,
                      ),
                      const SizedBox(height: Spacing.sm),
                      _MetaRow(lot: lot),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lot.price,
                      style: AppTypography.monoId.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _NavigateButton(primary: lot.closest),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosestBadge extends StatelessWidget {
  const _ClosestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: Palette.primarySoft,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Text(
        'CLOSEST',
        style: AppTypography.overline.copyWith(color: Palette.primary),
      ),
    );
  }
}

// la linea de "4 min · 22 free" con las etiquetas de lit y guarded
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.lot});

  final _Nearby lot;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_walk,
              size: 12,
              color: Palette.textSecondary,
            ),
            const SizedBox(width: 2),
            Text(lot.walk, style: AppTypography.caption),
          ],
        ),
        Text(
          lot.free,
          style: AppTypography.caption.copyWith(
            color: Palette.success,
            fontWeight: FontWeight.w600,
          ),
        ),
        for (final tag in lot.tags) _Tag(label: tag),
      ],
    );
  }
}

// etiquetas chiquitas: lit es amarilla y guarded morada
class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isLit = label == 'Lit';
    final color = isLit ? Palette.warningText : Palette.secondary;
    final background = isLit ? Palette.warningSoft : Palette.secondarySoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(fontSize: 11, color: color),
      ),
    );
  }
}

// boton de navigate: azul en la mas cercana, gris en las demas
class _NavigateButton extends StatelessWidget {
  const _NavigateButton({required this.primary});

  final bool primary;

  @override
  Widget build(BuildContext context) {
    const size = Size(88, 32);
    const padding = EdgeInsets.symmetric(horizontal: Spacing.sm);

    if (primary) {
      return FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: size,
          padding: padding,
          textStyle: AppTypography.button.copyWith(fontSize: 12),
        ),
        onPressed: () {},
        child: const Text('Navigate'),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: size,
        padding: padding,
        backgroundColor: Palette.background,
        foregroundColor: Palette.textPrimary,
        side: const BorderSide(color: Palette.border),
        textStyle: AppTypography.button.copyWith(fontSize: 12),
      ),
      onPressed: () {},
      child: const Text('Navigate'),
    );
  }
}

// la card de abajo de "notify when campus opens up"

class _NotifyCard extends StatelessWidget {
  const _NotifyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_none,
                size: 20,
                color: Palette.primary,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  'Notify when campus opens up',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading2,
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Palette.border),
            ],
          ),
        ),
      ),
    );
  }
}
