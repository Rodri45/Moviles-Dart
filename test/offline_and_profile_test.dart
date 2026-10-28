import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/app/dependencies.dart';
import 'package:parkwise/domain/ports/reservation_outbox.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_outbox.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_repository.dart';
import 'package:parkwise/presentation/screens/login/auth_view_model.dart';
import 'package:parkwise/presentation/screens/offline/offline_screen.dart';
import 'package:parkwise/presentation/screens/profile/profile_screen.dart';
import 'package:parkwise/presentation/screens/profile/profile_view_model.dart';
import 'package:provider/provider.dart';

import 'support/test_app.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('profile counts the actions waiting in the queue', () async {
    final outbox = MockReservationOutbox()..pending = 2;
    final profile = ProfileViewModel(MockReservationRepository(), outbox);
    addTearDown(profile.dispose);

    await profile.load();
    expect(profile.pendingActions, 2);
    expect(profile.historySavedAt, isNotNull);

    outbox.emit(OutboxStatus.idle);
    await Future<void>.delayed(Duration.zero);
    expect(profile.pendingActions, 0);
  });

  testWidgets('log out asks first when actions are waiting', (tester) async {
    final deps = AppDependencies.mock();
    (deps.outbox as MockReservationOutbox).pending = 1;
    await tester.pumpWidget(testApp(const ProfileScreen(), dependencies: deps));
    final context = tester.element(find.byType(ProfileScreen));
    final auth = context.read<AuthViewModel>();
    await tester.runAsync(() async {
      await auth.restoreSession();
      await context.read<ProfileViewModel>().load();
    });
    await tester.pumpAndSettle();
    final logOut = find.byIcon(Icons.logout);

    await tester.ensureVisible(logOut);
    await tester.tap(logOut);
    await tester.pumpAndSettle();
    expect(find.text('Log out now?'), findsOneWidget);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(auth.status, AuthStatus.authenticated);

    await tester.tap(logOut);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(auth.status, AuthStatus.unauthenticated);
  });

  testWidgets('the offline view closes when the signal returns', (
    tester,
  ) async {
    final deps = AppDependencies.mock();
    final connectivity = deps.connectivity as MockConnectivity;
    connectivity.online = false;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(OfflineScreen.routeName),
              child: const Text('Open offline view'),
            ),
          ),
        ),
        dependencies: deps,
      ),
    );
    await tester.tap(find.text('Open offline view'));
    await tester.pumpAndSettle();
    expect(find.byType(OfflineScreen), findsOneWidget);
    expect(find.text('Retry connection'), findsOneWidget);

    connectivity.setOnline(true);
    await tester.pumpAndSettle();

    expect(find.byType(OfflineScreen), findsNothing);
    expect(find.text('Back online. Data updated.'), findsOneWidget);
  });
}
