import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_report.dart';

void main() {
  final json = {
    'id': 'r-1',
    'clientId': 'c-1',
    'spotId': 'P2-A-14',
    'spotCode': 'A-14',
    'levelCode': 'P2',
    'kind': 'blocked',
    'note': null,
    'shownStatus': 'free',
    'reportedAt': '2026-11-24T13:14:00.000Z',
    'photoUrl': '/api/v1/reports/r-1/photo',
  };

  test('a report from the server is sent and its photo is on the server', () {
    final report = SpotReport.fromJson(
      json,
      imageBase: 'https://parkwise.example.com',
    );

    expect(report.state, ReportState.sent);
    expect(report.kind, ReportKind.blocked);
    expect(report.shownStatus, SpotStatus.free);
    expect(
      report.photoUrl,
      'https://parkwise.example.com/api/v1/reports/r-1/photo',
    );
    expect(report.hasPhoto, isTrue);
  });

  test('the body sent keeps the state that the app showed', () {
    final report = SpotReport(
      clientId: 'c-2',
      spotId: 'P1-A-01',
      levelCode: 'P1',
      kind: ReportKind.occupied,
      shownStatus: SpotStatus.free,
      reportedAt: DateTime.utc(2026, 11, 24, 13, 14),
    );

    expect(report.toJson(photo: 'abc'), {
      'clientId': 'c-2',
      'spotId': 'P1-A-01',
      'kind': 'occupied',
      'shownStatus': 'free',
      'reportedAt': '2026-11-24T13:14:00.000Z',
      'photo': 'abc',
    });
    expect(report.toJson().containsKey('note'), isFalse);
  });

  test('an unknown kind is read as something else', () {
    expect(ReportKind.fromCode('noisy'), ReportKind.other);
  });
}
