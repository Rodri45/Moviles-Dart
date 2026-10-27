import '../../domain/entities/car_location.dart';
import '../../domain/entities/parked_vehicle.dart';
import '../../domain/ports/vehicle_locator.dart';
import '../storage/car_location_file_store.dart';
import 'api_client.dart';

class HttpVehicleLocator implements VehicleLocator {
  HttpVehicleLocator(this._client, this._fileStore);

  final ApiClient _client;
  final CarLocationFileStore _fileStore;

  @override
  Future<ParkedVehicle?> getParkedVehicle() async {
    final json = await _client.get('/vehicle');
    return json == null
        ? null
        : ParkedVehicle.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<CarLocation?> savedLocation() async {
    final data = await _fileStore.read();
    return data == null
        ? null
        : CarLocation.fromJson(data);
  }

  @override
  Future<void> saveLocation(CarLocation location) =>
      _fileStore.write(location.toJson());

  @override
  Future<void> clearLocation() => _fileStore.clear();
}
