import 'dart:typed_data';

import '../entities/saved.dart';
import '../entities/spot_report.dart';

abstract interface class ReportRepository {
  Future<SpotReport> send(SpotReport report, {Uint8List? photo});

  Future<Saved<List<SpotReport>>> mine();

  Map<String, String> photoHeaders();
}
