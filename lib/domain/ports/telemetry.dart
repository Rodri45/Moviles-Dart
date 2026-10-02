abstract interface class Telemetry {
  void track(String name, [Map<String, Object> properties = const {}]);
}
