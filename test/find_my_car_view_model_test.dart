import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/car_location.dart';
import 'package:parkwise/domain/entities/geo_point.dart';
import 'package:parkwise/domain/entities/parked_vehicle.dart';
import 'package:parkwise/domain/ports/reservation_outbox.dart';
import 'package:parkwise/infrastructure/mock/mock_location_provider.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_outbox.dart';
import 'package:parkwise/infrastructure/mock/mock_vehicle_locator.dart';
import 'package:parkwise/presentation/screens/find_my_car/find_my_car_view_model.dart';

void main() {
  final parkedAt = DateTime(2026, 10, 28, 8, 14);
  late MockVehicleLocator vehicles;
  late MockReservationOutbox outbox;
  late FindMyCarViewModel car;

  setUp(() {
    vehicles = MockVehicleLocator(
      location: CarLocation(
        levelCode: 'P3',
        spotCode: 'C-07',
        savedAt: parkedAt,
        position: const GeoPoint(4.6025, -74.0655),
      ),
    );
    outbox = MockReservationOutbox();
    car = FindMyCarViewModel(vehicles, MockLocationProvider(), outbox);
  });

  tearDown(() => car.dispose());

  test('a check-in waiting in the queue already counts as parked', () async {
    outbox.pending = 1;

    await car.load();

    expect(car.hasCar, isTrue);
    expect(car.spotCode, 'C-07');
    expect(car.pendingActions, 1);
    expect(vehicles.location, isNotNull);
  });

  test('with an empty queue and no car on the server it is cleared', () async {
    await car.load();

    expect(car.hasCar, isFalse);
    expect(vehicles.location, isNull);
  });

  test('when the queue is sent the server is asked again', () async {
    outbox.pending = 1;
    await car.load();
    vehicles.vehicle = ParkedVehicle(
      spotId: 'P3-C-07',
      spotCode: 'C-07',
      levelCode: 'P3',
      zone: 'C',
      parkedAt: parkedAt,
    );

    outbox.emit(OutboxStatus.idle);
    await Future<void>.delayed(Duration.zero);

    expect(car.pendingActions, 0);
    expect(car.vehicle?.zone, 'C');
    expect(car.hasCar, isTrue);
  });
}
