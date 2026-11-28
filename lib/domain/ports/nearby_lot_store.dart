import '../entities/nearby_lot.dart';
import '../entities/saved.dart';

abstract interface class NearbyLotStore {
  Future<Saved<List<NearbyLot>>?> read();

  Future<void> save(List<NearbyLot> lots, DateTime savedAt);
}
