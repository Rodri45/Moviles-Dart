import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

class ReservationHistoryStore {
  ReservationHistoryStore(this._database);

  static const _table = 'reservation_history';

  final Database _database;

  static Future<ReservationHistoryStore> open({String? databasePath}) async =>
      ReservationHistoryStore(
        await LocalDatabase.open(databasePath: databasePath),
      );

  Future<
    ({List<Map<String, Object?>> reservations, DateTime savedAt})?
  > read(String userId) async {
    final rows = await _database.query(
      _table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    final sync = await _database.query(
      'reservation_history_sync',
      columns: ['synced_at'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (sync.isEmpty) return null;
    return (
      reservations: [
        for (final row in rows)
          Map<String, Object?>.from(row)..remove('user_id'),
      ],
      savedAt: DateTime.parse(sync.single['synced_at'] as String),
    );
  }

  Future<void> replace(
    String userId,
    List<Map<String, Object?>> reservations,
  ) async {
    await _database.transaction((transaction) async {
      await transaction.delete(
        _table,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      for (final reservation in reservations) {
        await transaction.insert(_table, {
          ...reservation,
          'user_id': userId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await transaction.insert('reservation_history_sync', {
        'user_id': userId,
        'synced_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> upsert(String userId, Map<String, Object?> reservation) =>
      _database.transaction((transaction) async {
        await transaction.insert(
          _table,
          {...reservation, 'user_id': userId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await transaction.insert(
          'reservation_history_sync',
          {
            'user_id': userId,
            'synced_at': DateTime.now().toUtc().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

  Future<void> clear() async {
    await _database.delete(_table);
    await _database.delete('reservation_history_sync');
  }

  Future<void> close() => _database.close();
}
