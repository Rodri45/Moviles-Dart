import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/ports/connectivity_port.dart';

// el estado de la red real usando connectivity_plus
class ConnectivityPlusAdapter implements ConnectivityPort {
  ConnectivityPlusAdapter([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes =>
      _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
