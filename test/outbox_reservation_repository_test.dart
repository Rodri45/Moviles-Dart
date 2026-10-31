import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/pending_action.dart';
import 'package:parkwise/domain/entities/reservation.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/domain/ports/reservation_outbox.dart';
import 'package:parkwise/infrastructure/http/outbox_reservation_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_reservation_repository.dart';
import 'package:parkwise/infrastructure/mock/parking_mock_data.dart';

import 'support/memory_pending_action_store.dart';

class _FlakyServer extends MockReservationRepository {
  _FlakyServer({super.clock});

  bool offline = false;
  Object? checkInError;
  int checkIns = 0;
  int releases = 0;

  void _guard() {
    if (offline) throw const NetworkException('offline');
  }

  @override
  Future<Reservation> checkIn(String reservationId) async {
    _guard();
    final error = checkInError;
    if (error != null) throw error;
    checkIns++;
    return super.checkIn(reservationId);
  }

  @override
  Future<Reservation> release(String reservationId) async {
    _guard();
    releases++;
    return super.release(reservationId);
  }

  @override
  Future<Reservation?> active() async => current;
}

void main() {
  late DateTime now;
  late _FlakyServer server;
  late MemoryPendingActionStore store;
  late MockConnectivity connectivity;
  late OutboxReservationRepository repository;
  late List<Reservation> remembered;

  setUp(() {
    now = DateTime.utc(2026, 10, 26, 13);
    server = _FlakyServer(clock: () => now);
    store = MemoryPendingActionStore();
    connectivity = MockConnectivity();
    remembered = [];
    repository = OutboxReservationRepository(
      server,
      store,
      connectivity,
      remember: (reservation) async => remembered.add(reservation),
      clock: () => now,
    );
    server.current = ParkingMockData.reservation(createdAt: now);
  });

  tearDown(() => repository.dispose());

  test('online, "I parked" goes straight to the server', () async {
    final parked = await repository.checkIn(server.current!.id);

    expect(parked.status, ReservationStatus.fulfilled);
    expect(server.checkIns, 1);
    expect(store.actions, isEmpty);
    expect(remembered, isEmpty);
  });

  test('offline, "I parked" is queued and shown at once', () async {
    final id = server.current!.id;
    server.offline = true;

    final parked = await repository.checkIn(id);

    expect(parked.status, ReservationStatus.fulfilled);
    expect(parked.checkedInAt, now);
    expect(store.actions.single.type, PendingActionType.checkIn);
    expect(store.actions.single.reservationId, id);
    expect(remembered.last.status, ReservationStatus.fulfilled);
    expect(await repository.pendingCount(), 1);
  });

  test('the queue is sent in order when the connection returns', () async {
    final id = server.current!.id;
    server.offline = true;
    await repository.checkIn(id);
    await repository.release(id);
    expect(store.actions.map((a) => a.type), [
      PendingActionType.checkIn,
      PendingActionType.release,
    ]);

    server.offline = false;
    final statuses = <OutboxStatus>[];
    final sub = repository.status.listen(statuses.add);
    connectivity.setOnline(true);
    await Future<void>.delayed(Duration.zero);
    await repository.flush();
    await sub.cancel();

    expect(server.checkIns, 1);
    expect(server.releases, 1);
    expect(store.actions, isEmpty);
    expect(statuses.last.pending, 0);
    expect(server.current, isNull);
    expect(server.past.single.status, ReservationStatus.released);
  });

  test('a refused action leaves the queue with a message', () async {
    final id = server.current!.id;
    server.offline = true;
    await repository.checkIn(id);

    server
      ..offline = false
      ..checkInError = const ApiException(409, 'Reservation has expired');
    final status = await repository.flush();

    expect(status.pending, 0);
    expect(status.rejected.single, contains('after the hold expired'));
  });

  test('a flush while offline keeps the action in the queue', () async {
    final id = server.current!.id;
    server.offline = true;
    await repository.checkIn(id);

    final status = await repository.flush();

    expect(status.pending, 1);
    expect(store.actions.single.reservationId, id);
  });

  test('two flushes at the same time share one run', () async {
    final id = server.current!.id;
    server.offline = true;
    await repository.checkIn(id);
    server.offline = false;

    await Future.wait([repository.flush(), repository.flush()]);

    expect(server.checkIns, 1);
  });

  test('a reservation is never created offline', () async {
    server
      ..current = null
      ..createError = const NetworkException('offline');

    await expectLater(
      repository.create('P1-A-02'),
      throwsA(isA<NetworkException>()),
    );
    expect(store.actions, isEmpty);
  });
}
