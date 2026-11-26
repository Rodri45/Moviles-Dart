import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_report.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/http/outbox_report_repository.dart';
import 'package:parkwise/infrastructure/mock/memory_pending_report_store.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_report_repository.dart';

class _SlowServer extends MockReportRepository {
  final List<String> started = [];
  final Map<String, Completer<void>> gates = {};

  @override
  Future<SpotReport> send(SpotReport report, {Uint8List? photo}) async {
    started.add(report.clientId);
    await gates[report.clientId]?.future;
    return super.send(report, photo: photo);
  }
}

SpotReport report(String clientId) => SpotReport(
  clientId: clientId,
  spotId: 'P2-A-1${clientId.length}',
  levelCode: 'P2',
  kind: ReportKind.occupied,
  shownStatus: SpotStatus.free,
  reportedAt: DateTime(2026, 11, 24, 8),
);

void main() {
  final photo = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
  late _SlowServer server;
  late MemoryPendingReportStore store;
  late MockConnectivity connectivity;
  late OutboxReportRepository outbox;
  late List<SpotReport> updates;

  setUp(() {
    server = _SlowServer();
    store = MemoryPendingReportStore();
    connectivity = MockConnectivity();
    outbox = OutboxReportRepository(server, store, connectivity);
    updates = [];
    outbox.updates.listen(updates.add);
  });

  tearDown(() => outbox.dispose());

  test('with signal the report goes straight to ParkWise', () async {
    final sent = await outbox.send(report('a'), photo: photo);

    expect(sent.state, ReportState.sent);
    expect(server.photos.values.single, photo);
    expect(await outbox.pending(), isEmpty);
  });

  test('without signal the report and its photo wait on the phone', () async {
    server.failure = const NetworkException('offline');

    final saved = await outbox.send(report('a'), photo: photo);
    await pumpEventQueue();

    expect(saved.state, ReportState.waiting);
    expect((await outbox.pending()).single.clientId, 'a');
    expect(store.photos['a'], photo);
    expect(updates.first.state, ReportState.waiting);
  });

  test('they are sent one at a time when the signal returns', () async {
    server.failure = const NetworkException('offline');
    await outbox.send(report('a'), photo: photo);
    await outbox.send(report('bb'));
    await pumpEventQueue();
    server
      ..failure = null
      ..gates['a'] = Completer<void>();

    connectivity.setOnline(true);
    await pumpEventQueue();
    expect(server.started.where((id) => id == 'bb'), isEmpty);
    expect((await outbox.pending()).first.state, ReportState.sending);

    server.gates['a']!.complete();
    await outbox.flush();

    expect(server.reports.map((item) => item.clientId), ['bb', 'a']);
    expect(server.photos.values.single, photo);
    expect(await outbox.pending(), isEmpty);
    expect(store.photos, isEmpty);
    expect(
      updates.where((item) => item.state == ReportState.sent),
      hasLength(2),
    );
  });

  test('a new report waits behind the ones already queued', () async {
    server.failure = const NetworkException('offline');
    await outbox.send(report('a'));
    await pumpEventQueue();
    server.failure = null;
    server.gates['a'] = Completer<void>();

    final second = await outbox.send(report('bb'));

    expect(second.state, ReportState.waiting);
    server.gates['a']!.complete();
    await outbox.flush();
    expect(server.reports.map((item) => item.clientId), ['bb', 'a']);
  });

  test('a report the server refuses leaves the queue as rejected', () async {
    server.failure = const NetworkException('offline');
    await outbox.send(report('a'));
    await pumpEventQueue();
    server.failure = const ApiException(404, 'Parking spot not found');

    await outbox.flush();

    expect(await outbox.pending(), isEmpty);
    expect(updates.last.state, ReportState.rejected);
    expect(updates.last.clientId, 'a');
  });

  test('a refused report is shown right away when there is signal', () async {
    server.failure = const ApiException(413, 'Photo is larger than 300 KB');

    await expectLater(
      outbox.send(report('a'), photo: photo),
      throwsA(isA<ApiException>()),
    );
    expect(await outbox.pending(), isEmpty);
  });

  test('signing out clears the queue', () async {
    server.failure = const NetworkException('offline');
    await outbox.send(report('a'), photo: photo);
    await pumpEventQueue();

    await outbox.clear();

    expect(await outbox.pending(), isEmpty);
    expect(store.photos, isEmpty);
  });
}
