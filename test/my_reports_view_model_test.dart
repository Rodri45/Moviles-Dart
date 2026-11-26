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

  setUp(() {
    server = MockReportRepository();
    store = MemoryPendingReportStore();
    connectivity = MockConnectivity();
    outbox = OutboxReportRepository(server, store, connectivity);
    reports = MyReportsViewModel(outbox, outbox, connectivity);
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
}
