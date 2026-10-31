import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_location_provider.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_outbox.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_telemetry.dart';
import 'package:parkwise/infrastructure/mock/mock_vehicle_locator.dart';
import 'package:parkwise/infrastructure/mock/parking_mock_data.dart';
import 'package:parkwise/presentation/screens/reserve/reserve_view_model.dart';

void main() {
  late MockReservationRepository repository;
  late MockConnectivity connectivity;
  late MockTelemetry telemetry;
  late MockReservationOutbox outbox;
  late ReserveViewModel reserve;
  final spot = ParkingMockData.spots['P1']!.firstWhere((s) => s.isFree);

  setUp(() {
    repository = MockReservationRepository();
    connectivity = MockConnectivity();
    telemetry = MockTelemetry();
    outbox = MockReservationOutbox();
    reserve = ReserveViewModel(
      repository,
      MockVehicleLocator(),
      MockLocationProvider(),
      connectivity,
      telemetry: telemetry,
      outbox: outbox,
    );
  });

  tearDown(() => reserve.dispose());

  group('BQ7 funnel events', () {
    test('selecting and confirming a spot sends both steps', () async {
      reserve.selectSpot(spot);
      await reserve.confirm();

      final selected = telemetry.named('spot_selected').single;
      expect(selected['spotCode'], spot.code);
      expect(selected['levelCode'], spot.levelCode);
      expect(telemetry.named('reserve_confirm_tapped'), hasLength(1));
      expect(telemetry.named('reserve_failed'), isEmpty);
    });

    test('a spot taken by someone else is reported with its reason', () async {
      repository.createError = const ApiException(
        409,
        'Parking spot is not available',
      );
      reserve.selectSpot(spot);
      await reserve.confirm();

      expect(telemetry.named('reserve_failed').single['reason'], 'spot_taken');
    });

    test('a network failure is reported as offline', () async {
      repository.createError = const NetworkException('timeout');
      reserve.selectSpot(spot);
      await reserve.confirm();

      expect(telemetry.named('reserve_failed').single['reason'], 'offline');
    });
  });
}
