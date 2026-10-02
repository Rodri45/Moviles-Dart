import '../../domain/ports/directions_launcher.dart';

class MockDirectionsLauncher implements DirectionsLauncher {
  final List<String> opened = [];

  @override
  Future<bool> openDirections(String destination) async {
    opened.add(destination);
    return true;
  }
}
