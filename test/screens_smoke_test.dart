import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/core/design/app_theme.dart';
import 'package:parkwise/presentation/screens/find_my_car/find_my_car_screen.dart';
import 'package:parkwise/presentation/screens/find_spot/find_spot_screen.dart';
import 'package:parkwise/presentation/screens/home/home_screen.dart';
import 'package:parkwise/presentation/screens/lot_detail/lot_detail_screen.dart';
import 'package:parkwise/presentation/screens/no_spots/no_spots_screen.dart';
import 'package:parkwise/presentation/screens/offline/offline_screen.dart';
import 'package:parkwise/presentation/screens/reserve/reserve_screen.dart';


void main() {
  setUpAll(() {
    // Sin red en tests: usar la fuente de fallback en vez de descargar.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const screens = <String, Widget>{
    'Home': HomeScreen(),
    'P1 North': LotDetailScreen(),
    'Find a spot': FindSpotScreen(),
    'Reserve': ReserveScreen(),
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

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: screen.value),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Find a spot shows its content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FindSpotScreen()),
    );
    expect(find.text('Find a spot'), findsOneWidget);
    expect(find.text('6 spots found'), findsOneWidget);
    expect(find.text('A103'), findsOneWidget);
  });

  testWidgets('Reserve shows its content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReserveScreen()),
    );
    expect(find.text('Reserve spot'), findsOneWidget);
    expect(find.text('B201'), findsOneWidget);
    expect(find.text('Confirm reservation'), findsOneWidget);
    expect(find.text('Compliance history'), findsOneWidget);
  });
}
