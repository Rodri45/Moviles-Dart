import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/spot_cell.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/spot_filter.dart';
import '../../shell/main_shell.dart';
import '../../shell/shell_view_model.dart';
import '../reserve/reserve_view_model.dart';
import 'level_map_view_model.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen>
    with WidgetsBindingObserver {
  late final LevelMapViewModel _map;
  bool _resumed = true;
  bool? _visible;

  @override
  void initState() {
    super.initState();
    _map = context.read<LevelMapViewModel>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _map.selectLevel(_map.levelCode),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _resumed = state == AppLifecycleState.resumed);
  }

  void _syncVisibility(bool visible) {
    if (visible == _visible) return;
    _visible = visible;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _map.setVisible(visible);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _map.setVisible(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ShellViewModel>().tab;
    final isTop = ModalRoute.isCurrentOf(context) ?? true;
    _syncVisibility(tab == AppTab.map && isTop && _resumed);

    final map = context.watch<LevelMapViewModel>();
    final highlighted = map.highlighted;
    if (map.awaitingPaint) {
      WidgetsBinding.instance.addPostFrameCallback((_) => map.gridPainted());
    }

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(map: map),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.md,
                      Spacing.md,
                      Spacing.md,
                      200,
                    ),
                    children: [
                      if (map.showOffline) ...[
                        OfflineBanner(savedAt: map.savedAt, online: map.online),
                        const SizedBox(height: Spacing.md),
                      ],
                      if (map.notice != null) ...[
                        NoticeBanner(message: map.notice!),
                        const SizedBox(height: Spacing.md),
                      ],
                      if (map.errorMessage != null && map.spots.isEmpty) ...[
                        NoticeBanner(
                          message: map.errorMessage!,
                          tone: NoticeTone.danger,
                          icon: Icons.error_outline,
                        ),
                        const SizedBox(height: Spacing.md),
                      ],
                      const _EntranceCard(),
                      const SizedBox(height: Spacing.md),
                      if (map.isLoading && map.spots.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(Spacing.lg),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      for (final zone in map.zones.entries) ...[
                        _ZoneSection(
                          name: zone.key,
                          spots: zone.value,
                          map: map,
                        ),
                        const SizedBox(height: Spacing.md),
                      ],
                    ],
                  ),
                  if (highlighted != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _SelectedSpotSheet(
                        spot: highlighted,
                        isRecommendation: map.selected == null,
                        onClose: map.clearSelection,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.map});

  final LevelMapViewModel map;

  static const _filterLabels = {
    SpotFilter.available: 'Available',
    SpotFilter.vip: 'VIP',
    SpotFilter.electric: 'Electric',
    SpotFilter.accessible: 'Accessible',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Palette.surface,
        border: Border(bottom: BorderSide(color: Palette.border)),
      ),
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
                    Text('LEVEL', style: AppTypography.overline),
                    const SizedBox(height: 2),
                    Text(
                      'Level ${map.levelCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Row(
                children: [
                  for (final code in LevelMapViewModel.levelCodes) ...[
                    if (code != LevelMapViewModel.levelCodes.first)
                      const SizedBox(width: Spacing.xs),
                    Pill(
                      label: code,
                      selected: code == map.levelCode,
                      onTap: () => map.selectLevel(code),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const SpotLegend(),
          const SizedBox(height: Spacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final entry in _filterLabels.entries) ...[
                  Pill(
                    label: entry.value,
                    selected: map.filters.contains(entry.key),
                    onTap: () => map.toggleFilter(entry.key),
                  ),
                  const SizedBox(width: Spacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
            Text(
              'ENTRANCE / EXIT',
              style: AppTypography.overline.copyWith(
                color: Palette.textPrimary,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(child: Container(height: 1, color: Palette.border)),
            const SizedBox(width: Spacing.sm),
            const Icon(
              Icons.arrow_forward,
              size: 12,
              color: Palette.textSecondary,
            ),
            const SizedBox(width: 2),
            Text('N', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _ZoneSection extends StatelessWidget {
  const _ZoneSection({
    required this.name,
    required this.spots,
    required this.map,
  });

  static const _perRow = 6;

  final String name;
  final List<ParkingSpot> spots;
  final LevelMapViewModel map;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (var i = 0; i < spots.length; i += _perRow)
        spots.sublist(i, (i + _perRow).clamp(0, spots.length)),
    ];
    final recommendedId = map.recommended?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: Palette.primary),
            const SizedBox(width: Spacing.sm),
            Text(
              'Zone $name',
              style: AppTypography.heading2.copyWith(color: Palette.primary),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        const _RoadLine(),
        const SizedBox(height: Spacing.sm),
        for (var r = 0; r < rows.length; r++) ...[
          Row(
            children: [
              SizedBox(
                width: 14,
                child: Text('${r + 1}', style: AppTypography.monoData),
              ),
              for (var c = 0; c < _perRow; c++) ...[
                if (c > 0) const SizedBox(width: Spacing.xs),
                Expanded(
                  child: c < rows[r].length
                      ? SpotCell(
                          spot: rows[r][c],
                          selected: rows[r][c].id == map.selected?.id,
                          recommended: rows[r][c].id == recommendedId,
                          onTap: () => map.selectSpot(rows[r][c]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
          if (r < rows.length - 1) const SizedBox(height: Spacing.sm),
        ],
      ],
    );
  }
}

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

class _SelectedSpotSheet extends StatelessWidget {
  const _SelectedSpotSheet({
    required this.spot,
    required this.isRecommendation,
    required this.onClose,
  });

  final ParkingSpot spot;
  final bool isRecommendation;
  final VoidCallback onClose;

  void _reserve(BuildContext context) {
    context.read<ReserveViewModel>().selectSpot(spot);
    MainShell.openTab(context, AppTab.reserve);
  }

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
                    Text(
                      isRecommendation ? 'RECOMMENDED SPOT' : 'SELECTED SPOT',
                      style: AppTypography.overline,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spot.code,
                      style: AppTypography.monoDisplay.copyWith(fontSize: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Walk to destination', style: AppTypography.caption),
                  const SizedBox(height: 2),
                  Text(
                    '~${spot.walkMinutes} min',
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
                  onPressed: () => _reserve(context),
                  child: const Text('Reserve this spot'),
                ),
              ),
              if (!isRecommendation) ...[
                const SizedBox(width: Spacing.sm),
                SizedBox(
                  width: Spacing.touchTarget,
                  height: Spacing.touchTarget,
                  child: OutlinedButton(
                    onPressed: onClose,
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
            ],
          ),
        ],
      ),
    );
  }
}
