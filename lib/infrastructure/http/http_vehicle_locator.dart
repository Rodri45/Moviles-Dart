import '../../domain/entities/car_location.dart';
import '../../domain/entities/parked_vehicle.dart';
import '../../domain/ports/vehicle_locator.dart';
import '../storage/local_cache.dart';
import 'api_client.dart';

// GET /vehicle para el puesto y hive para la posicion gps del carro
class HttpVehicleLocator implements VehicleLocator {
  HttpVehicleLocator(this._client, this._cache);

  static const _key = 'car_location';

  final ApiClient _client;
  final LocalCache _cache;

  @override
  Future<ParkedVehicle?> getParkedVehicle() async {
    final json = await _client.get('/vehicle');
    return json == null
        ? null
        : ParkedVehicle.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<CarLocation?> savedLocation() async {
    final data = _cache.read(_key)?.data;
    return data == null
        ? null
        : CarLocation.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> saveLocation(CarLocation location) =>
      _cache.write(_key, location.toJson());

  @override
  Future<void> clearLocation() => _cache.delete(_key);
}
