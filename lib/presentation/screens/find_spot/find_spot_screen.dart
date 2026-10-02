import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/pill.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/spot_filter.dart';
import '../../shell/main_shell.dart';
import '../reserve/reserve_view_model.dart';
import 'find_spot_view_model.dart';

// pantalla 3, find a spot. arriba el buscador con los filtros y abajo la
// lista de puestos ordenada por minutos a pie
class FindSpotScreen extends StatefulWidget {
  const FindSpotScreen({super.key});

  static const String routeName = '/find-spot';

  @override
  State<FindSpotScreen> createState() => _FindSpotScreenState();
}

class _FindSpotScreenState extends State<FindSpotScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FindSpotViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finder = context.watch<FindSpotViewModel>();
    final results = finder.results;

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(finder: finder),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                ),
                children: [
                  if (finder.showOffline) ...[
                    OfflineBanner(
                      savedAt: finder.savedAt,
                      online: finder.online,
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                  if (finder.errorMessage != null) ...[
                    NoticeBanner(
                      message: finder.errorMessage!,
                      tone: NoticeTone.danger,
                      icon: Icons.error_outline,
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                  if (finder.isLoading && results.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    Text(
                      '${results.length} spots found',
                      style: AppTypography.caption,
                    ),
                  const SizedBox(height: Spacing.md),
                  for (final spot in results) ...[
                    _SpotResultCard(spot: spot),
                    const SizedBox(height: Spacing.md),
                  ],
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

// la parte blanca de arriba: titulo, buscador y los filtros

class _Header extends StatelessWidget {
  const _Header({required this.finder});

  final FindSpotViewModel finder;

  static const _filterLabels = {
    SpotFilter.available: 'Available',
    SpotFilter.vip: 'VIP',
    SpotFilter.electric: 'Electric',
    SpotFilter.accessible: 'Accessible',
  };

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
          TextField(
            onChanged: finder.setQuery,
            style: AppTypography.body,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Spot code, zone, level...',
              hintStyle: AppTypography.body.copyWith(
                color: Palette.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: Palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final entry in _filterLabels.entries)
                Pill(
                  label: entry.value,
                  selected: finder.filters.contains(entry.key),
                  onTap: () => finder.toggleFilter(entry.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// cada tarjetica de la lista

class _SpotResultCard extends StatelessWidget {
  const _SpotResultCard({required this.spot});

  final ParkingSpot spot;

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
                  Text(
                    'Level ${spot.levelCode} · Zone ${spot.zone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: Spacing.xs),
                  _MetaRow(spot: spot),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            _ReserveButton(spot: spot),
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          code,
          style: AppTypography.monoId.copyWith(color: Palette.primary),
        ),
      ),
    );
  }
}

// la linea de "1 min · Standard" con su iconito si es electrico o accesible
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.spot});

  final ParkingSpot spot;

  (String, IconData?, Color) get _type {
    if (spot.isEv) return ('Electric', Icons.bolt, Palette.warning);
    if (spot.isAccessible) {
      return ('Accessible', Icons.accessible, Palette.primary);
    }
    if (spot.isVip) return ('VIP', null, Palette.textSecondary);
    return ('Standard', null, Palette.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _type;
    final status = spot.isFree ? '' : '  ·  ${spot.status.name}';

    return Row(
      children: [
        const Icon(Icons.schedule, size: 12, color: Palette.textSecondary),
        const SizedBox(width: Spacing.xs),
        Flexible(
          child: Text(
            '${spot.walkMinutes} min  ·  $label$status',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption,
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

class _ReserveButton extends StatelessWidget {
  const _ReserveButton({required this.spot});

  final ParkingSpot spot;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(80, 36),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      ),
      onPressed: spot.isFree
          ? () {
              context.read<ReserveViewModel>().selectSpot(spot);
              MainShell.openTab(context, AppTab.reserve);
            }
          : null,
      child: const Text('Reserve'),
    );
  }
}
