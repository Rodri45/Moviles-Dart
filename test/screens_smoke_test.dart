import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/app/dependencies.dart';
import 'package:parkwise/app/parkwise_app.dart';
import 'package:parkwise/domain/entities/car_location.dart';
import 'package:parkwise/domain/entities/geo_point.dart';
import 'package:parkwise/domain/entities/parked_vehicle.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_vehicle_locator.dart';
import 'package:parkwise/infrastructure/mock/parking_mock_data.dart';
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
import 'package:parkwise/presentation/screens/reserve/reserve_view_model.dart';
import 'package:provider/provider.dart';

import 'support/test_app.dart';

void main() {
  setUpAll(() {
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

  AppDependencies withParkedCar() {
    final deps = AppDependencies.mock();
    (deps.vehicles as MockVehicleLocator)
      ..vehicle = ParkedVehicle(
        spotId: 'P2-B-24',
        spotCode: 'B-24',
        levelCode: 'P2',
        zone: 'B',
        parkedAt: DateTime(2026, 10, 2, 8, 14),
      )
      ..location = CarLocation(
        levelCode: 'P2',
        spotCode: 'B-24',
        savedAt: DateTime(2026, 10, 2, 8, 14),
        position: const GeoPoint(4.6025, -74.0655),
      );
    (deps.reservations as MockReservationRepository).current =
        ParkingMockData.reservation(createdAt: DateTime.now());
    return deps;
  }

  for (final size in sizes.entries) {
    testWidgets('Find my car with a parked car on ${size.key}', (tester) async {
      tester.view.physicalSize = size.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testApp(const FindMyCarScreen(), dependencies: withParkedCar()),
      );
      await tester.pumpAndSettle();

      expect(find.text('B-24'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Reserve with an active reservation on ${size.key}', (
      tester,
    ) async {
      tester.view.physicalSize = size.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final deps = withParkedCar();
      await tester.pumpWidget(
        testApp(const ReserveScreen(), dependencies: deps),
      );
      await tester.runAsync(
        () => tester
            .element(find.byType(ReserveScreen))
            .read<ReserveViewModel>()
            .load(),
      );
      await tester.pump();

      expect(find.text('I parked'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('app with a saved session opens on Home', (tester) async {
    await tester.pumpWidget(ParkWiseApp(dependencies: AppDependencies.mock()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Log in'), findsNothing);
  });
}
