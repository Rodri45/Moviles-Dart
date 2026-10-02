import '../../domain/ports/telemetry.dart';

class MockTelemetry implements Telemetry {
  final List<({String name, Map<String, Object> properties})> events = [];

  @override
  void track(String name, [Map<String, Object> properties = const {}]) {
    events.add((name: name, properties: properties));
  }

  Iterable<Map<String, Object>> named(String name) =>
      events.where((e) => e.name == name).map((e) => e.properties);
}
