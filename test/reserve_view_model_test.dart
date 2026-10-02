import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/geo_point.dart';
import 'package:parkwise/domain/entities/reservation.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_location_provider.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_vehicle_locator.dart';
import 'package:parkwise/infrastructure/mock/parking_mock_data.dart';
import 'package:parkwise/presentation/screens/reserve/reserve_view_model.dart';

void main() {
  late DateTime now;
  late MockReservationRepository repository;
  late MockLocationProvider location;
  late MockVehicleLocator vehicles;
  late ReserveViewModel reserve;
  final spot = ParkingMockData.spots['P1']!.first;

  setUp(() {
    now = DateTime.utc(2026, 10, 2, 13);
    repository = MockReservationRepository(clock: () => now);
    location = MockLocationProvider();
    vehicles = MockVehicleLocator();
    reserve = ReserveViewModel(
      repository,
      vehicles,
      location,
      MockConnectivity(),
      clock: () => now,
    );
  });

  tearDown(() => reserve.dispose());

  test('201: the reservation becomes active', () async {
    reserve.selectSpot(spot);
    await reserve.confirm();

    expect(reserve.isActive, isTrue);
    expect(reserve.reservation!.spotId, spot.id);
    expect(reserve.pendingSpot, isNull);
    expect(reserve.errorMessage, isNull);
  });

  test('409 spot not available asks to choose another spot', () async {
    repository.createError = const ApiException(
      409,
      'Parking spot is not available',
    );
    reserve.selectSpot(spot);
    await reserve.confirm();

    expect(reserve.reservation, isNull);
    expect(reserve.errorMessage, 'Spot taken, choose another.');
    expect(reserve.pendingSpot, isNull);
  });

  test('409 active reservation says the user already has one', () async {
    repository.createError = const ApiException(
      409,
      'An active reservation already exists',
    );
    reserve.selectSpot(spot);
    await reserve.confirm();

    expect(reserve.errorMessage, 'You already have a reservation.');
  });

  test('the countdown follows expiresAt from the server', () async {
    // la reserva se creo hace 5 minutos en el servidor
    repository.current = ParkingMockData.reservation(
      createdAt: now.subtract(const Duration(minutes: 5)),
    );
    await reserve.load();
    expect(reserve.remaining, const Duration(minutes: 10));

    now = now.add(const Duration(minutes: 4, seconds: 30));
    expect(reserve.remaining, const Duration(minutes: 5, seconds: 30));

    now = now.add(const Duration(minutes: 20));
    expect(reserve.remaining, Duration.zero);
  });

  test('check-in saves where the car is parked', () async {
    location.position = const GeoPoint(4.6020, -74.0650);
    reserve.selectSpot(spot);
    await reserve.confirm();
    await reserve.checkIn();

    expect(reserve.reservation!.status, ReservationStatus.fulfilled);
    expect(vehicles.location!.spotCode, spot.code);
    expect(vehicles.location!.position!.latitude, 4.6020);

    await reserve.release();
    expect(reserve.reservation, isNull);
    expect(vehicles.location, isNull);
  });

  test('warns once when it is about to expire and the user is far', () async {
    location.position = const GeoPoint(4.70, -74.05);
    repository.current = ParkingMockData.reservation(
      createdAt: now.subtract(const Duration(minutes: 12, seconds: 59)),
    );
    await reserve.load();

    // el timer de la vista corre cada segundo
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await Future<void>.delayed(Duration.zero);
    expect(reserve.expiryAlert, isTrue);

    reserve.dismissExpiryAlert();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(reserve.expiryAlert, isFalse);
  });

  test('does not warn when the user is already on campus', () async {
    repository.current = ParkingMockData.reservation(
      createdAt: now.subtract(const Duration(minutes: 13)),
    );
    await reserve.load();

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(reserve.expiryAlert, isFalse);
  });
}
