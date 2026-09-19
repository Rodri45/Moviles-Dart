import 'package:flutter/material.dart';

import '../presentation/root/root_screen.dart';
import '../presentation/screens/find_my_car/find_my_car_screen.dart';
import '../presentation/screens/find_spot/find_spot_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/lot_detail/lot_detail_screen.dart';
import '../presentation/screens/no_spots/no_spots_screen.dart';
import '../presentation/screens/offline/offline_screen.dart';
import '../presentation/screens/reserve/reserve_screen.dart';

// las rutas de la app, por ahora no se usan porque no hay navegacion
abstract final class AppRouter {
  static const String root = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      root => const RootScreen(),
      HomeScreen.routeName => const HomeScreen(),
      LotDetailScreen.routeName => const LotDetailScreen(),
      FindSpotScreen.routeName => const FindSpotScreen(),
      ReserveScreen.routeName => const ReserveScreen(),
      NoSpotsScreen.routeName => const NoSpotsScreen(),
      FindMyCarScreen.routeName => const FindMyCarScreen(),
      OfflineScreen.routeName => const OfflineScreen(),
      _ => const RootScreen(),
    };

    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }
}
