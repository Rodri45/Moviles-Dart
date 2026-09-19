import '../../domain/entities/parked_vehicle.dart';
import '../../domain/ports/vehicle_locator.dart';
import 'parking_mock_data.dart';

/// Adaptador mock de [VehicleLocator]. Guarda el carro en memoria.
class MockVehicleLocator implements VehicleLocator {
  ParkedVehicle? _vehicle = ParkingMockData.parkedVehicle;

  @override
  Future<ParkedVehicle?> getParkedVehicle() async => _vehicle;

  @override
  Future<void> saveParkedVehicle(ParkedVehicle vehicle) async {
    _vehicle = vehicle;
  }

  @override
  Future<void> clear() async {
    _vehicle = null;
  }
}
