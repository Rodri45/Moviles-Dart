import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:parkwise/domain/entities/pending_action.dart';
import 'package:parkwise/infrastructure/storage/local_database.dart';
import 'package:parkwise/infrastructure/storage/reservation_history_store.dart';
import 'package:parkwise/infrastructure/storage/sqlite_pending_action_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('a phone with version 1 keeps its history and gets the queue', () async {
    final directory = await Directory.systemTemp.createTemp('parkwise_db');
    final file = path.join(directory.path, LocalDatabase.fileName);
    final first = await databaseFactoryFfi.openDatabase(
      file,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
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
          await db.execute('''
            CREATE TABLE reservation_history_sync (
              user_id TEXT PRIMARY KEY,
              synced_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    await first.insert('reservation_history', {
      'user_id': 'user-a',
      'reservation_id': 'reservation-1',
      'spot_id': 'P2-B-03',
      'spot_code': 'B-03',
      'level_code': 'P2',
      'status': 'fulfilled',
      'created_at': '2026-10-26T13:00:00.000Z',
      'expires_at': '2026-10-26T13:15:00.000Z',
      'checked_in_at': '2026-10-26T13:10:00.000Z',
      'released_at': null,
    });
    await first.insert('reservation_history_sync', {
      'user_id': 'user-a',
      'synced_at': '2026-10-26T13:10:00.000Z',
    });
    await first.close();

    final db = await LocalDatabase.open(databasePath: file);
    try {
      expect(await db.getVersion(), LocalDatabase.version);
      final history = await ReservationHistoryStore(db).read('user-a');
      expect(history!.reservations.single['reservation_id'], 'reservation-1');
      expect(await SqlitePendingActionStore(db).pendingCount(), 0);
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });

  test('the queue keeps the order and refuses unknown actions', () async {
    final db = await LocalDatabase.open(databasePath: inMemoryDatabasePath);
    final queue = SqlitePendingActionStore(db);
    final parkedAt = DateTime.utc(2026, 10, 26, 13, 10);
    try {
      final first = await queue.addPending(
        PendingAction(
          reservationId: 'reservation-1',
          spotCode: 'B-03',
          type: PendingActionType.checkIn,
          createdAt: parkedAt,
        ),
      );
      await queue.addPending(
        PendingAction(
          reservationId: 'reservation-1',
          spotCode: 'B-03',
          type: PendingActionType.release,
          createdAt: parkedAt.add(const Duration(hours: 2)),
        ),
      );

      final actions = await queue.pending();
      expect(actions.map((action) => action.type), [
        PendingActionType.checkIn,
        PendingActionType.release,
      ]);
      expect(actions.first.createdAt, parkedAt);
      expect(await queue.pendingCount(), 2);

      await queue.removePending(first);
      expect((await queue.pending()).single.type, PendingActionType.release);

      await expectLater(
        db.insert('pending_actions', {
          'reservation_id': 'reservation-1',
          'spot_code': 'B-03',
          'action': 'reserve',
          'created_at': parkedAt.toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    } finally {
      await db.close();
    }
  });
}
