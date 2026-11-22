import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/reservation.dart';
import 'package:parkwise/domain/entities/saved.dart';
import 'package:parkwise/infrastructure/http/history_memory_cache.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_repository.dart';

class _CountingReservations extends MockReservationRepository {
  int historyCalls = 0;
  bool offline = false;

  @override
  Future<Saved<List<Reservation>>> history() async {
    historyCalls++;
    final result = await super.history();
    return Saved(result.data, savedAt: result.savedAt, fromStorage: offline);
  }
}

void main() {
  late _CountingReservations inner;
  late String? user;
  late HistoryMemoryCache history;

  setUp(() {
    inner = _CountingReservations();
    user = 'user-1';
    history = HistoryMemoryCache(inner, () => user);
  });

  test('a second read inside the time to live does not go to the network',
      () async {
    await history.history();
    await history.history();

    expect(inner.historyCalls, 1);
  });

  test('each user has its own entry', () async {
    await history.history();
    user = 'user-2';
    await history.history();

    expect(inner.historyCalls, 2);
  });

  test('a new reservation or a change forgets the saved history', () async {
    await history.history();
    final reservation = await history.create('spot-1');
    await history.history();
    await history.release(reservation.id);
    final after = await history.history();

    expect(inner.historyCalls, 3);
    expect(after.data.first.id, reservation.id);
  });

  test('the copy saved on the phone is never kept in memory', () async {
    inner.offline = true;
    await history.history();
    inner.offline = false;
    await history.history();

    expect(inner.historyCalls, 2);
  });
}
