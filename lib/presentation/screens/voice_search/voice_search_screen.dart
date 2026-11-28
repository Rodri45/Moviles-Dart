import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/cache/building_photo_cache.dart';
import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/format.dart';
import '../../../core/widgets/lot_photo.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/pill.dart';
import '../../../domain/entities/building.dart';
import '../../../domain/entities/recent_search.dart';
import '../../../domain/entities/spot_filter.dart';
import '../../../domain/entities/voice_language.dart';
import '../../../domain/entities/voice_query.dart';
import '../../../domain/ports/speech_recognizer.dart';
import 'voice_search_view_model.dart';

class VoiceSearchScreen extends StatefulWidget {
  const VoiceSearchScreen({super.key});

  static const String routeName = '/voice-search';

  @override
  State<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends State<VoiceSearchScreen> {
  late final VoiceSearchViewModel _voice;

  @override
  void initState() {
    super.initState();
    _voice = context.read<VoiceSearchViewModel>();
    _voice.addListener(_closeWhenDone);
    WidgetsBinding.instance.addPostFrameCallback((_) => _voice.open());
  }

  @override
  void dispose() {
    _voice.removeListener(_closeWhenDone);
    unawaited(_voice.close());
    super.dispose();
  }

  void _closeWhenDone() {
    if (!mounted) return;
    final outcome = _voice.takeOutcome();
    if (outcome != null) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceSearchViewModel>();
    final destination = voice.destination;

    return Scaffold(
      backgroundColor: Palette.surface,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(language: voice.language, onLanguage: voice.chooseLanguage),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.sm,
                  Spacing.md,
                  Spacing.lg,
                ),
                children: [
                  if (!voice.online) ...[
                    const NoticeBanner(
                      title: 'No signal',
                      message:
                          'Some phones need internet to recognize voice. If '
                          'it does not work, type your search instead.',
                      icon: Icons.wifi_off,
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                  _Microphone(voice: voice),
                  const SizedBox(height: Spacing.lg),
                  if (destination != null) ...[
                    _DestinationCard(building: destination),
                    const SizedBox(height: Spacing.md),
                  ],
                  _TryCard(phrases: voice.tryPhrases),
                  if (voice.recent.isNotEmpty) ...[
                    const SizedBox(height: Spacing.lg),
                    _RecentList(searches: voice.recent, onTap: voice.repeat),
                  ],
                  const SizedBox(height: Spacing.lg),
                  OutlinedButton.icon(
                    onPressed: voice.typeInstead,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(Spacing.touchTarget),
                    ),
                    icon: const Icon(Icons.keyboard_outlined, size: 18),
                    label: const Text('Type instead'),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.language, required this.onLanguage});

  final VoiceLanguage language;
  final ValueChanged<VoiceLanguage> onLanguage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xs,
        Spacing.sm,
        Spacing.md,
        Spacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close voice search',
            icon: const Icon(Icons.close, color: Palette.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'Voice search',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display,
            ),
          ),
          for (final option in VoiceLanguage.values) ...[
            const SizedBox(width: Spacing.xs),
            Pill(
              label: option.localeId.substring(0, 2).toUpperCase(),
              selected: option == language,
              onTap: () => onLanguage(option),
            ),
          ],
        ],
      ),
    );
  }
}

class _Microphone extends StatelessWidget {
  const _Microphone({required this.voice});

  final VoiceSearchViewModel voice;

  String get _status => switch (voice.status) {
    VoiceStatus.listening => 'LISTENING…',
    VoiceStatus.notUnderstood => 'WE HEARD YOU, BUT…',
    VoiceStatus.failed => 'VOICE DID NOT WORK',
    VoiceStatus.ready => 'TAP TO SPEAK',
  };

  String get _message {
    if (voice.status == VoiceStatus.notUnderstood) {
      return 'We could not find a level, zone or type of spot in '
          '“${voice.words}”. Try one of the phrases below.';
    }
    if (voice.status == VoiceStatus.failed) {
      return switch (voice.failure) {
        SpeechFailure.noPermission =>
          'ParkWise needs the microphone to search by voice. You can allow '
              'it in the settings of the phone, or type your search.',
        SpeechFailure.network =>
          'This phone needs internet to recognize voice. Type your search '
              'instead; it works with the spots saved on the phone.',
        SpeechFailure.noMatch =>
          'We did not hear anything. Tap the microphone and try again.',
        _ => 'Voice search is not available on this phone. Type your '
            'search instead.',
      };
    }
    return voice.words.isEmpty ? 'Say what spot you need' : voice.words;
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 560;
    final ring = compact ? 112.0 : 168.0;
    final listening = voice.isListening;
    final problem =
        voice.status == VoiceStatus.failed ||
        voice.status == VoiceStatus.notUnderstood;

    return Column(
      children: [
        SizedBox.square(
          dimension: ring,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: listening ? Palette.primarySoft : Palette.background,
            ),
            child: Center(
              child: SizedBox.square(
                dimension: ring * 0.55,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: listening ? voice.stopListening : voice.listen,
                  child: Icon(
                    listening ? Icons.stop_rounded : Icons.mic_none,
                    size: compact ? 28 : 36,
                    semanticLabel: listening ? 'Stop listening' : 'Speak',
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          _status,
          style: AppTypography.overline.copyWith(
            color: problem ? Palette.warningText : Palette.primary,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          _message,
          textAlign: TextAlign.center,
          style: problem || voice.words.isEmpty
              ? AppTypography.body.copyWith(color: Palette.textSecondary)
              : AppTypography.display,
        ),
        if (voice.heard.understood) ...[
          const SizedBox(height: Spacing.md),
          _HeardChips(query: voice.heard),
        ],
      ],
    );
  }
}

class _HeardChips extends StatelessWidget {
  const _HeardChips({required this.query});

  final VoiceQuery query;

  static const _filterLabels = {
    SpotFilter.electric: 'Electric',
    SpotFilter.accessible: 'Accessible',
    SpotFilter.vip: 'VIP',
  };

  List<String> get _labels => [
    if (query.levelCode != null) 'Level ${query.levelCode}',
    if (query.spotCode != null)
      'Spot ${query.spotCode}'
    else if (query.zone != null)
      'Zone ${query.zone}',
    for (final filter in query.filters) ?_filterLabels[filter],
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        for (final label in _labels)
          Chip(
            label: Text(label),
            labelStyle: AppTypography.pill.copyWith(color: Palette.primary),
            backgroundColor: Palette.primarySoft,
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.building});

  final Building building;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: LotPhoto(
              name: building.name,
              url: building.imageUrl,
              height: 72,
              cacheManager: BuildingPhotoCache.manager,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DESTINATION', style: AppTypography.overline),
                const SizedBox(height: Spacing.xs),
                Text(
                  building.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading2,
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
        ],
      ),
    );
  }
}

class _TryCard extends StatelessWidget {
  const _TryCard({required this.phrases});

  final List<String> phrases;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: Palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRY SAYING', style: AppTypography.overline),
          for (final phrase in phrases) ...[
            const SizedBox(height: Spacing.sm),
            Text('“$phrase”', style: AppTypography.body),
          ],
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.searches, required this.onTap});

  final List<RecentSearch> searches;
  final ValueChanged<RecentSearch> onTap;

  static String _when(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final today =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return today ? formatTime(local) : formatDate(local);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent searches', style: AppTypography.heading2),
            ),
            Text('Saved on this phone', style: AppTypography.caption),
          ],
        ),
        for (final search in searches)
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: Spacing.touchTarget,
            leading: const Icon(
              Icons.mic_none,
              size: 18,
              color: Palette.textSecondary,
            ),
            title: Text(
              search.phrase,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body,
            ),
            trailing: Text(
              _when(search.searchedAt),
              style: AppTypography.monoData,
            ),
            onTap: () => onTap(search),
          ),
      ],
    );
  }
}
