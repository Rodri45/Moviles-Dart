import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/spot_report.dart';
import '../../domain/ports/pending_report_store.dart';

class SqlitePendingReportStore implements PendingReportStore {
  SqlitePendingReportStore(this._db, this._photos);

  static const _table = 'pending_reports';

  final Database _db;
  final Directory _photos;

  @override
  Future<void> add(SpotReport report, {Uint8List? photo}) async {
    String? photoPath;
    if (photo != null) {
      await _photos.create(recursive: true);
      photoPath = path.join(_photos.path, '${report.clientId}.jpg');
      await File(photoPath).writeAsBytes(photo, flush: true);
    }
    await _db.insert(_table, {
      'client_id': report.clientId,
      'spot_id': report.spotId,
      'level_code': report.levelCode,
      'kind': report.kind.code,
      'shown_status': report.shownStatus.name,
      'note': report.note,
      'photo_path': photoPath,
      'reported_at': report.reportedAt.toUtc().toIso8601String(),
      'state': ReportState.waiting.name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<List<SpotReport>> pending() async {
    final rows = await _db.query(_table, orderBy: 'id ASC');
    return [
      for (final row in rows)
        SpotReport(
          clientId: row['client_id'] as String,
          spotId: row['spot_id'] as String,
          levelCode: row['level_code'] as String,
          kind: ReportKind.fromCode(row['kind'] as String),
          shownStatus:
              SpotStatus.values.asNameMap()[row['shown_status']] ??
              SpotStatus.free,
          note: row['note'] as String?,
          photoPath: row['photo_path'] as String?,
          reportedAt: DateTime.parse(row['reported_at'] as String),
          state: row['state'] == ReportState.sending.name
              ? ReportState.sending
              : ReportState.waiting,
        ),
    ];
  }

  @override
  Future<Uint8List?> photoOf(SpotReport report) async {
    final photoPath = report.photoPath;
    if (photoPath == null) return null;
    final file = File(photoPath);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> setState(String clientId, ReportState state) => _db.update(
    _table,
    {'state': state.name},
    where: 'client_id = ?',
    whereArgs: [clientId],
  );

  @override
  Future<void> remove(String clientId) async {
    final rows = await _db.query(
      _table,
      columns: ['photo_path'],
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
    await _db.delete(_table, where: 'client_id = ?', whereArgs: [clientId]);
    for (final row in rows) {
      await _deletePhoto(row['photo_path'] as String?);
    }
  }

  @override
  Future<void> clear() async {
    await _db.delete(_table);
    if (await _photos.exists()) await _photos.delete(recursive: true);
  }

  static Future<void> _deletePhoto(String? photoPath) async {
    if (photoPath == null) return;
    final file = File(photoPath);
    if (await file.exists()) await file.delete();
  }
}
