import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/app/dependencies.dart';
import 'package:parkwise/app/parkwise_app.dart';
import 'package:parkwise/presentation/screens/find_my_car/find_my_car_screen.dart';
import 'package:parkwise/presentation/screens/find_spot/find_spot_screen.dart';
import 'package:parkwise/presentation/screens/home/home_screen.dart';
import 'package:parkwise/presentation/screens/level_map/level_map_screen.dart';
import 'package:parkwise/presentation/screens/login/login_screen.dart';
import 'package:parkwise/presentation/screens/no_spots/no_spots_screen.dart';
import 'package:parkwise/presentation/screens/offline/offline_screen.dart';
import 'package:parkwise/presentation/screens/profile/profile_screen.dart';
import 'package:parkwise/presentation/screens/register/register_screen.dart';
import 'package:parkwise/presentation/screens/reserve/reserve_screen.dart';

import 'support/test_app.dart';

void main() {
  setUpAll(() {
    // sin red en los tests: usar la fuente de fallback en vez de descargar
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const screens = <String, Widget>{
    'Login': LoginScreen(),
    'Register': RegisterScreen(),
    'Home': HomeScreen(),
    'Level map': LevelMapScreen(),
    'Find a spot': FindSpotScreen(),
    'Reserve': ReserveScreen(),
    'Profile': ProfileScreen(),
    'No campus spots': NoSpotsScreen(),
    'Find my car': FindMyCarScreen(),
    'Offline': OfflineScreen(),
  };

  const sizes = <String, Size>{
    'phone': Size(390, 844),
    'narrow': Size(320, 568),
  };

  for (final screen in screens.entries) {
    for (final size in sizes.entries) {
      testWidgets('${screen.key} renders on ${size.key}', (tester) async {
        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(testApp(screen.value));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('app with a saved session opens on Home', (tester) async {
    await tester.pumpWidget(ParkWiseApp(dependencies: AppDependencies.mock()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Log in'), findsNothing);
  });
}
