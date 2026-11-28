import 'dart:typed_data';

import '../../domain/entities/saved.dart';
import '../../domain/entities/spot_report.dart';
import '../../domain/ports/report_repository.dart';

class MockReportRepository implements ReportRepository {
  final List<SpotReport> reports = [];
  final Map<String, Uint8List> photos = {};
  Object? failure;
  int sendCalls = 0;
  int mineCalls = 0;

  @override
  Future<SpotReport> send(SpotReport report, {Uint8List? photo}) async {
    sendCalls++;
    final error = failure;
    if (error != null) throw error;
    final id = 'report-${reports.length + 1}';
    if (photo != null) photos[id] = photo;
    final saved = SpotReport(
      id: id,
      clientId: report.clientId,
      spotId: report.spotId,
      levelCode: report.levelCode,
      kind: report.kind,
      shownStatus: report.shownStatus,
      reportedAt: report.reportedAt,
      note: report.note,
      photoUrl: photo == null ? null : 'https://parkwise.test/$id/photo',
      state: ReportState.sent,
    );
    reports.insert(0, saved);
    return saved;
  }

  @override
  Future<Saved<List<SpotReport>>> mine() async {
    mineCalls++;
    final error = failure;
    if (error != null) throw error;
    return Saved(List.of(reports), savedAt: DateTime.now());
  }

  @override
  Map<String, String> photoHeaders() => const {'Authorization': 'Bearer t'};
}
