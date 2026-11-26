import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/format.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../domain/entities/spot_report.dart';
import 'my_reports_view_model.dart';
import 'report_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  static const String routeName = '/my-reports';

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    final reports = context.read<MyReportsViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) => reports.load());
  }

  void _newReport() => Navigator.of(context).pushNamed(ReportScreen.routeName);

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<MyReportsViewModel>();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: const Text('My reports'),
        actions: [
          IconButton(
            tooltip: 'New report',
            onPressed: _newReport,
            icon: const Icon(Icons.add, color: Palette.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: reports.load,
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: EdgeInsets.symmetric(
                horizontal: max(Spacing.md, (constraints.maxWidth - 720) / 2),
                vertical: Spacing.md,
              ),
              children: [
                if (reports.fromStorage) ...[
                  NoticeBanner(
                    title: 'Saved on this phone',
                    message: _savedMessage(reports.savedAt),
                    icon: Icons.history,
                  ),
                  const SizedBox(height: Spacing.md),
                ] else if (reports.errorMessage != null) ...[
                  NoticeBanner(
                    message: reports.errorMessage!,
                    tone: NoticeTone.danger,
                    icon: Icons.error_outline,
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                if (reports.isLoading && reports.reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(Spacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (reports.reports.isEmpty)
                  _NoReports(onReport: _newReport)
                else
                  for (final report in reports.reports) ...[
                    _ReportCard(report: report, now: now),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _savedMessage(DateTime? savedAt) {
  if (savedAt == null) return 'It updates when you\'re back online.';
  return 'Updated ${formatDate(savedAt)} at ${formatTime(savedAt)}. '
      'It updates when you\'re back online.';
}

String reportedWhen(DateTime at, DateTime now) {
  final local = at.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final daysAgo = today.difference(day).inDays;
  final time = formatTime(local);
  if (daysAgo == 0) return 'Today, $time';
  if (daysAgo == 1) return 'Yesterday, $time';
  if (daysAgo > 1 && daysAgo < 7) return '${formatWeekday(local)}, $time';
  return '${formatDate(local)}, $time';
}

class _NoReports extends StatelessWidget {
  const _NoReports({required this.onReport});

  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('No reports yet', style: AppTypography.heading1),
            const SizedBox(height: Spacing.xs),
            Text(
              'When a spot does not match the app, report it here. It helps '
              'ParkWise show the real state of the lot.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: Spacing.md),
            FilledButton(
              onPressed: onReport,
              child: const Text('Report a problem'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.now});

  final SpotReport report;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportThumbnail(report: report),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        report.spotId,
                        style: AppTypography.monoId.copyWith(fontSize: 14),
                      ),
                      _StateBadge(state: report.state),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(report.kind.label, style: AppTypography.body),
                  const SizedBox(height: 3),
                  Text(
                    reportedWhen(report.reportedAt, now),
                    style: AppTypography.caption,
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

class _ReportThumbnail extends StatelessWidget {
  const _ReportThumbnail({required this.report});

  final SpotReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Palette.background,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Icon(
        report.hasPhoto ? Icons.image_outlined : Icons.report_outlined,
        size: 22,
        color: Palette.textSecondary,
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state});

  final ReportState state;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (state) {
      ReportState.waiting => (
        'WAITING FOR SIGNAL',
        Palette.warningSoft,
        const Color(0xFF974F0C),
      ),
      ReportState.sending => (
        'SENDING',
        Palette.primarySoft,
        Palette.primary,
      ),
      ReportState.sent => (
        'SENT',
        Palette.primarySoft,
        const Color(0xFF0747A6),
      ),
      ReportState.rejected => (
        'NOT ACCEPTED',
        Palette.dangerSoft,
        Palette.danger,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Text(
        label,
        style: AppTypography.tab.copyWith(
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
