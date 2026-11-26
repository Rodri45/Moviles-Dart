import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../domain/entities/saved.dart';
import '../../domain/entities/spot_report.dart';
import '../../domain/ports/connectivity_port.dart';
import '../../domain/ports/pending_report_store.dart';
import '../../domain/ports/report_queue.dart';
import '../../domain/ports/report_repository.dart';
import 'api_client.dart';

class OutboxReportRepository implements ReportRepository, ReportQueue {
  OutboxReportRepository(
    this._inner,
    this._store,
    ConnectivityPort connectivity,
  ) {
    _connectivitySub = connectivity.changes
        .where((online) => online)
        .listen((_) => flush());
  }

  final ReportRepository _inner;
  final PendingReportStore _store;
  final _updates = StreamController<SpotReport>.broadcast();
  late final StreamSubscription<bool> _connectivitySub;
  Future<void>? _running;

  @override
  Stream<SpotReport> get updates => _updates.stream;

  @override
  Future<List<SpotReport>> pending() => _store.pending();

  @override
  Future<Saved<List<SpotReport>>> mine() => _inner.mine();

  @override
  Map<String, String> photoHeaders() => _inner.photoHeaders();

  @override
  Future<SpotReport> send(SpotReport report, {Uint8List? photo}) async {
    if ((await _store.pending()).isEmpty) {
      try {
        final sent = await _inner.send(report, photo: photo);
        _updates.add(sent);
        return sent;
      } catch (e) {
        if (!ApiClient.isNetworkFailure(e)) rethrow;
      }
    }
    await _store.add(report, photo: photo);
    final waiting = report.withState(ReportState.waiting);
    _updates.add(waiting);
    unawaited(flush());
    return waiting;
  }

  @override
  Future<void> flush() =>
      _running ??= _sendNext().whenComplete(() => _running = null);

  @override
  Future<void> clear() => _store.clear();

  Future<void> _sendNext() {
    return _store.pending().then<void>((reports) {
      if (reports.isEmpty) return null;
      return _sendOne(
        reports.first,
      ).then<void>((goOn) => goOn ? _sendNext() : null);
    });
  }

  Future<bool> _sendOne(SpotReport report) {
    return _store
        .setState(report.clientId, ReportState.sending)
        .then<Uint8List?>((_) {
          _updates.add(report.withState(ReportState.sending));
          return _store.photoOf(report);
        })
        .then<SpotReport>((photo) => _inner.send(report, photo: photo))
        .then<bool>(
          (sent) => _store.remove(report.clientId).then((_) {
            _updates.add(sent);
            return true;
          }),
        )
        .catchError((Object error) => _failed(report, error));
  }

  Future<bool> _failed(SpotReport report, Object error) {
    if (ApiClient.isNetworkFailure(error)) {
      return _store.setState(report.clientId, ReportState.waiting).then((_) {
        _updates.add(report.withState(ReportState.waiting));
        return false;
      });
    }
    debugPrint('report ${report.clientId} rejected: $error');
    return _store.remove(report.clientId).then((_) {
      _updates.add(report.withState(ReportState.rejected));
      return true;
    });
  }

  void dispose() {
    _connectivitySub.cancel();
    _updates.close();
  }
}
