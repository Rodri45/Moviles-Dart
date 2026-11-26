import 'dart:typed_data';

import '../../domain/entities/spot_report.dart';
import '../../domain/ports/pending_report_store.dart';

class MemoryPendingReportStore implements PendingReportStore {
  final Map<String, SpotReport> reports = {};
  final Map<String, Uint8List> photos = {};

  @override
  Future<void> add(SpotReport report, {Uint8List? photo}) async {
    if (reports.containsKey(report.clientId)) return;
    reports[report.clientId] = report.withState(ReportState.waiting);
    if (photo != null) photos[report.clientId] = photo;
  }

  @override
  Future<List<SpotReport>> pending() async => reports.values.toList();

  @override
  Future<Uint8List?> photoOf(SpotReport report) async =>
      photos[report.clientId];

  @override
  Future<void> setState(String clientId, ReportState state) async {
    final report = reports[clientId];
    if (report != null) reports[clientId] = report.withState(state);
  }

  @override
  Future<void> remove(String clientId) async {
    reports.remove(clientId);
    photos.remove(clientId);
  }

  @override
  Future<void> clear() async {
    reports.clear();
    photos.clear();
  }
}
