// interfaz para saber si hay internet
abstract interface class ConnectivityPort {
  Future<bool> isOnline();

  // avisa cada vez que se pierde o vuelve la red
  Stream<bool> get changes;
}
