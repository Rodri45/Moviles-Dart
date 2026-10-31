import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/ports/reservation_outbox.dart';
import 'package:parkwise/infrastructure/mock/mock_auth_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_location_provider.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_outbox.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_telemetry.dart';
import 'package:parkwise/infrastructure/mock/mock_vehicle_locator.dart';
import 'package:parkwise/infrastructure/mock/parking_mock_data.dart';
import 'package:parkwise/presentation/screens/login/auth_view_model.dart';
import 'package:parkwise/presentation/screens/reserve/reserve_view_model.dart';

void main() {
  late MockReservationRepository repository;
  late MockConnectivity connectivity;
  late MockReservationOutbox outbox;
  late ReserveViewModel reserve;
  final spot = ParkingMockData.spots['P1']!.firstWhere((s) => s.isFree);

  setUp(() {
    repository = MockReservationRepository();
    connectivity = MockConnectivity();
    outbox = MockReservationOutbox();
    reserve = ReserveViewModel(
      repository,
      MockVehicleLocator(),
      MockLocationProvider(),
      connectivity,
      outbox: outbox,
    );
  });

  tearDown(() => reserve.dispose());

  group('eventual connectivity', () {
    test('offline the spot stays selected and confirm is off', () async {
      connectivity.setOnline(false);
      await Future<void>.delayed(Duration.zero);
      reserve.selectSpot(spot);

      expect(reserve.canConfirm, isFalse);
      await reserve.confirm();

      expect(reserve.pendingSpot, spot);
      expect(reserve.reservation, isNull);
      expect(reserve.errorMessage, ReserveViewModel.offlineConfirmMessage);
    });

    test('actions saved on the phone are shown until they are sent', () async {
      outbox.emit(const OutboxStatus(pending: 2));
      await Future<void>.delayed(Duration.zero);
      expect(reserve.pendingActions, 2);

      outbox.emit(
        const OutboxStatus(
          pending: 0,
          rejected: ['"I parked" for spot B-03 reached the server late.'],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(reserve.pendingActions, 0);
      expect(reserve.errorMessage, contains('B-03'));
    });

    test('loading online sends the outbox first', () async {
      await reserve.load();

      expect(outbox.flushes, 1);
    });
  });

  test('signing out clears the actions saved for the old session', () async {
    var cleared = 0;
    final auth = AuthViewModel(
      MockAuthRepository(),
      MockTelemetry(),
      onSignedOut: () async => cleared++,
    );
    addTearDown(auth.dispose);

    await auth.logout();

    expect(cleared, 1);
  });
}
