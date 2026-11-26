import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/spot_report.dart';
import '../../../domain/errors.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/report_queue.dart';
import '../../../domain/ports/report_repository.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';

class MyReportsViewModel extends ChangeNotifier with ConnectivityAware {
  MyReportsViewModel(
    this._reports,
    this._queue,
    ConnectivityPort connectivity,
  ) {
    _updatesSub = _queue.updates.listen(_onUpdate);
    watchConnectivity(connectivity, load);
  }

  final ReportRepository _reports;
  final ReportQueue _queue;
  late final StreamSubscription<SpotReport> _updatesSub;
  List<SpotReport> _sent = const [];
  List<SpotReport> _pending = const [];
  List<SpotReport> _rejected = const [];
  bool _disposed = false;

  bool isLoading = false;
  bool fromStorage = false;
  DateTime? savedAt;
  String? errorMessage;

  List<SpotReport> get reports {
    final local = {for (final report in _pending) report.clientId};
    return [
      ..._pending,
      ..._rejected,
      for (final report in _sent)
        if (!local.contains(report.clientId)) report,
    ]..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
  }

  int get waiting => _pending.length;

  List<SpotReport> get rejected => _rejected;

  Map<String, String> get photoHeaders => _reports.photoHeaders();

  @override
  bool get showingSavedData => fromStorage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    _pending = await _readPending();
    try {
      final result = await _reports.mine();
      _sent = result.data;
      savedAt = result.savedAt;
      fromStorage = result.fromStorage;
    } catch (e) {
      final offline = e is NetworkException && _pending.isNotEmpty;
      errorMessage = offline ? null : errorMessageFor(e);
    }
    isLoading = false;
    _notify();
  }

  void reset() {
    _sent = const [];
    _pending = const [];
    _rejected = const [];
    fromStorage = false;
    savedAt = null;
    errorMessage = null;
    unawaited(
      _queue.clear().catchError(
        (Object e) => debugPrint('report queue not cleared: $e'),
      ),
    );
    notifyListeners();
  }

  void _onUpdate(SpotReport report) {
    switch (report.state) {
      case ReportState.sent:
        _sent = [
          report,
          for (final item in _sent)
            if (item.clientId != report.clientId) item,
        ];
      case ReportState.rejected:
        _rejected = [..._rejected, report];
      case ReportState.waiting || ReportState.sending:
        break;
    }
    unawaited(_refreshPending());
  }

  Future<void> _refreshPending() async {
    _pending = await _readPending();
    _notify();
  }

  Future<List<SpotReport>> _readPending() async {
    try {
      return await _queue.pending();
    } catch (e) {
      debugPrint('pending reports not read: $e');
      return const [];
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_updatesSub.cancel());
    super.dispose();
  }
}
