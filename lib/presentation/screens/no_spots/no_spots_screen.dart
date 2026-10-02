import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../domain/entities/nearby_lot.dart';
import '../../shell/main_shell.dart';
import 'no_spots_view_model.dart';

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

  Future<void> _navigate(NearbyLot lot) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await context.read<NoSpotsViewModel>().navigate(lot);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the maps app.')),
      );
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
                    _NearbyCard(
                      lot: lot,
                      closest: lot.id == noSpots.closestId,
                      onNavigate: () => _navigate(lot),
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                  const SizedBox(height: Spacing.sm),
                  _NotifyCard(noSpots: noSpots),
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

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.lot,
    required this.closest,
    required this.onNavigate,
  });

  final NearbyLot lot;
  final bool closest;
  final VoidCallback onNavigate;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (closest) ...[
                        const _ClosestBadge(),
                        const SizedBox(height: Spacing.sm),
                      ],
                      Text(
                        lot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.heading2,
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
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  size: 12,
                  color: Palette.textSecondary,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${lot.walkMinutes} min',
                    style: AppTypography.caption,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                _NavigateButton(primary: closest, onPressed: onNavigate),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigateButton extends StatelessWidget {
  const _NavigateButton({required this.primary, required this.onPressed});

  final bool primary;
  final VoidCallback onPressed;

  static const _size = Size(88, 36);
  static const _padding = EdgeInsets.symmetric(horizontal: Spacing.md);

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(minimumSize: _size, padding: _padding),
        child: const Text('Navigate'),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: _size,
        padding: _padding,
        foregroundColor: Palette.textPrimary,
        backgroundColor: Palette.background,
        side: const BorderSide(color: Palette.border),
      ),
      child: const Text('Navigate'),
    );
  }
}

class _NotifyCard extends StatelessWidget {
  const _NotifyCard({required this.noSpots});

  final NoSpotsViewModel noSpots;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notify when campus opens up',
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    noSpots.watching
                        ? 'On. We check every 30 s while the app is open.'
                        : 'We\'ll ping you the moment a spot opens. Keep the '
                              'app open.',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            OutlinedButton(
              onPressed: noSpots.toggleNotify,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(88, 36),
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                foregroundColor: Palette.secondary,
                backgroundColor: Palette.secondarySoft,
                side: BorderSide(
                  color: Palette.secondary.withValues(alpha: 0.4),
                ),
              ),
              child: Text(noSpots.watching ? 'Turn off' : 'Notify me'),
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
