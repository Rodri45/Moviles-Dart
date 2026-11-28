import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/ports/connectivity_port.dart';

mixin ConnectivityAware on ChangeNotifier {
  static const reconnectRetryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
  ];

  bool online = true;
  StreamSubscription<bool>? _connectivitySub;
  bool _disposed = false;
  int _reconnects = 0;

  bool get showingSavedData => false;

  void watchConnectivity(
    ConnectivityPort connectivity,
    Future<void> Function() reload,
  ) {
    connectivity.isOnline().then((value) {
      if (_disposed) return;
      online = value;
      notifyListeners();
    });
    _connectivitySub = connectivity.changes.listen((value) {
      if (_disposed) return;
      final cameBack = value && !online;
      online = value;
      notifyListeners();
      if (cameBack) unawaited(_refreshAfterReconnect(reload));
    });
  }

  Future<void> _refreshAfterReconnect(Future<void> Function() reload) async {
    final attempt = ++_reconnects;
    bool stillWanted() => !_disposed && online && attempt == _reconnects;

    await _reloadSafely(reload);
    for (final delay in reconnectRetryDelays) {
      if (!stillWanted() || !showingSavedData) return;
      await Future<void>.delayed(delay);
      if (!stillWanted()) return;
      await _reloadSafely(reload);
    }
  }

  Future<void> _reloadSafely(Future<void> Function() reload) async {
    try {
      await reload();
    } catch (e) {
      debugPrint('reload after reconnect failed: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    super.dispose();
  }
}
