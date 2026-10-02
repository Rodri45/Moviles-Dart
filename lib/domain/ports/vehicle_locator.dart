import '../entities/car_location.dart';
import '../entities/parked_vehicle.dart';

abstract interface class VehicleLocator {
  Future<ParkedVehicle?> getParkedVehicle();

  Future<CarLocation?> savedLocation();

  Future<void> saveLocation(CarLocation location);

  Future<void> clearLocation();
}
