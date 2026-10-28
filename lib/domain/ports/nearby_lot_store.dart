import '../entities/cached.dart';
import '../entities/nearby_lot.dart';

abstract interface class NearbyLotStore {
  Future<Cached<List<NearbyLot>>?> read();

  Future<void> save(List<NearbyLot> lots, DateTime savedAt);
}
