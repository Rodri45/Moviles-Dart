import '../../domain/entities/nearby_lot.dart';
import '../../domain/entities/saved.dart';
import '../../domain/ports/nearby_lot_store.dart';

class MemoryNearbyLotStore implements NearbyLotStore {
  Saved<List<NearbyLot>>? saved;

  @override
  Future<Saved<List<NearbyLot>>?> read() async => saved;

  @override
  Future<void> save(List<NearbyLot> lots, DateTime savedAt) async =>
      saved = Saved(List.of(lots), savedAt: savedAt);
}
