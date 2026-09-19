import '../entities/forecast.dart';
import '../entities/parking_lot.dart';

/// Puerto de salida: cómo el dominio obtiene datos de parqueaderos.
///
/// La presentación solo conoce esta interfaz. Hoy la implementa
/// `MockParkingRepository`; más adelante puede implementarla un adaptador
/// HTTP sin tocar las pantallas.
abstract interface class ParkingRepository {
  Future<List<ParkingLot>> getLots();

  Future<ParkingLot?> getLot(String lotId);

  Future<Forecast> getForecast(String lotId);
}
