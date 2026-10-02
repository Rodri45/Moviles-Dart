import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/format.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/spot_cell.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../domain/entities/parking_level.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/reservation.dart';
import '../../shell/main_shell.dart';
import 'offline_view_model.dart';

// pantalla 7, offline: lo ultimo que se guardo mientras vuelve la red
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  static const String routeName = '/offline';

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OfflineViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineViewModel>();
    final levels = offline.levels;
    final reservation = offline.reservation;
    final map = offline.map;

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(offline: offline),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.md,
                  Spacing.md,
                  Spacing.lg,
                ),
                children: [
                  if (!offline.recovered) ...[
                    OfflineBanner(
                      savedAt: levels?.savedAt,
                      online: offline.online,
                    ),
                    const SizedBox(height: Spacing.lg),
                  ],
                  Text('CACHED AVAILABILITY', style: AppTypography.overline),
                  const SizedBox(height: Spacing.sm),
                  if (levels == null)
                    Text('Nothing saved yet', style: AppTypography.caption),
                  for (final level in levels?.data.levels ?? const []) ...[
                    _CachedLevelCard(level: level, savedAt: levels!.savedAt),
                    const SizedBox(height: Spacing.sm),
                  ],
                  const SizedBox(height: Spacing.md),
                  Text('YOUR SAVED RESERVATION', style: AppTypography.overline),
                  const SizedBox(height: Spacing.sm),
                  if (reservation == null)
                    Text('No open reservation', style: AppTypography.caption)
                  else
                    _SavedReservationCard(reservation: reservation),
                  if (map != null && map.data.isNotEmpty) ...[
                    const SizedBox(height: Spacing.md),
                    _CachedMapCard(level: offline.mapLevel, spots: map.data),
                  ],
                  const SizedBox(height: Spacing.md),
                  if (offline.recovered)
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Back to the app'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: offline.isLoading ? null : offline.load,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry connection'),
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
  const _Header({required this.offline});

  final OfflineViewModel offline;

  String get _subtitle {
    if (offline.recovered) return 'Back online · data updated';
    final minutes = offline.minutesSinceSync;
    if (minutes == null) return 'Offline mode';
    return 'Offline mode · last sync $minutes min ago';
  }

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
          Text('ParkWise', style: AppTypography.display),
          const SizedBox(height: Spacing.xs),
          Text(
            _subtitle,
            style: AppTypography.body.copyWith(color: Palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

// card de cada nivel con los datos guardados

class _CachedLevelCard extends StatelessWidget {
  const _CachedLevelCard({required this.level, required this.savedAt});

  final ParkingLevel level;
  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final color = StatusBadge.colorOf(level.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            _CodeBadge(
              code: level.code,
              color: color,
              background: StatusBadge.softOf(level.status),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: level.free == 0
                              ? 'No spots'
                              : '${level.free} free',
                          style: AppTypography.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: '   cached ${formatTime(savedAt)}',
                          style: AppTypography.monoData.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            const _Tag(
              label: 'CACHED',
              color: Palette.warningText,
              background: Palette.warningSoft,
            ),
          ],
        ),
      ),
    );
  }
}

// cuadrito con el codigo (P1, P2, P3, A-07)
class _CodeBadge extends StatelessWidget {
  const _CodeBadge({
    required this.code,
    required this.color,
    required this.background,
  });

  final String code;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(code, style: AppTypography.monoId.copyWith(color: color)),
    );
  }
}

// etiqueta chiquita tipo CACHED / SAVED
class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Text(label, style: AppTypography.overline.copyWith(color: color)),
    );
  }
}

// la card azul de la reserva guardada

class _SavedReservationCard extends StatelessWidget {
  const _SavedReservationCard({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final parked = reservation.status == ReservationStatus.fulfilled;
    final detail = parked
        ? 'Parked · since ${formatTime(reservation.checkedInAt!)}'
        : 'Reserved · expires ${formatTime(reservation.expiresAt)}';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: const BorderSide(color: Palette.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            _CodeBadge(
              code: reservation.spotCode,
              color: Palette.primary,
              background: Palette.primarySoft,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spot ${reservation.spotCode} — Level ${reservation.levelCode}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            const _Tag(
              label: 'SAVED',
              color: Palette.success,
              background: Palette.successSoft,
            ),
          ],
        ),
      ),
    );
  }
}

// la card del mapita guardado, las primeras filas del nivel

class _CachedMapCard extends StatelessWidget {
  const _CachedMapCard({required this.level, required this.spots});

  static const _perRow = 6;
  static const _rows = 3;

  final String level;
  final List<ParkingSpot> spots;

  @override
  Widget build(BuildContext context) {
    final shown = spots.take(_perRow * _rows).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Level $level · cached map',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'OFFLINE',
                  style: AppTypography.monoId.copyWith(
                    fontSize: 11,
                    color: Palette.warningText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            for (var r = 0; r * _perRow < shown.length; r++) ...[
              if (r > 0) const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  for (var c = 0; c < _perRow; c++) ...[
                    if (c > 0) const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: r * _perRow + c < shown.length
                          ? SpotCell(spot: shown[r * _perRow + c])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: Spacing.sm),
            Center(
              child: Text(
                'DATA MAY BE OUTDATED',
                style: AppTypography.monoData.copyWith(
                  fontSize: 9,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
