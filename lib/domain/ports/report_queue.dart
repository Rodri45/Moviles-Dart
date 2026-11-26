import '../entities/spot_report.dart';

abstract interface class ReportQueue {
  Stream<SpotReport> get updates;

  Future<List<SpotReport>> pending();

  Future<void> flush();

  Future<void> clear();
}
