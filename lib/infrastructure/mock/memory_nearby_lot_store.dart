import '../../domain/entities/cached.dart';
import '../../domain/entities/nearby_lot.dart';
import '../../domain/ports/nearby_lot_store.dart';

class MemoryNearbyLotStore implements NearbyLotStore {
  Cached<List<NearbyLot>>? saved;

  @override
  Future<Cached<List<NearbyLot>>?> read() async => saved;

  @override
  Future<void> save(List<NearbyLot> lots, DateTime savedAt) async =>
      saved = Cached(List.of(lots), savedAt: savedAt);
}
