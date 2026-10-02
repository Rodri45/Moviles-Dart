import '../../domain/entities/parked_vehicle.dart';
import '../../domain/ports/vehicle_locator.dart';

// version de mentira, el carro esta donde se le diga
class MockVehicleLocator implements VehicleLocator {
  MockVehicleLocator({this.vehicle});

  ParkedVehicle? vehicle;

  @override
  Future<ParkedVehicle?> getParkedVehicle() async => vehicle;
}
