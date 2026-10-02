// interfaz para mandar eventos de analitica. nunca bloquea la pantalla:
// el evento se encola y se manda cuando se pueda
abstract interface class Telemetry {
  void track(String name, [Map<String, Object> properties = const {}]);
}
