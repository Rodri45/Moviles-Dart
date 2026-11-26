import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/header_scroll_view.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/pill.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/spot_filter.dart';
import '../../shell/main_shell.dart';
import '../reserve/reserve_view_model.dart';
import '../voice_search/voice_search_screen.dart';
import '../voice_search/voice_search_view_model.dart';
import 'find_spot_view_model.dart';

class FindSpotScreen extends StatefulWidget {
  const FindSpotScreen({super.key, this.initialFilter});

  static const String routeName = '/find-spot';
  static const String accessibleRouteName = '/accessible-spots';
  static const String evRouteName = '/ev-spots';

  final SpotFilter? initialFilter;

  @override
  State<FindSpotScreen> createState() => _FindSpotScreenState();
}

class _FindSpotScreenState extends State<FindSpotScreen> {
  final _query = TextEditingController();
  final _queryFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        final finder = context.read<FindSpotViewModel>();
        final filter = widget.initialFilter;
        finder.setFilters({
          SpotFilter.available,
          ?filter,
        });
      },
    );
  }

  @override
  void dispose() {
    _query.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  Future<void> _openVoiceSearch() async {
    final outcome = await Navigator.of(
      context,
    ).pushNamed(VoiceSearchScreen.routeName);
    if (!mounted || outcome is! VoiceSearchOutcome) return;
    final finder = context.read<FindSpotViewModel>();
    switch (outcome) {
      case PhraseSearch(:final phrase, :final query, :final spoken):
        _query.text = query.searchText;
        await finder.searchPhrase(phrase, query, spoken: spoken);
      case TypeInstead(:final words):
        finder.typeAfterVoice();
        _query.value = TextEditingValue(
          text: words,
          selection: TextSelection.collapsed(offset: words.length),
        );
        finder.setQuery(words);
        _queryFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final finder = context.watch<FindSpotViewModel>();
    final results = finder.results;

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: HeaderScrollView(
          header: _Header(
            finder: finder,
            query: _query,
            queryFocus: _queryFocus,
            onVoice: () => unawaited(_openVoiceSearch()),
            title: switch (widget.initialFilter) {
              SpotFilter.accessible => 'Accessible spots',
              SpotFilter.electric => 'EV spots',
              _ => 'Find a spot',
            },
          ),
          onRefresh: finder.refresh,
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
              const SizedBox(height: Spacing.sm),
              Text(
                'Filters and search work with this copy. You can pick '
                'a spot now; the reservation is confirmed when the '
                'phone is back online.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: Spacing.md),
            ],
            if (finder.spokenPhrase != null) ...[
              _VoicePhraseCard(
                phrase: finder.spokenPhrase!,
                onTap: () => unawaited(_openVoiceSearch()),
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
            else ...[
              if (finder.recommended != null) ...[
                _RecommendedCard(spot: finder.recommended!),
                const SizedBox(height: Spacing.md),
              ],
              Text(
                '${results.length} spots found',
                style: AppTypography.caption,
              ),
            ],
            const SizedBox(height: Spacing.md),
            for (final spot in results) ...[
              _SpotResultCard(spot: spot),
              const SizedBox(height: Spacing.md),
            ],
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
  const _Header({
    required this.finder,
    required this.query,
    required this.queryFocus,
    required this.onVoice,
    required this.title,
  });

  final FindSpotViewModel finder;
  final TextEditingController query;
  final FocusNode queryFocus;
  final VoidCallback onVoice;
  final String title;

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
          Text(title, style: AppTypography.display),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: query,
            focusNode: queryFocus,
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
              suffixIcon: IconButton(
                tooltip: 'Search by voice',
                icon: const Icon(Icons.mic_none, color: Palette.primary),
                onPressed: onVoice,
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

class _VoicePhraseCard extends StatelessWidget {
  const _VoicePhraseCard({required this.phrase, required this.onTap});

  final String phrase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              const Icon(Icons.mic_none, size: 20, color: Palette.primary),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOU SAID', style: AppTypography.overline),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '“$phrase”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'Again',
                style: AppTypography.button.copyWith(color: Palette.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.spot});

  final ParkingSpot spot;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Palette.primarySoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: Palette.primary.withValues(alpha: 0.4)),
      ),
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
                  Text('RECOMMENDED', style: AppTypography.overline),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Level ${spot.levelCode} · ${spot.walkMinutes} min walk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Free, closest to your destination and matching your '
                    'filters.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
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
              final search = context
                  .read<FindSpotViewModel>()
                  .searchForSelection();
              context.read<ReserveViewModel>().selectSpot(spot, search: search);
              MainShell.openTab(context, AppTab.reserve);
            }
          : null,
      child: const Text('Reserve'),
    );
  }
}
