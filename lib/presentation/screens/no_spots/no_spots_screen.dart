import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../domain/entities/nearby_lot.dart';
import '../../shell/main_shell.dart';
import '../home/home_view_model.dart';
import 'no_spots_view_model.dart';

// pantalla 5, se abre sola cuando GET /levels dice campusFull
class NoSpotsScreen extends StatefulWidget {
  const NoSpotsScreen({super.key});

  static const String routeName = '/no-spots';

  @override
  State<NoSpotsScreen> createState() => _NoSpotsScreenState();
}

class _NoSpotsScreenState extends State<NoSpotsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NoSpotsViewModel>().load(),
    );
  }

  // vuelve a pedir los niveles y si ya hay puestos regresa a home
  Future<void> _checkAgain() async {
    final home = context.read<HomeViewModel>();
    await home.load();
    if (!mounted) return;
    if (home.levels?.data.campusFull == false) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final noSpots = context.watch<NoSpotsViewModel>();

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
                  if (noSpots.errorMessage != null)
                    NoticeBanner(
                      message: noSpots.errorMessage!,
                      tone: NoticeTone.danger,
                      icon: Icons.error_outline,
                    ),
                  if (noSpots.isLoading && noSpots.lots.isEmpty)
                    const Center(child: CircularProgressIndicator()),
                  for (final lot in noSpots.lots) ...[
                    _NearbyCard(lot: lot, closest: lot.id == noSpots.closestId),
                    const SizedBox(height: Spacing.sm),
                  ],
                  const SizedBox(height: Spacing.sm),
                  OutlinedButton.icon(
                    onPressed: _checkAgain,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Check campus again'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppTabBar(
        current: AppTab.home,
        onSelected: (tab) => MainShell.openTab(context, tab),
      ),
    );
  }
}

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
            child: const Icon(
              Icons.close,
              size: 18,
              color: Palette.textOnPrimary,
            ),
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
                  'All 3 levels at capacity. Nearby options below.',
                  style: AppTypography.body.copyWith(
                    color: Palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// cada card de parqueadero cercano. la mas cercana tiene borde azul y "CLOSEST"

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.lot, required this.closest});

  final NearbyLot lot;
  final bool closest;

  // 6000 -> "$6.000/hr", como se escriben los precios en colombia
  String get _price {
    final digits = lot.ratePerHour.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '\$$buffer/hr';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: closest ? Palette.primary : Palette.border,
          width: closest ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (closest) ...[
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
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            size: 12,
                            color: Palette.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${lot.walkMinutes} min  ·  ${lot.address}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Text(
                  _price,
                  style: AppTypography.monoId.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
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
