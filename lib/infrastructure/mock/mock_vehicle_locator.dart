import '../../domain/entities/car_location.dart';
import '../../domain/entities/parked_vehicle.dart';
import '../../domain/ports/vehicle_locator.dart';

class MockVehicleLocator implements VehicleLocator {
  MockVehicleLocator({this.vehicle, this.location});

  ParkedVehicle? vehicle;
  CarLocation? location;

  @override
  Future<ParkedVehicle?> getParkedVehicle() async => vehicle;

  @override
  Future<CarLocation?> savedLocation() async => location;

  @override
  Future<void> saveLocation(CarLocation value) async => location = value;

  @override
  Future<void> clearLocation() async => location = null;
}
