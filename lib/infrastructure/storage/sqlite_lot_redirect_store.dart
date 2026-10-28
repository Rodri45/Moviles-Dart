import 'package:sqflite/sqflite.dart';

import '../../domain/entities/lot_redirect.dart';
import '../../domain/ports/lot_redirect_store.dart';

class SqliteLotRedirectStore implements LotRedirectStore {
  SqliteLotRedirectStore(this._db);

  static const _table = 'lot_redirects';

  final Database _db;

  @override
  Future<LotRedirect> add(String lotId, String lotName, DateTime at) async {
    final id = await _db.insert(_table, {
      'lot_id': lotId,
      'lot_name': lotName,
      'redirected_at': _iso(at),
    });
    return LotRedirect(
      id: id,
      lotId: lotId,
      lotName: lotName,
      redirectedAt: at,
    );
  }

  @override
  Future<LotRedirect?> openFor(String lotId, {required DateTime since}) =>
      _first(
        where: 'lot_id = ? AND redirected_at >= ? AND answered_at IS NULL',
        args: [lotId, _iso(since)],
      );

  @override
  Future<LotRedirect?> latest({required DateTime since}) =>
      _first(where: 'redirected_at >= ?', args: [_iso(since)]);

  @override
  Future<void> answer(int id, {required bool parked, required DateTime at}) =>
      _db.update(
        _table,
        {'answered_at': _iso(at), 'parked': parked ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );

  @override
  Future<void> clear() => _db.delete(_table);

  Future<LotRedirect?> _first({
    required String where,
    required List<Object> args,
  }) async {
    final rows = await _db.query(
      _table,
      where: where,
      whereArgs: args,
      orderBy: 'redirected_at DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    final answeredAt = row['answered_at'] as String?;
    final parked = row['parked'] as int?;
    return LotRedirect(
      id: row['id'] as int,
      lotId: row['lot_id'] as String,
      lotName: row['lot_name'] as String,
      redirectedAt: DateTime.parse(row['redirected_at'] as String),
      answeredAt: answeredAt == null ? null : DateTime.parse(answeredAt),
      parked: parked == null ? null : parked == 1,
    );
  }

  static String _iso(DateTime date) => date.toUtc().toIso8601String();
}
