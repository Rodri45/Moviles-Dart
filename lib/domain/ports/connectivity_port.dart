abstract interface class ConnectivityPort {
  Future<bool> isOnline();

  Stream<bool> get changes;
}
