import '../../domain/entities/cached.dart';
import '../../domain/entities/nearby_lot.dart';
import '../../domain/ports/nearby_lot_repository.dart';
import '../../domain/ports/nearby_lot_store.dart';
import '../../domain/ports/parking_repository.dart';
import 'api_client.dart';

class CachedNearbyLotRepository implements NearbyLotRepository {
  CachedNearbyLotRepository(
    this._parking,
    this._store, {
    this.maxAge = const Duration(hours: 24),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ParkingRepository _parking;
  final NearbyLotStore _store;
  final Duration maxAge;
  final DateTime Function() _clock;

  @override
  Future<Cached<List<NearbyLot>>> lots({bool refresh = false}) async {
    final saved = await _store.read();
    if (!refresh && saved != null && _isFresh(saved.savedAt)) return saved;
    try {
      final lots = await _parking.getNearbyLots();
      final now = _clock();
      await _store.save(lots, now);
      return Cached(lots, savedAt: now);
    } catch (e) {
      if (saved == null || !ApiClient.isNetworkFailure(e)) rethrow;
      return Cached(saved.data, savedAt: saved.savedAt, fromCache: true);
    }
  }

  bool _isFresh(DateTime savedAt) => _clock().difference(savedAt) < maxAge;
}
