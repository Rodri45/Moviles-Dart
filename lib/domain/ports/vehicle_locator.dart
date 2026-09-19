import '../entities/parked_vehicle.dart';

/// Puerto de salida para saber dónde quedó el carro del usuario.
abstract interface class VehicleLocator {
  Future<ParkedVehicle?> getParkedVehicle();

  Future<void> saveParkedVehicle(ParkedVehicle vehicle);

  Future<void> clear();
}
