import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static const fileName = 'parkwise_local.db';
  static const version = 3;

  static Future<Database> open({String? databasePath}) async {
    final location =
        databasePath ?? path.join(await getDatabasesPath(), fileName);
    return openDatabase(
      location,
      version: version,
      onCreate: (db, _) => _migrate(db, from: 0),
      onUpgrade: (db, from, _) => _migrate(db, from: from),
    );
  }

  static Future<void> _migrate(Database db, {required int from}) async {
    if (from < 1) await _createReservationHistory(db);
    if (from < 2) await _createPendingActions(db);
    if (from < 3) await _createNearbyLotTables(db);
  }

  static Future<void> _createReservationHistory(Database db) async {
    await db.execute('''
      CREATE TABLE reservation_history (
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
      'ON reservation_history (user_id, created_at DESC)',
    );
    await db.execute('''
      CREATE TABLE reservation_history_sync (
        user_id TEXT PRIMARY KEY,
        synced_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createNearbyLotTables(Database db) async {
    await db.execute('''
      CREATE TABLE nearby_lots (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        rate_per_hour INTEGER NOT NULL,
        currency TEXT NOT NULL,
        walk_minutes INTEGER NOT NULL,
        image_url TEXT,
        saved_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE lot_redirects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lot_id TEXT NOT NULL,
        lot_name TEXT NOT NULL,
        redirected_at TEXT NOT NULL,
        answered_at TEXT,
        parked INTEGER CHECK (parked IN (0, 1))
      )
    ''');
    await db.execute(
      'CREATE INDEX lot_redirects_lot_date '
      'ON lot_redirects (lot_id, redirected_at)',
    );
  }

  static Future<void> _createPendingActions(Database db) => db.execute('''
    CREATE TABLE pending_actions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      reservation_id TEXT NOT NULL,
      spot_code TEXT NOT NULL,
      action TEXT NOT NULL CHECK (action IN ('check_in', 'release')),
      created_at TEXT NOT NULL
    )
  ''');
}
