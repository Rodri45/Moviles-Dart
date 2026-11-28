import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_report.dart';
import 'package:parkwise/infrastructure/storage/local_database.dart';
import 'package:parkwise/infrastructure/storage/sqlite_pending_report_store.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  late Database db;
  late SqlitePendingReportStore store;
  final photo = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);

  SpotReport report(String clientId, {String? note}) => SpotReport(
    clientId: clientId,
    spotId: 'P2-A-14',
    levelCode: 'P2',
    kind: ReportKind.blocked,
    shownStatus: SpotStatus.free,
    reportedAt: DateTime.utc(2026, 11, 24, 13, 14),
    note: note,
  );

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('parkwise_reports');
    db = await LocalDatabase.open(databasePath: inMemoryDatabasePath);
    store = SqlitePendingReportStore(
      db,
      Directory(path.join(directory.path, 'report_photos')),
    );
  });

  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test('a report waits in order with its photo in a file', () async {
    await store.add(report('a', note: 'Cone'), photo: photo);
    await store.add(report('b'));

    final pending = await store.pending();

    expect(pending.map((item) => item.clientId), ['a', 'b']);
    expect(pending.first.state, ReportState.waiting);
    expect(pending.first.kind, ReportKind.blocked);
    expect(pending.first.shownStatus, SpotStatus.free);
    expect(pending.first.note, 'Cone');
    expect(pending.first.reportedAt, DateTime.utc(2026, 11, 24, 13, 14));
    expect(File(pending.first.photoPath!).existsSync(), isTrue);
    expect(await store.photoOf(pending.first), photo);
    expect(pending.last.photoPath, isNull);
    expect(await store.photoOf(pending.last), isNull);
  });

  test('the same report is never queued twice', () async {
    await store.add(report('a'));
    await store.add(report('a'));

    expect(await store.pending(), hasLength(1));
  });

  test('the state is kept and a sent report leaves with its photo', () async {
    await store.add(report('a'), photo: photo);
    await store.setState('a', ReportState.sending);
    final sending = (await store.pending()).single;
    expect(sending.state, ReportState.sending);

    await store.remove('a');

    expect(await store.pending(), isEmpty);
    expect(File(sending.photoPath!).existsSync(), isFalse);
  });

  test('clearing removes every report and photo', () async {
    await store.add(report('a'), photo: photo);
    await store.add(report('b'), photo: photo);

    await store.clear();

    expect(await store.pending(), isEmpty);
    expect(
      Directory(path.join(directory.path, 'report_photos')).existsSync(),
      isFalse,
    );
  });
}
