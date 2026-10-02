import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/ports/connectivity_port.dart';

mixin ConnectivityAware on ChangeNotifier {
  bool online = true;
  StreamSubscription<bool>? _connectivitySub;
  bool _disposed = false;

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
      final cameBack = value && !online;
      online = value;
      notifyListeners();
      if (cameBack) reload();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    super.dispose();
  }
}
