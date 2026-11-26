import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/cache/array_map_cache.dart';
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
    ConnectivityPort connectivity, {
    DateTime Function()? clock,
  }) : _memory = ArrayMapCache(
         maxEntries: memoryReports,
         ttl: memoryTtl,
         clock: clock,
       ) {
    _updatesSub = _queue.updates.listen(_onUpdate);
    watchConnectivity(connectivity, load);
  }

  static const memoryReports = 32;

  static const memoryTtl = Duration(seconds: 60);

  final ReportRepository _reports;
  final ReportQueue _queue;
  final ArrayMapCache<String, SpotReport> _memory;
  List<String> _sentIds = const [];
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

  Future<void> refresh() => load(refresh: true);

  Future<void> load({bool refresh = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    _pending = await _readPending();
    final remembered = refresh ? null : _fromMemory();
    if (remembered != null) {
      _sent = remembered;
      fromStorage = false;
      isLoading = false;
      _notify();
      return;
    }
    try {
      final result = await _reports.mine();
      _sent = result.data;
      savedAt = result.savedAt;
      fromStorage = result.fromStorage;
      if (!result.fromStorage) _remember(result.data);
    } catch (e) {
      final offline = e is NetworkException && _pending.isNotEmpty;
      errorMessage = offline ? null : errorMessageFor(e);
    }
    isLoading = false;
    _notify();
  }

  void reset() {
    _memory.clear();
    _sentIds = const [];
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
        if (_sentIds.isNotEmpty) {
          _memory.put(report.clientId, report);
          _sentIds = [
            report.clientId,
            for (final id in _sentIds)
              if (id != report.clientId) id,
          ];
        }
      case ReportState.rejected:
        _rejected = [..._rejected, report];
      case ReportState.waiting || ReportState.sending:
        break;
    }
    unawaited(_refreshPending());
  }

  List<SpotReport>? _fromMemory() {
    if (_sentIds.isEmpty) return null;
    final remembered = <SpotReport>[];
    for (final id in _sentIds) {
      final report = _memory.get(id);
      if (report == null) return null;
      remembered.add(report);
    }
    return remembered;
  }

  void _remember(List<SpotReport> reports) {
    if (reports.length > memoryReports) {
      _sentIds = const [];
      return;
    }
    for (final report in reports) {
      _memory.put(report.clientId, report);
    }
    _sentIds = [for (final report in reports) report.clientId];
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
