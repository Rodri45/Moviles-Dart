import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_report.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/http/outbox_report_repository.dart';
import 'package:parkwise/infrastructure/mock/memory_pending_report_store.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_report_repository.dart';
import 'package:parkwise/presentation/screens/report/my_reports_view_model.dart';

SpotReport report(String clientId, {int hour = 8}) => SpotReport(
  clientId: clientId,
  spotId: 'P1-A-0${clientId.length}',
  levelCode: 'P1',
  kind: ReportKind.occupied,
  shownStatus: SpotStatus.free,
  reportedAt: DateTime(2026, 11, 24, hour),
);

void main() {
  late MockReportRepository server;
  late MemoryPendingReportStore store;
  late MockConnectivity connectivity;
  late OutboxReportRepository outbox;
  late MyReportsViewModel reports;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 11, 24, 9);
    server = MockReportRepository();
    store = MemoryPendingReportStore();
    connectivity = MockConnectivity();
    outbox = OutboxReportRepository(server, store, connectivity);
    reports = MyReportsViewModel(
      outbox,
      outbox,
      connectivity,
      clock: () => now,
    );
  });

  tearDown(() {
    reports.dispose();
    outbox.dispose();
  });

  test('reports on the phone and on ParkWise are listed together', () async {
    await outbox.send(report('a', hour: 7));
    server.failure = const NetworkException('offline');
    await outbox.send(report('bb', hour: 9));
    await pumpEventQueue();

    await reports.load();

    expect(reports.reports.map((item) => item.clientId), ['bb', 'a']);
    expect(reports.reports.first.state, ReportState.waiting);
    expect(reports.reports.last.state, ReportState.sent);
    expect(reports.waiting, 1);
    expect(reports.errorMessage, isNull);
  });

  test('a waiting report turns into sent when the signal returns', () async {
    server.failure = const NetworkException('offline');
    await outbox.send(report('a'));
    await pumpEventQueue();
    await reports.load();
    expect(reports.reports.single.state, ReportState.waiting);

    server.failure = null;
    connectivity.setOnline(true);
    await outbox.flush();
    await pumpEventQueue();

    expect(reports.waiting, 0);
    expect(reports.reports.single.state, ReportState.sent);
  });

  test('a report ParkWise refuses is shown as not accepted', () async {
    server.failure = const NetworkException('offline');
    await outbox.send(report('a'));
    await pumpEventQueue();
    server.failure = const ApiException(404, 'Parking spot not found');

    await outbox.flush();
    await pumpEventQueue();

    expect(reports.rejected.single.clientId, 'a');
    expect(reports.reports.single.state, ReportState.rejected);
  });

  test('a server error is shown and signing out clears everything', () async {
    server.failure = const ApiException(500, 'boom');
    await reports.load();
    expect(reports.errorMessage, 'The server had a problem. Try again.');

    server.failure = const NetworkException('offline');
    await outbox.send(report('a'));
    await pumpEventQueue();
    reports.reset();
    await pumpEventQueue();

    expect(reports.reports, isEmpty);
    expect(await outbox.pending(), isEmpty);
  });

  test('going back to the list within a minute uses the memory', () async {
    await outbox.send(report('a'));
    await reports.load();
    expect(server.mineCalls, 1);

    now = now.add(const Duration(seconds: 59));
    await reports.load();
    expect(server.mineCalls, 1);
    expect(reports.reports.single.clientId, 'a');

    now = now.add(const Duration(seconds: 2));
    await reports.load();
    expect(server.mineCalls, 2);

    await reports.refresh();
    expect(server.mineCalls, 3);
  });

  test('a report sent while the list is in memory joins it', () async {
    await outbox.send(report('a', hour: 7));
    await reports.load();
    server.failure = const NetworkException('offline');
    await outbox.send(report('bb'));
    await pumpEventQueue();
    server.failure = null;
    await outbox.flush();
    await pumpEventQueue();

    await reports.load();

    expect(server.mineCalls, 1);
    expect(reports.reports.map((item) => item.clientId), ['bb', 'a']);
    expect(
      reports.reports.every((item) => item.state == ReportState.sent),
      isTrue,
    );
  });
}
