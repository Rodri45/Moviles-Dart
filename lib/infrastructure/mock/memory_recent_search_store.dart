import '../../domain/entities/recent_search.dart';
import '../../domain/ports/recent_search_store.dart';

class MemoryRecentSearchStore implements RecentSearchStore {
  final List<RecentSearch> searches = [];

  @override
  Future<List<RecentSearch>> recent() async => [...searches.reversed];

  @override
  Future<void> save(String phrase, DateTime at) async {
    searches
      ..removeWhere(
        (search) => search.phrase.toLowerCase() == phrase.toLowerCase(),
      )
      ..add(RecentSearch(phrase: phrase, searchedAt: at));
  }
}
