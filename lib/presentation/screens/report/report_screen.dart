import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/format.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/pill.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/report_photo.dart';
import '../../../domain/entities/spot_report.dart';
import 'my_reports_view_model.dart';
import 'report_view_model.dart';

String shownAs(SpotStatus status) => switch (status) {
  SpotStatus.free => 'shown as free in ParkWise',
  SpotStatus.reserved => 'shown as reserved in ParkWise',
  SpotStatus.occupied => 'shown as occupied in ParkWise',
  SpotStatus.disabled => 'shown as out of service in ParkWise',
};

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.spot});

  static const String routeName = '/report';

  final ParkingSpot? spot;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final ReportViewModel _report;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _report = context.read<ReportViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _report.start(spot: widget.spot);
      _note.text = _report.note;
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _chooseSpot() async {
    final spot = await showModalBottomSheet<ParkingSpot>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.75,
        child: _SpotPicker(
          load: _report.spotsOf,
          initialLevel: _report.spot?.levelCode ?? 'P1',
        ),
      ),
    );
    if (spot != null) _report.chooseSpot(spot);
  }

  Future<void> _send() async {
    final reports = context.read<MyReportsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final sent = await _report.send();
    if (!mounted || sent == null) return;
    reports.added(sent);
    messenger.showSnackBar(
      SnackBar(content: Text('Report of ${sent.spotId} sent. Thank you.')),
    );
    Navigator.of(context).pop(sent);
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportViewModel>();
    final what = [
      _SpotCard(spot: report.spot, onChange: _chooseSpot),
      const SizedBox(height: Spacing.md),
      Text('What is wrong?', style: AppTypography.heading2),
      const SizedBox(height: Spacing.sm),
      for (final kind in ReportKind.values) ...[
        _KindOption(
          kind: kind,
          selected: kind == report.kind,
          onTap: () => report.chooseKind(kind),
        ),
        const SizedBox(height: Spacing.sm),
      ],
    ];
    final details = [
      const _Optional(title: 'Photo'),
      const SizedBox(height: Spacing.sm),
      _PhotoCard(
        photo: report.photo,
        compressing: report.isCompressing,
        onTake: report.takePhoto,
        onRemove: report.removePhoto,
      ),
      const SizedBox(height: Spacing.md),
      const _Optional(title: 'Note'),
      const SizedBox(height: Spacing.sm),
      TextField(
        controller: _note,
        onChanged: report.changeNote,
        maxLines: 2,
        maxLength: 280,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'A car without a reservation since 8:10',
        ),
      ),
      if (report.errorMessage != null) ...[
        const SizedBox(height: Spacing.sm),
        NoticeBanner(
          message: report.errorMessage!,
          tone: NoticeTone.danger,
          icon: Icons.error_outline,
        ),
      ],
      const SizedBox(height: Spacing.md),
      FilledButton(
        onPressed: report.canSend ? _send : null,
        child: report.isSending
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Palette.textOnPrimary,
                ),
              )
            : const Text('Send report'),
      ),
    ];

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(title: const Text('Report a problem')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  ...what,
                  const SizedBox(height: Spacing.sm),
                  ...details,
                ],
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: what,
                    ),
                  ),
                  const SizedBox(width: Spacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: details,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Optional extends StatelessWidget {
  const _Optional({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: title,
        style: AppTypography.heading2,
        children: [
          TextSpan(
            text: ' (optional)',
            style: AppTypography.caption.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot, required this.onChange});

  final ParkingSpot? spot;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final spot = this.spot;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.md, 14, Spacing.sm, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SPOT', style: AppTypography.overline),
                  const SizedBox(height: 2),
                  if (spot == null)
                    Text('Choose the spot', style: AppTypography.heading1)
                  else ...[
                    Text(
                      spot.id,
                      style: AppTypography.monoDisplay.copyWith(
                        fontSize: 24,
                        color: Palette.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Level ${spot.levelCode} · ${shownAs(spot.status)}',
                      style: AppTypography.caption,
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: onChange,
              child: Text(spot == null ? 'Choose' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindOption extends StatelessWidget {
  const _KindOption({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final ReportKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? Palette.primarySoft : Palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(
            color: selected ? Palette.primary : Palette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.card),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Spacing.touchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? Palette.primary : Palette.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kind.label,
                      style: AppTypography.heading2.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.photo,
    required this.compressing,
    required this.onTake,
    required this.onRemove,
  });

  final ReportPhoto? photo;
  final bool compressing;
  final VoidCallback onTake;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    if (compressing) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Making the photo smaller on the phone…',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (photo == null) {
      return OutlinedButton.icon(
        onPressed: onTake,
        icon: const Icon(Icons.photo_camera_outlined, size: 18),
        label: const Text('Take a photo'),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.sm),
              child: Image.memory(
                photo.bytes,
                width: 72,
                height: 72,
                cacheWidth: 144,
                fit: BoxFit.cover,
                semanticLabel: 'Attached photo',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Photo ready', style: AppTypography.heading2),
                  const SizedBox(height: 3),
                  Text(
                    '${formatBytes(photo.originalBytes)} → '
                    '${formatBytes(photo.sizeBytes)}',
                    style: AppTypography.monoData.copyWith(
                      fontSize: 12,
                      color: Palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Resized on the phone before sending',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Take another photo',
              onPressed: onTake,
              icon: const Icon(Icons.photo_camera_outlined),
            ),
            IconButton(
              tooltip: 'Remove the photo',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotPicker extends StatefulWidget {
  const _SpotPicker({required this.load, required this.initialLevel});

  final Future<List<ParkingSpot>> Function(String levelCode) load;
  final String initialLevel;

  @override
  State<_SpotPicker> createState() => _SpotPickerState();
}

class _SpotPickerState extends State<_SpotPicker> {
  static const _levels = ['P1', 'P2', 'P3'];

  late String _level = widget.initialLevel;
  late Future<List<ParkingSpot>> _spots = widget.load(_level);

  void _selectLevel(String level) {
    setState(() {
      _level = level;
      _spots = widget.load(level);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text('Choose the spot', style: AppTypography.heading1),
              ),
              for (final level in _levels) ...[
                const SizedBox(width: Spacing.xs),
                Pill(
                  label: level,
                  selected: level == _level,
                  onTap: () => _selectLevel(level),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Expanded(
          child: FutureBuilder<List<ParkingSpot>>(
            future: _spots,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'The spots of $_level could not be loaded.',
                    style: AppTypography.caption,
                  ),
                );
              }
              final spots = snapshot.data;
              if (spots == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.separated(
                itemCount: spots.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final spot = spots[index];
                  return ListTile(
                    title: Text(spot.id, style: AppTypography.monoId),
                    subtitle: Text(
                      shownAs(spot.status),
                      style: AppTypography.caption,
                    ),
                    onTap: () => Navigator.of(context).pop(spot),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
