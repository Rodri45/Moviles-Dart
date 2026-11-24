import '../entities/recent_search.dart';

abstract interface class RecentSearchStore {
  Future<List<RecentSearch>> recent();

  Future<void> save(String phrase, DateTime at);
}
