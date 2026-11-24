import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/cache/lru_cache.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/saved.dart';
import '../../../domain/entities/spot_filter.dart';
import '../../../domain/entities/voice_query.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/telemetry.dart';
import '../../../domain/services/spot_ranking.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';
import '../level_map/level_map_view_model.dart';

typedef _Remembered = ({
  Saved<List<ParkingSpot>> data,
  SpotSearchResult ranked,
});

class FindSpotViewModel extends ChangeNotifier with ConnectivityAware {
  FindSpotViewModel(
    this._parking,
    this._preferences,
    this._telemetry,
    ConnectivityPort connectivity, {
    this._rank = rankSpotsInBackground,
    DateTime Function()? clock,
  }) : _memory = LruCache(
         maxEntries: memoryEntries,
         ttl: memoryTtl,
         clock: clock,
       ) {
    watchConnectivity(connectivity, () => load(force: true));
  }

  static const memoryEntries = 8;

  static const memoryTtl = Duration(seconds: 30);

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final Telemetry _telemetry;
  final SpotRanker _rank;
  final LruCache<String, _Remembered> _memory;
  Timer? _queryDebounce;
  int _generation = 0;

  Set<SpotFilter> filters = {SpotFilter.available};
  String query = '';
  List<ParkingSpot> _spots = const [];
  Saved<List<ParkingSpot>>? _data;
  SpotSearchResult _ranked = SpotSearchResult.empty;
  DateTime? savedAt;
  bool fromStorage = false;
  bool fromMemory = false;
  bool isLoading = false;
  String? errorMessage;
  String? spokenPhrase;

  bool get showOffline => !online || fromStorage;

  @override
  bool get showingSavedData => fromStorage;

  List<ParkingSpot> get results => _ranked.results;

  ParkingSpot? get recommended => _ranked.recommended;

  Future<void> toggleFilter(SpotFilter filter) async {
    if (filters.contains(filter)) {
      filters = {...filters}..remove(filter);
    } else {
      filters = {...filters, filter};
      _telemetry.track('filter_applied', {'filter': filter.name});
    }
    await load();
  }

  Future<void> setFilters(Set<SpotFilter> value) async {
    filters = {...value};
    query = '';
    spokenPhrase = null;
    await load();
  }

  void setQuery(String value) {
    query = value;
    spokenPhrase = null;
    _queryDebounce?.cancel();
    _queryDebounce = Timer(const Duration(milliseconds: 150), _rerank);
    notifyListeners();
  }

  Future<void> searchPhrase(
    String phrase,
    VoiceQuery voiceQuery, {
    required bool spoken,
  }) async {
    spokenPhrase = spoken ? phrase : null;
    filters = {...voiceQuery.filters};
    query = voiceQuery.searchText;
    await load();
  }

  Future<void> refresh() => load(force: true);

  Future<void> load({bool force = false}) async {
    final requested = filters;
    final destination = _preferences.destination;

    final remembered = force
        ? null
        : _memory.get(_memoryKey(destination, requested, query));
    if (remembered != null) {
      _generation++;
      fromMemory = true;
      _useData(remembered.data);
      _ranked = remembered.ranked;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final perLevel = await Future.wait([
        for (final code in LevelMapViewModel.levelCodes)
          _parking.getSpots(code, destination: destination, filters: requested),
      ]);
      if (requested != filters) return;
      final combined = Saved(
        [for (final level in perLevel) ...level.data],
        savedAt: perLevel
            .map((level) => level.savedAt)
            .reduce((a, b) => a.isBefore(b) ? a : b),
        fromStorage: perLevel.any((level) => level.fromStorage),
      );
      if (!combined.fromStorage) {
        _telemetry.track('availability_viewed', {'source': 'find_spot'});
      }
      fromMemory = false;
      _useData(combined);
      await _rerank(requested);
    } catch (e) {
      errorMessage = errorMessageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _useData(Saved<List<ParkingSpot>> data) {
    _data = data;
    _spots = data.data;
    savedAt = data.savedAt;
    fromStorage = data.fromStorage;
  }

  Future<void> _rerank([Set<SpotFilter>? requested]) async {
    final generation = ++_generation;
    final used = requested ?? filters;
    final data = _data;
    final key = _memoryKey(_preferences.destination, used, query);
    final remembered = _memory.get(key);
    if (remembered != null && identical(remembered.data, data)) {
      _ranked = remembered.ranked;
      notifyListeners();
      return;
    }
    final ranked = await _rank(
      SpotSearchInput(spots: _spots, filters: used, query: query),
    );
    if (generation != _generation) return;
    _ranked = ranked;
    if (data != null && !data.fromStorage) {
      _memory.put(key, (data: data, ranked: ranked));
    }
    notifyListeners();
  }

  static String _memoryKey(
    String destination,
    Set<SpotFilter> filters,
    String query,
  ) {
    final names = filters.map((f) => f.name).toList()..sort();
    return '$destination|${names.join(',')}|${query.trim().toLowerCase()}';
  }

  @override
  void dispose() {
    _queryDebounce?.cancel();
    super.dispose();
  }
}
