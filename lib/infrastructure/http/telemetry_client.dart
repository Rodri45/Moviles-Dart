import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../domain/errors.dart';
import '../../domain/ports/connectivity_port.dart';
import '../../domain/ports/telemetry.dart';
import 'api_client.dart';

class TelemetryClient implements Telemetry {
  TelemetryClient(this._client, this._queue, this._connectivity) {
    _connectivity.changes.where((online) => online).listen((_) => flush());
  }

  static const maxQueued = 200;

  final ApiClient _client;
  final Box<String> _queue;
  final ConnectivityPort _connectivity;
  bool _flushing = false;

  @override
  void track(String name, [Map<String, Object> properties = const {}]) {
    unawaited(_enqueue({'name': name, 'properties': properties}));
  }

  Future<void> flush() async {
    if (_flushing || !await _connectivity.isOnline()) return;
    _flushing = true;
    try {
      while (_queue.isNotEmpty) {
        final key = _queue.keyAt(0);
        try {
          await _client.post('/telemetry', body: jsonDecode(_queue.get(key)!));
        } on ApiException catch (e) {
          if (e.statusCode >= 500 || e.statusCode == 429) break;
        } on NetworkException {
          break;
        }
        await _queue.delete(key);
      }
    } catch (e) {
      debugPrint('telemetry flush failed: $e');
    } finally {
      _flushing = false;
    }
  }

  Future<void> _enqueue(Map<String, Object> event) async {
    await _queue.add(jsonEncode(event));
    while (_queue.length > maxQueued) {
      await _queue.deleteAt(0);
    }
    await flush();
  }
}
