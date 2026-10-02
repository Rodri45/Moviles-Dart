import '../entities/car_location.dart';
import '../entities/parked_vehicle.dart';

// interfaz para saber donde quedo el carro
abstract interface class VehicleLocator {
  // nivel y puesto segun el backend, o null si no hay carro parqueado
  Future<ParkedVehicle?> getParkedVehicle();

  // la posicion gps que se guardo en el celular al hacer check-in
  Future<CarLocation?> savedLocation();

  Future<void> saveLocation(CarLocation location);

  Future<void> clearLocation();
}
