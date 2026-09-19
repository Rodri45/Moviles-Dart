import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/core/design/app_theme.dart';
import 'package:parkwise/presentation/screens/find_spot/find_spot_screen.dart';
import 'package:parkwise/presentation/screens/reserve/reserve_screen.dart';

// prueba que cada pantalla se vea en un celular normal y en uno chiquito
// sin que nada se salga de la pantalla. cuando hagan su pantalla la agregan
// a la lista de abajo
void main() {
  setUpAll(() {
    // en los tests no hay internet asi que no intenta bajar las fuentes
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const screens = <String, Widget>{
    'Find a spot': FindSpotScreen(),
    'Reserve': ReserveScreen(),
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
