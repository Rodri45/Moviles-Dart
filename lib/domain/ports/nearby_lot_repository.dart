import '../entities/cached.dart';
import '../entities/nearby_lot.dart';

abstract interface class NearbyLotRepository {
  Future<Cached<List<NearbyLot>>> lots({bool refresh = false});
}
