import '../entities/parked_vehicle.dart';

// interfaz para saber donde quedo el carro
abstract interface class VehicleLocator {
  Future<ParkedVehicle?> getParkedVehicle();
}
