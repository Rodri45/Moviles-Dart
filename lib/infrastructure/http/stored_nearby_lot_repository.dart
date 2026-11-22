import '../../domain/entities/nearby_lot.dart';
import '../../domain/entities/saved.dart';
import '../../domain/ports/nearby_lot_repository.dart';
import '../../domain/ports/nearby_lot_store.dart';
import '../../domain/ports/parking_repository.dart';
import 'api_client.dart';

class StoredNearbyLotRepository implements NearbyLotRepository {
  StoredNearbyLotRepository(
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
  Future<Saved<List<NearbyLot>>> lots({bool refresh = false}) async {
    final saved = await _store.read();
    if (!refresh && saved != null && _isFresh(saved.savedAt)) return saved;
    try {
      final lots = await _parking.getNearbyLots();
      final now = _clock();
      await _store.save(lots, now);
      return Saved(lots, savedAt: now);
    } catch (e) {
      if (saved == null || !ApiClient.isNetworkFailure(e)) rethrow;
      return Saved(saved.data, savedAt: saved.savedAt, fromStorage: true);
    }
  }

  bool _isFresh(DateTime savedAt) => _clock().difference(savedAt) < maxAge;
}
