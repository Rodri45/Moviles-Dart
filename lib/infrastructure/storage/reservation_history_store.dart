import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class ReservationHistoryStore {
  ReservationHistoryStore(this._database);

  static const _table = 'reservation_history';

  final Database _database;

  static Future<ReservationHistoryStore> open({String? databasePath}) async {
    final location =
        databasePath ??
        path.join(await getDatabasesPath(), 'parkwise_local.db');
    final database = await openDatabase(
      location,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_table (
            user_id TEXT NOT NULL,
            reservation_id TEXT NOT NULL,
            spot_id TEXT NOT NULL,
            spot_code TEXT NOT NULL,
            level_code TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            checked_in_at TEXT,
            released_at TEXT,
            PRIMARY KEY (user_id, reservation_id)
          )
        ''');
        await db.execute(
          'CREATE INDEX reservation_history_user_created '
          'ON $_table (user_id, created_at DESC)',
        );
        await db.execute('''
          CREATE TABLE reservation_history_sync (
            user_id TEXT PRIMARY KEY,
            synced_at TEXT NOT NULL
          )
        ''');
      },
    );
    return ReservationHistoryStore(database);
  }

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
      await transaction.delete(_table, where: 'user_id = ?', whereArgs: [userId]);
      for (final reservation in reservations) {
        await transaction.insert(_table, {
          ...reservation,
          'user_id': userId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await transaction.insert(
        'reservation_history_sync',
        {'user_id': userId, 'synced_at': DateTime.now().toUtc().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
