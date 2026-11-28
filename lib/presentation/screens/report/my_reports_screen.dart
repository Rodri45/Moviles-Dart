import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/cache/report_photo_cache.dart';
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
          onRefresh: reports.refresh,
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: EdgeInsets.symmetric(
                horizontal: max(Spacing.md, (constraints.maxWidth - 720) / 2),
                vertical: Spacing.md,
              ),
              children: [
                if (reports.waiting > 0) ...[
                  NoticeBanner(
                    title: reports.online ? 'Sending' : 'No signal',
                    message: _waitingMessage(reports.waiting, reports.online),
                    icon: reports.online ? Icons.upload : Icons.wifi_off,
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                if (reports.rejected.isNotEmpty) ...[
                  NoticeBanner(
                    message: _rejectedMessage(reports.rejected),
                    tone: NoticeTone.danger,
                    icon: Icons.error_outline,
                  ),
                  const SizedBox(height: Spacing.md),
                ],
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
                    _ReportCard(
                      report: report,
                      now: now,
                      photoHeaders: reports.photoHeaders,
                    ),
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

String _waitingMessage(int count, bool online) {
  final reports = count == 1 ? '1 report is' : '$count reports are';
  return online
      ? '$reports going to ParkWise, one at a time.'
      : '$reports saved on this phone and will be sent when you are back '
            'online.';
}

String _rejectedMessage(List<SpotReport> rejected) {
  final spots = rejected.map((report) => report.spotId).join(', ');
  return 'ParkWise did not accept the report of $spots. You can send it '
      'again with Report a problem.';
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
  const _ReportCard({
    required this.report,
    required this.now,
    required this.photoHeaders,
  });

  final SpotReport report;
  final DateTime now;
  final Map<String, String> photoHeaders;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportThumbnail(report: report, headers: photoHeaders),
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
  const _ReportThumbnail({required this.report, required this.headers});

  static const size = 56.0;

  final SpotReport report;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    final url = report.photoUrl;
    final file = report.photoPath;
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final Widget child;
    if (file != null) {
      child = Image.file(
        File(file),
        width: size,
        height: size,
        cacheWidth: cacheWidth,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _icon(Icons.image_outlined),
      );
    } else if (url != null) {
      child = CachedNetworkImage(
        imageUrl: url,
        httpHeaders: headers,
        cacheManager: ReportPhotoCache.manager,
        width: size,
        height: size,
        memCacheWidth: cacheWidth,
        fit: BoxFit.cover,
        placeholder: (_, _) => _icon(Icons.image_outlined),
        errorWidget: (_, _, _) => _icon(Icons.image_outlined),
      );
    } else {
      child = _icon(Icons.report_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Semantics(
        label: report.hasPhoto ? 'Report photo' : 'Report without a photo',
        child: child,
      ),
    );
  }

  static Widget _icon(IconData icon) => Container(
    width: size,
    height: size,
    color: Palette.background,
    child: Icon(icon, size: 22, color: Palette.textSecondary),
  );
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
