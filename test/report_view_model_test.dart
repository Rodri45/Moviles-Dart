import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/report_photo.dart';
import 'package:parkwise/domain/entities/spot_report.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/mock/mock_form_draft_store.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_photo_source.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/infrastructure/mock/mock_report_repository.dart';
import 'package:parkwise/presentation/screens/report/report_view_model.dart';

class _BrokenCamera extends MockPhotoSource {
  @override
  Future<Uint8List?> takePhoto() async => throw StateError('no camera');
}

void main() {
  const spot = ParkingSpot(
    id: 'P2-A-14',
    code: 'A-14',
    zone: 'A',
    levelCode: 'P2',
    status: SpotStatus.free,
    walkMinutes: 4,
  );
  final now = DateTime(2026, 11, 24, 8, 14);
  late MockReportRepository reports;
  late MockPreferencesStore preferences;
  late MockFormDraftStore drafts;
  late MockPhotoSource camera;
  late ReportViewModel report;
  late List<Uint8List> compressed;

  Future<ReportPhoto> compress(Uint8List original) async {
    compressed.add(original);
    return ReportPhoto(
      bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
      originalBytes: original.length,
    );
  }

  ReportViewModel build(MockPhotoSource source) => ReportViewModel(
    reports,
    source,
    MockParkingRepository(),
    preferences,
    drafts,
    compress: compress,
    newId: () => 'client-1',
    clock: () => now,
  );

  setUp(() {
    reports = MockReportRepository();
    preferences = MockPreferencesStore();
    drafts = MockFormDraftStore();
    camera = MockPhotoSource(photo: Uint8List(2400000));
    compressed = [];
    report = build(camera);
  });

  tearDown(() => report.dispose());

  test('the report keeps the spot, its level and the state shown', () async {
    report
      ..start(spot: spot)
      ..chooseKind(ReportKind.blocked)
      ..changeNote('  A cone on the spot  ');

    final sent = await report.send();

    expect(sent?.state, ReportState.sent);
    final saved = reports.reports.single;
    expect(saved.clientId, 'client-1');
    expect(saved.spotId, 'P2-A-14');
    expect(saved.levelCode, 'P2');
    expect(saved.shownStatus, SpotStatus.free);
    expect(saved.kind, ReportKind.blocked);
    expect(saved.note, 'A cone on the spot');
    expect(saved.reportedAt, now);
    expect(report.spot, isNull);
    expect(report.isSending, isFalse);
  });

  test('the photo is compressed before it is sent', () async {
    report.start(spot: spot);

    await report.takePhoto();

    expect(compressed.single.length, 2400000);
    expect(report.photo?.originalBytes, 2400000);
    expect(report.photo?.sizeBytes, 4);
    final photo = report.photo!;
    await report.send();
    expect(reports.photos.values.single, photo.bytes);
  });

  test('closing the camera without a photo changes nothing', () async {
    camera.photo = null;
    report.start(spot: spot);

    await report.takePhoto();

    expect(compressed, isEmpty);
    expect(report.photo, isNull);
    expect(report.errorMessage, isNull);
  });

  test('a camera that fails says so', () async {
    report.dispose();
    report = build(_BrokenCamera());
    report.start(spot: spot);

    await report.takePhoto();

    expect(report.errorMessage, 'The camera could not be opened.');
    expect(report.isCompressing, isFalse);
  });

  test('a report the server refuses keeps what the driver wrote', () async {
    reports.failure = const ApiException(400, 'Invalid request');
    report
      ..start(spot: spot)
      ..changeNote('Blocked');

    final sent = await report.send();

    expect(sent, isNull);
    expect(report.errorMessage, 'Invalid request');
    expect(report.spot, spot);
    expect(report.note, 'Blocked');
    expect(report.isSending, isFalse);
  });

  test('without a spot nothing is sent', () async {
    report.start();

    expect(report.canSend, isFalse);
    expect(await report.send(), isNull);
    expect(reports.sendCalls, 0);
  });

  test('a report left halfway comes back when the view opens', () async {
    report
      ..start(spot: spot)
      ..chooseKind(ReportKind.damaged)
      ..changeNote('Paint gone');
    await pumpEventQueue();

    final next = build(camera);
    addTearDown(next.dispose);
    next.start();

    expect(next.spot?.id, 'P2-A-14');
    expect(next.spot?.levelCode, 'P2');
    expect(next.spot?.status, SpotStatus.free);
    expect(next.kind, ReportKind.damaged);
    expect(next.note, 'Paint gone');
  });

  test('another spot starts a new report with the last type used', () async {
    preferences.lastReportKind = 'blocked';
    report
      ..start(spot: spot)
      ..changeNote('Old note');
    await pumpEventQueue();

    report.start(
      spot: const ParkingSpot(
        id: 'P1-A-01',
        code: 'A-01',
        zone: 'A',
        levelCode: 'P1',
        status: SpotStatus.occupied,
        walkMinutes: 2,
      ),
    );

    expect(report.kind, ReportKind.blocked);
    expect(report.note, isEmpty);
  });

  test('sending keeps the type for next time and clears the draft', () async {
    report
      ..start(spot: spot)
      ..chooseKind(ReportKind.damaged);

    await report.send();
    await pumpEventQueue();

    expect(preferences.lastReportKind, 'damaged');
    expect(drafts.read(ReportViewModel.draftForm), isEmpty);
    report.start();
    expect(report.spot, isNull);
    expect(report.kind, ReportKind.damaged);
  });
}
