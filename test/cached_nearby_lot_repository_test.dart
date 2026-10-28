import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/nearby_lot.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/http/cached_nearby_lot_repository.dart';
import 'package:parkwise/infrastructure/mock/memory_nearby_lot_store.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';

class _Server extends MockParkingRepository {
  bool offline = false;
  int calls = 0;

  @override
  Future<List<NearbyLot>> getNearbyLots() async {
    calls++;
    if (offline) throw const NetworkException('offline');
    return super.getNearbyLots();
  }
}

void main() {
  late DateTime now;
  late _Server server;
  late MemoryNearbyLotStore store;
  late CachedNearbyLotRepository lots;

  setUp(() {
    now = DateTime.utc(2026, 10, 28, 9);
    server = _Server();
    store = MemoryNearbyLotStore();
    lots = CachedNearbyLotRepository(server, store, clock: () => now);
  });

  test('the first time the lots come from the server and are saved', () async {
    final result = await lots.lots();

    expect(server.calls, 1);
    expect(result.fromCache, isFalse);
    expect(store.saved!.data.map((lot) => lot.id), ['nearby-1', 'nearby-2']);
  });

  test('a copy younger than a day is used without the server', () async {
    await lots.lots();
    now = now.add(const Duration(hours: 23));

    final result = await lots.lots();

    expect(server.calls, 1);
    expect(result.savedAt, DateTime.utc(2026, 10, 28, 9));
  });

  test('after a day the server is asked again', () async {
    await lots.lots();
    now = now.add(const Duration(hours: 25));

    await lots.lots();

    expect(server.calls, 2);
  });

  test('pull to refresh asks the server even with a fresh copy', () async {
    await lots.lots();

    await lots.lots(refresh: true);

    expect(server.calls, 2);
  });

  test('without signal an old copy is shown and marked as saved', () async {
    await lots.lots();
    now = now.add(const Duration(days: 3));
    server.offline = true;

    final result = await lots.lots();

    expect(result.fromCache, isTrue);
    expect(result.data, hasLength(2));
  });

  test('without signal and without a copy the error is shown', () async {
    server.offline = true;

    await expectLater(lots.lots(), throwsA(isA<NetworkException>()));
  });
}
