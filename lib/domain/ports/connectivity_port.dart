// interfaz para saber si hay internet, para la pantalla de offline
abstract interface class ConnectivityPort {
  Stream<bool> get isOnline;
}
