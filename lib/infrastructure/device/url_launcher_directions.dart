import 'package:url_launcher/url_launcher.dart';

import '../../domain/ports/directions_launcher.dart';

class UrlLauncherDirections implements DirectionsLauncher {
  @override
  Future<bool> openDirections(String destination) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
