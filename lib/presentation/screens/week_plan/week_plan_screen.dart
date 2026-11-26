import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/format.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/pill.dart';
import '../home/home_view_model.dart';
import 'week_heat_map.dart';
import 'week_plan_view_model.dart';

const _heatColors = [
  Color(0xFFDEEBFF),
  Color(0xFFB3D4FF),
  Color(0xFF4C9AFF),
  Color(0xFF2684FF),
  Color(0xFF0052CC),
  Color(0xFF0747A6),
];

class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({super.key});

  static const String routeName = '/week-plan';

  @override
  State<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends State<WeekPlanScreen> {
  @override
  void initState() {
    super.initState();
    final week = context.read<WeekPlanViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) => week.open());
  }

  Future<void> _pickTime(WeekPlanViewModel week) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(week.arrivalAt),
    );
    if (picked != null) await week.setArrivalTime(picked.hour, picked.minute);
  }

  void _useTime(BestTime time) {
    unawaited(context.read<HomeViewModel>().planArrival(time.start));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final week = context.watch<WeekPlanViewModel>();
    final heatMap = _HeatMapCard(week: week);
    final bestTimes = _BestTimesCard(week: week, onUse: _useTime);

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(title: const Text('Plan your week')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: week.refresh,
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                if (week.showingSavedData) ...[
                  NoticeBanner(
                    title: week.online ? 'Server unreachable' : 'No signal',
                    message: _savedWeekMessage(week),
                    icon: week.online ? Icons.cloud_off : Icons.wifi_off,
                  ),
                  const SizedBox(height: Spacing.md),
                ] else if (week.errorMessage != null) ...[
                  NoticeBanner(
                    message: week.errorMessage!,
                    tone: NoticeTone.danger,
                    icon: Icons.error_outline,
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                _Controls(week: week, onPickTime: () => _pickTime(week)),
                const SizedBox(height: Spacing.md),
                if (constraints.maxWidth >= 720)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: heatMap),
                      const SizedBox(width: Spacing.md),
                      Expanded(flex: 2, child: bestTimes),
                    ],
                  )
                else ...[
                  heatMap,
                  const SizedBox(height: Spacing.md),
                  bestTimes,
                ],
                if (week.updatedAt != null) ...[
                  const SizedBox(height: Spacing.md),
                  Text(_footer(week), style: AppTypography.caption),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _savedWeekMessage(WeekPlanViewModel week) {
  final savedAt = week.updatedAt;
  if (!week.fromStorage || savedAt == null) {
    return 'There is no week saved on this phone yet. It loads by itself '
        'when the signal returns.';
  }
  final saved =
      'Showing the week saved on ${formatDayMonth(savedAt)} at '
      '${formatTime(savedAt)}.';
  final missing = week.missingDays;
  if (missing.isEmpty) return saved;
  if (missing.length == 1) {
    return '$saved ${formatWeekday(missing.first)} was not saved yet.';
  }
  return '$saved ${formatWeekday(missing.first)} to '
      '${formatWeekday(missing.last)} were not saved yet.';
}

String _footer(WeekPlanViewModel week) {
  final at = week.updatedAt!;
  final when = week.fromStorage
      ? 'Saved ${formatDayMonth(at)}, ${formatTime(at)}'
      : 'Updated ${formatTime(at)}';
  final kept = week.savedOnPhone && !week.fromStorage
      ? ' · Kept on this phone'
      : '';
  return 'Based on the last 4 weeks of occupancy · $when$kept';
}

class _Controls extends StatelessWidget {
  const _Controls({required this.week, required this.onPickTime});

  final WeekPlanViewModel week;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onPickTime,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            foregroundColor: Palette.textPrimary,
            side: const BorderSide(color: Palette.border),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.schedule, size: 16),
          label: Text('Arrive around ${formatTime(week.arrivalAt)}'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final code in WeekPlanViewModel.levelCodes) ...[
              if (code != WeekPlanViewModel.levelCodes.first)
                const SizedBox(width: Spacing.xs),
              Pill(
                label: code,
                selected: code == week.level,
                onTap: () => week.selectLevel(code),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeatMapCard extends StatelessWidget {
  const _HeatMapCard({required this.week});

  final WeekPlanViewModel week;

  @override
  Widget build(BuildContext context) {
    final rows = week.heatMap.rows;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PREDICTED OCCUPANCY · ${week.level}'
              '${week.fromStorage ? ' · SAVED' : ''}',
              style: AppTypography.overline,
            ),
            const SizedBox(height: Spacing.sm),
            if (rows.isEmpty || !week.hasWeek)
              SizedBox(
                height: 96,
                child: Center(
                  child: week.isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          'The week is not available yet.',
                          style: AppTypography.caption,
                        ),
                ),
              )
            else ...[
              _HeatGrid(hours: week.hours, rows: rows),
              const SizedBox(height: Spacing.sm),
              _Legend(arrivalAt: week.arrivalAt, saved: week.fromStorage),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeatGrid extends StatelessWidget {
  const _HeatGrid({required this.hours, required this.rows});

  final List<int> hours;
  final List<HeatRow> rows;

  static const _labelWidth = 34.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final hourStyle = AppTypography.monoData.copyWith(fontSize: 10);
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: _labelWidth),
            for (final hour in hours) ...[
              const SizedBox(width: _gap),
              Expanded(
                child: Text(
                  hour.isEven ? '$hour' : '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: hourStyle,
                ),
              ),
            ],
          ],
        ),
        for (final row in rows) ...[
          const SizedBox(height: _gap),
          Row(
            children: [
              SizedBox(
                width: _labelWidth,
                child: Text(
                  formatWeekday(row.date),
                  style: AppTypography.caption.copyWith(
                    color: row.saved
                        ? Palette.textPrimary
                        : Palette.textSecondary,
                  ),
                ),
              ),
              for (var index = 0; index < row.cells.length; index++) ...[
                const SizedBox(width: _gap),
                Expanded(
                  child: _Cell(
                    cell: row.cells[index],
                    saved: row.saved,
                    label: '${formatWeekday(row.date)} ${hours[index]}:00',
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.cell, required this.saved, required this.label});

  final HeatCell cell;
  final bool saved;
  final String label;

  @override
  Widget build(BuildContext context) {
    final step = cell.step;
    final occupancy = cell.occupancy;
    if (!saved) {
      return Semantics(
        label: '$label, not saved',
        child: const SizedBox(height: 22, child: _Hatch()),
      );
    }
    return Semantics(
      label: occupancy == null
          ? '$label, no data'
          : '$label, ${(occupancy * 100).round()}% full',
      child: Container(
        height: 22,
        decoration: BoxDecoration(
          color: step == null ? Palette.background : _heatColors[step],
          borderRadius: BorderRadius.circular(Radii.badge),
          border: cell.best
              ? Border.all(color: Palette.warningText, width: 2)
              : null,
        ),
      ),
    );
  }
}

class _Hatch extends StatelessWidget {
  const _Hatch();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.badge),
      child: const CustomPaint(
        painter: _HatchPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.surface);
    final line = Paint()
      ..color = Palette.border
      ..strokeWidth = 3;
    for (var x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) => false;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.arrivalAt, required this.saved});

  final DateTime arrivalAt;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.caption.copyWith(fontSize: 11);
    return Wrap(
      spacing: 6,
      runSpacing: Spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Empty', style: style),
        for (final color in _heatColors)
          Container(
            width: 18,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        Text('Full', style: style),
        const SizedBox(width: Spacing.sm),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.badge),
            border: Border.all(color: Palette.warningText, width: 2),
          ),
        ),
        Text('Best near ${formatTime(arrivalAt)}', style: style),
        if (saved) ...[
          const SizedBox(width: Spacing.sm),
          const SizedBox(width: 12, height: 12, child: _Hatch()),
          Text('Not saved', style: style),
        ],
      ],
    );
  }
}

class _BestTimesCard extends StatelessWidget {
  const _BestTimesCard({required this.week, required this.onUse});

  final WeekPlanViewModel week;
  final ValueChanged<BestTime> onUse;

  @override
  Widget build(BuildContext context) {
    final best = week.heatMap.best;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              14,
              Spacing.md,
              6,
            ),
            child: Text(
              week.fromStorage
                  ? 'BEST TIMES IN THE SAVED DAYS'
                  : 'BEST TIMES THIS WEEK',
              style: AppTypography.overline,
            ),
          ),
          if (best.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                0,
                Spacing.md,
                Spacing.md,
              ),
              child: Text(
                week.isLoading
                    ? 'Looking for the best times…'
                    : 'No history from Monday to Friday near '
                          '${formatTime(week.arrivalAt)} yet.',
                style: AppTypography.caption,
              ),
            ),
          for (final time in best) ...[
            const Divider(),
            _BestTimeRow(
              time: time,
              level: week.level,
              onUse: () => onUse(time),
            ),
          ],
        ],
      ),
    );
  }
}

class _BestTimeRow extends StatelessWidget {
  const _BestTimeRow({
    required this.time,
    required this.level,
    required this.onUse,
  });

  final BestTime time;
  final String level;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatWeekday(time.start)} · ${formatTime(time.start)}',
                style: AppTypography.heading2,
              ),
              const SizedBox(height: 2),
              Text(
                'Level $level · ${(time.occupancy * 100).round()}% full '
                'expected',
                style: AppTypography.caption,
              ),
            ],
          ),
          OutlinedButton(
            onPressed: onUse,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Use this time'),
          ),
        ],
      ),
    );
  }
}
