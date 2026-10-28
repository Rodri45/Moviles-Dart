import 'package:sqflite/sqflite.dart';

import '../../domain/entities/pending_action.dart';
import '../../domain/ports/pending_action_store.dart';

class SqlitePendingActionStore implements PendingActionStore {
  SqlitePendingActionStore(this._db);

  static const _table = 'pending_actions';

  final Database _db;

  @override
  Future<int> addPending(PendingAction action) => _db.insert(_table, {
    'reservation_id': action.reservationId,
    'spot_code': action.spotCode,
    'action': action.type.code,
    'created_at': action.createdAt.toUtc().toIso8601String(),
  });

  @override
  Future<List<PendingAction>> pending() async {
    final rows = await _db.query(_table, orderBy: 'id ASC');
    return [
      for (final row in rows)
        PendingAction(
          id: row['id'] as int,
          reservationId: row['reservation_id'] as String,
          spotCode: row['spot_code'] as String,
          type: PendingActionType.fromCode(row['action'] as String),
          createdAt: DateTime.parse(row['created_at'] as String),
        ),
    ];
  }

  @override
  Future<int> pendingCount() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM $_table'),
      ) ??
      0;

  @override
  Future<void> removePending(int id) =>
      _db.delete(_table, where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> clear() => _db.delete(_table);
}
