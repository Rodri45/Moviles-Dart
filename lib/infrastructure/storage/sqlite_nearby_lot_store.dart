import 'package:sqflite/sqflite.dart';

import '../../domain/entities/cached.dart';
import '../../domain/entities/nearby_lot.dart';
import '../../domain/ports/nearby_lot_store.dart';

class SqliteNearbyLotStore implements NearbyLotStore {
  SqliteNearbyLotStore(this._db);

  static const _table = 'nearby_lots';

  final Database _db;

  @override
  Future<Cached<List<NearbyLot>>?> read() async {
    final rows = await _db.query(_table, orderBy: 'walk_minutes ASC, id ASC');
    if (rows.isEmpty) return null;
    return Cached(
      [
        for (final row in rows)
          NearbyLot(
            id: row['id'] as String,
            name: row['name'] as String,
            address: row['address'] as String,
            ratePerHour: row['rate_per_hour'] as int,
            currency: row['currency'] as String,
            walkMinutes: row['walk_minutes'] as int,
            imageUrl: row['image_url'] as String?,
          ),
      ],
      savedAt: DateTime.parse(rows.first['saved_at'] as String),
    );
  }

  @override
  Future<void> save(List<NearbyLot> lots, DateTime savedAt) =>
      _db.transaction((txn) async {
        await txn.delete(_table);
        for (final lot in lots) {
          await txn.insert(_table, {
            'id': lot.id,
            'name': lot.name,
            'address': lot.address,
            'rate_per_hour': lot.ratePerHour,
            'currency': lot.currency,
            'walk_minutes': lot.walkMinutes,
            'image_url': lot.imageUrl,
            'saved_at': savedAt.toUtc().toIso8601String(),
          });
        }
      });
}
