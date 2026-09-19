import '../entities/forecast.dart';
import '../entities/parking_lot.dart';

// interfaz para pedir los parqueaderos. por ahora la implementa el mock,
// despues cuando haya backend se hace otra que llame a la api
abstract interface class ParkingRepository {
  Future<List<ParkingLot>> getLots();

  Future<ParkingLot?> getLot(String lotId);

  Future<Forecast> getForecast(String lotId);
}
