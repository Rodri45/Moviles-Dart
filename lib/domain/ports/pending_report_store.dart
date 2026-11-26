import 'dart:typed_data';

import '../entities/spot_report.dart';

abstract interface class PendingReportStore {
  Future<void> add(SpotReport report, {Uint8List? photo});

  Future<List<SpotReport>> pending();

  Future<Uint8List?> photoOf(SpotReport report);

  Future<void> setState(String clientId, ReportState state);

  Future<void> remove(String clientId);

  Future<void> clear();
}
