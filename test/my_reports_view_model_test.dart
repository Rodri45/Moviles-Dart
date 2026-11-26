import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_report.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/mock/mock_report_repository.dart';
import 'package:parkwise/presentation/screens/report/my_reports_view_model.dart';

SpotReport report(String clientId, {ReportState state = ReportState.sent}) =>
    SpotReport(
      clientId: clientId,
      spotId: 'P1-A-0${clientId.length}',
      levelCode: 'P1',
      kind: ReportKind.occupied,
      shownStatus: SpotStatus.free,
      reportedAt: DateTime(2026, 11, 24, 8),
      state: state,
    );

void main() {
  late MockReportRepository repository;
  late MyReportsViewModel reports;

  setUp(() {
    repository = MockReportRepository();
    reports = MyReportsViewModel(repository);
  });

  tearDown(() => reports.dispose());

  test('the reports of the driver are listed', () async {
    repository.reports.addAll([report('b'), report('a')]);

    await reports.load();

    expect(reports.reports.map((item) => item.clientId), ['b', 'a']);
    expect(reports.isLoading, isFalse);
    expect(reports.errorMessage, isNull);
  });

  test('a report just sent goes first and is not repeated', () async {
    repository.reports.add(report('a', state: ReportState.waiting));
    await reports.load();

    reports.added(report('a'));
    reports.added(report('c'));

    expect(reports.reports.map((item) => item.clientId), ['c', 'a']);
    expect(reports.reports.last.state, ReportState.sent);
  });

  test('a failure is shown and signing out clears the list', () async {
    repository.reports.add(report('a'));
    await reports.load();
    repository.failure = const ApiException(500, 'boom');

    await reports.load();

    expect(reports.errorMessage, 'The server had a problem. Try again.');
    expect(reports.reports, hasLength(1));
    reports.reset();
    expect(reports.reports, isEmpty);
  });
}
