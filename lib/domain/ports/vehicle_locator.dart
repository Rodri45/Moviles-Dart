import '../entities/parked_vehicle.dart';

// interfaz para guardar y consultar donde quedo el carro
abstract interface class VehicleLocator {
  Future<ParkedVehicle?> getParkedVehicle();

  Future<void> saveParkedVehicle(ParkedVehicle vehicle);

  Future<void> clear();
}
