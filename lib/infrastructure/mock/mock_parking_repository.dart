import '../../domain/entities/forecast.dart';
import '../../domain/entities/parking_lot.dart';
import '../../domain/ports/parking_repository.dart';
import 'parking_mock_data.dart';

/// Adaptador mock de [ParkingRepository]. Devuelve [ParkingMockData].
class MockParkingRepository implements ParkingRepository {
  const MockParkingRepository();

  @override
  Future<List<ParkingLot>> getLots() async => ParkingMockData.lots;

  @override
  Future<ParkingLot?> getLot(String lotId) async {
    for (final lot in ParkingMockData.lots) {
      if (lot.id == lotId) return lot;
    }
    return null;
  }

  @override
  Future<Forecast> getForecast(String lotId) async =>
      ParkingMockData.forecastP1;
}
