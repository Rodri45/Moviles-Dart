import 'package:flutter/foundation.dart';

import '../../../domain/entities/spot_report.dart';
import '../../../domain/ports/report_repository.dart';
import '../../shared/error_messages.dart';

class MyReportsViewModel extends ChangeNotifier {
  MyReportsViewModel(this._reports);

  final ReportRepository _reports;

  List<SpotReport> reports = const [];
  bool isLoading = false;
  bool fromStorage = false;
  DateTime? savedAt;
  String? errorMessage;

  Map<String, String> get photoHeaders => _reports.photoHeaders();

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _reports.mine();
      reports = result.data;
      savedAt = result.savedAt;
      fromStorage = result.fromStorage;
    } catch (e) {
      errorMessage = errorMessageFor(e);
    }
    isLoading = false;
    notifyListeners();
  }

  void added(SpotReport report) {
    reports = [
      report,
      for (final item in reports)
        if (item.clientId != report.clientId) item,
    ];
    notifyListeners();
  }

  void reset() {
    reports = const [];
    fromStorage = false;
    savedAt = null;
    errorMessage = null;
    notifyListeners();
  }
}
