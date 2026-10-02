import 'dart:async';

import '../../domain/ports/connectivity_port.dart';

// version de mentira, con setOnline se simula que se cae o vuelve la red
class MockConnectivity implements ConnectivityPort {
  MockConnectivity({this.online = true});

  bool online;
  final _controller = StreamController<bool>.broadcast();

  void setOnline(bool value) {
    online = value;
    _controller.add(value);
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get changes => _controller.stream;
}
