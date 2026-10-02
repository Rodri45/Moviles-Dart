import 'package:flutter/material.dart';

import '../presentation/screens/find_my_car/find_my_car_screen.dart';
import '../presentation/screens/find_spot/find_spot_screen.dart';
import '../presentation/screens/no_spots/no_spots_screen.dart';
import '../presentation/screens/offline/offline_screen.dart';
import '../presentation/screens/register/register_screen.dart';
import '../presentation/shell/auth_gate.dart';

abstract final class AppRouter {
  static const String root = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      RegisterScreen.routeName => const RegisterScreen(),
      FindSpotScreen.routeName => const FindSpotScreen(),
      NoSpotsScreen.routeName => const NoSpotsScreen(),
      FindMyCarScreen.routeName => const FindMyCarScreen(),
      OfflineScreen.routeName => const OfflineScreen(),
      _ => const AuthGate(),
    };

    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }
}
