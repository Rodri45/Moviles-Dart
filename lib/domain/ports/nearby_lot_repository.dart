import '../entities/nearby_lot.dart';
import '../entities/saved.dart';

abstract interface class NearbyLotRepository {
  Future<Saved<List<NearbyLot>>> lots({bool refresh = false});
}
