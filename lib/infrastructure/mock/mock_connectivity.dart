import '../../domain/ports/connectivity_port.dart';

/// Adaptador mock de [ConnectivityPort]. Siempre reporta el valor fijado.
class MockConnectivity implements ConnectivityPort {
  const MockConnectivity({this.online = true});

  final bool online;

  @override
  Stream<bool> get isOnline => Stream.value(online);
}
