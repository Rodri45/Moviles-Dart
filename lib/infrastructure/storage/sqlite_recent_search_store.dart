import 'package:sqflite/sqflite.dart';

import '../../domain/entities/recent_search.dart';
import '../../domain/ports/recent_search_store.dart';

class SqliteRecentSearchStore implements RecentSearchStore {
  SqliteRecentSearchStore(this._db);

  static const _table = 'recent_searches';
  static const keep = 10;

  final Database _db;

  @override
  Future<List<RecentSearch>> recent() async {
    final rows = await _db.query(
      _table,
      orderBy: 'searched_at DESC',
      limit: keep,
    );
    return [
      for (final row in rows)
        RecentSearch(
          phrase: row['phrase']! as String,
          searchedAt: DateTime.parse(row['searched_at']! as String),
        ),
    ];
  }

  @override
  Future<void> save(String phrase, DateTime at) async {
    final cleaned = phrase.trim();
    if (cleaned.isEmpty) return;
    await _db.transaction((txn) async {
      await txn.insert(_table, {
        'phrase': cleaned,
        'searched_at': at.toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.rawDelete(
        'DELETE FROM $_table WHERE phrase NOT IN '
        '(SELECT phrase FROM $_table ORDER BY searched_at DESC LIMIT ?)',
        [keep],
      );
    });
  }
}
