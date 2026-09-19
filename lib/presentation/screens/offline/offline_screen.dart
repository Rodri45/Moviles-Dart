import 'package:flutter/material.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  static const String routeName = '/offline';

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
                  const _NoSignalBanner(),
                  const SizedBox(height: Spacing.lg),
                  Text('CACHED AVAILABILITY', style: AppTypography.overline),
                  const SizedBox(height: Spacing.sm),
                  for (final level in _levels) ...[
                    _CachedLevelCard(level: level),
                    const SizedBox(height: Spacing.sm),
                  ],
                  const SizedBox(height: Spacing.md),
                  Text('YOUR SAVED RESERVATION', style: AppTypography.overline),
                  const SizedBox(height: Spacing.sm),
                  const _SavedReservationCard(),
                  const SizedBox(height: Spacing.md),
                  const _CachedMapCard(),
                  const SizedBox(height: Spacing.md),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry connection'),
                  ),
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

// datos de mentira

enum _Status { available, limited, full }

typedef _Level = ({String code, String name, String free, _Status status});

const List<_Level> _levels = [
  (code: 'P1', name: 'Level P1 · North', free: '14 free', status: _Status.available),
  (code: 'P2', name: 'Level P2 · Central', free: '3 free', status: _Status.limited),
  (code: 'P3', name: 'Level P3 · South', free: 'No spots', status: _Status.full),
];

enum _Cell { gray, free, reserved, you }

const List<List<_Cell>> _map = [
  [_Cell.gray, _Cell.free, _Cell.free, _Cell.gray, _Cell.reserved, _Cell.free],
  [_Cell.gray, _Cell.gray, _Cell.free, _Cell.you, _Cell.gray, _Cell.free],
  [_Cell.reserved, _Cell.free, _Cell.gray, _Cell.free, _Cell.free, _Cell.gray],
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
          Text('ParkWise', style: AppTypography.display),
          const SizedBox(height: Spacing.xs),
          Text(
            'Offline mode · last sync 41 min ago',
            style: AppTypography.body.copyWith(color: Palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

// el aviso amarillo de "no signal"

class _NoSignalBanner extends StatelessWidget {
  const _NoSignalBanner();

  @override
  Widget build(BuildContext context) {
    final body = AppTypography.body.copyWith(color: Palette.textSecondary);
    final bold = body.copyWith(
      color: Palette.textPrimary,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Palette.warningSoft,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: Palette.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Palette.warningText,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: const Icon(
              Icons.wifi_off,
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
                  'No signal',
                  style: AppTypography.heading2.copyWith(color: Palette.warningText),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: body,
                    children: [
                      const TextSpan(text: 'Showing cached data from '),
                      TextSpan(text: '8:03 AM', style: bold),
                      const TextSpan(text: ' · Sep 4, 2026'),
                    ],
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

// card de cada nivel con los datos guardados

class _CachedLevelCard extends StatelessWidget {
  const _CachedLevelCard({required this.level});

  final _Level level;

  Color get _color => switch (level.status) {
        _Status.available => Palette.success,
        _Status.limited => Palette.warning,
        _Status.full => Palette.danger,
      };

  Color get _soft => switch (level.status) {
        _Status.available => Palette.successSoft,
        _Status.limited => Palette.warningSoft,
        _Status.full => Palette.dangerSoft,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            _CodeBadge(code: level.code, color: _color, background: _soft),
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
                          text: level.free,
                          style: AppTypography.caption.copyWith(
                            color: _color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: '   cached 8:03 AM',
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

// cuadrito con el codigo (P1, P2, P3, B201)
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
  const _SavedReservationCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: const BorderSide(color: Palette.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            const _CodeBadge(
              code: 'B201',
              color: Palette.primary,
              background: Palette.primarySoft,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spot B201 — P1 North',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Reserved today · expires 8:30 AM',
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

// la card del mapita guardado

class _CachedMapCard extends StatelessWidget {
  const _CachedMapCard();

  @override
  Widget build(BuildContext context) {
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
                    'P1 North · cached map',
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
            for (var r = 0; r < _map.length; r++) ...[
              Row(
                children: [
                  for (var c = 0; c < _map[r].length; c++) ...[
                    if (c > 0) const SizedBox(width: Spacing.sm),
                    Expanded(child: _MapCell(cell: _map[r][c])),
                  ],
                ],
              ),
              if (r < _map.length - 1) const SizedBox(height: Spacing.sm),
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

// cada puestico del mapa
class _MapCell extends StatelessWidget {
  const _MapCell({required this.cell});

  final _Cell cell;

  Color get _fill => switch (cell) {
        _Cell.gray => Palette.background,
        _Cell.free => Palette.successSoft,
        _Cell.reserved => Palette.warningSoft,
        _Cell.you => Palette.primarySoft,
      };

  Color get _border => switch (cell) {
        _Cell.gray => Palette.border,
        _Cell.free => Palette.success.withValues(alpha: 0.3),
        _Cell.reserved => Palette.warning.withValues(alpha: 0.5),
        _Cell.you => Palette.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(Radii.badge),
        border: Border.all(color: _border, width: cell == _Cell.you ? 1.5 : 1),
      ),
    );
  }
}
