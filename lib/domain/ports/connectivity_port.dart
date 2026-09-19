/// Puerto de salida para saber si hay conexión. Alimenta la pantalla "Offline".
abstract interface class ConnectivityPort {
  Stream<bool> get isOnline;
}
