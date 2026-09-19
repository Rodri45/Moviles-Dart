import '../../domain/ports/connectivity_port.dart';

// version de mentira, siempre dice que hay o no hay internet segun se le pase
class MockConnectivity implements ConnectivityPort {
  const MockConnectivity({this.online = true});

  final bool online;

  @override
  Stream<bool> get isOnline => Stream.value(online);
}
