import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/cache/lru_cache.dart';
import '../../../domain/entities/cached.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/spot_filter.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/telemetry.dart';
import '../../../domain/services/spot_ranking.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';
import '../level_map/level_map_view_model.dart';

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

  static const memoryEntries = 16;

  static const memoryTtl = Duration(seconds: 30);

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final Telemetry _telemetry;
  final SpotRanker _rank;
  final LruCache<String, Cached<List<ParkingSpot>>> _memory;
  Timer? _queryDebounce;
  int _generation = 0;

  Set<SpotFilter> filters = {SpotFilter.available};
  String query = '';
  List<ParkingSpot> _spots = const [];
  SpotSearchResult _ranked = SpotSearchResult.empty;
  DateTime? savedAt;
  bool fromCache = false;
  bool fromMemory = false;
  bool isLoading = false;
  String? errorMessage;

  bool get showOffline => !online || fromCache;

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
    await load();
  }

  void setQuery(String value) {
    query = value;
    _queryDebounce?.cancel();
    _queryDebounce = Timer(const Duration(milliseconds: 150), _rerank);
    notifyListeners();
  }

  Future<void> refresh() => load(force: true);

  Future<void> load({bool force = false}) async {
    final requested = filters;
    final destination = _preferences.destination;
    final key = _memoryKey(destination, requested);

    final remembered = force ? null : _memory.get(key);
    if (remembered != null) {
      fromMemory = true;
      await _show(remembered, requested);
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
      final combined = Cached(
        [for (final level in perLevel) ...level.data],
        savedAt: perLevel
            .map((level) => level.savedAt)
            .reduce((a, b) => a.isBefore(b) ? a : b),
        fromCache: perLevel.any((level) => level.fromCache),
      );
      if (!combined.fromCache) {
        _memory.put(key, combined);
        _telemetry.track('availability_viewed', {'source': 'find_spot'});
      }
      fromMemory = false;
      await _show(combined, requested);
    } catch (e) {
      errorMessage = errorMessageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _show(
    Cached<List<ParkingSpot>> data,
    Set<SpotFilter> requested,
  ) async {
    _spots = data.data;
    savedAt = data.savedAt;
    fromCache = data.fromCache;
    await _rerank(requested);
  }

  Future<void> _rerank([Set<SpotFilter>? requested]) async {
    final generation = ++_generation;
    final ranked = await _rank(
      SpotSearchInput(
        spots: _spots,
        filters: requested ?? filters,
        query: query,
      ),
    );
    if (generation != _generation) return;
    _ranked = ranked;
    notifyListeners();
  }

  static String _memoryKey(String destination, Set<SpotFilter> filters) {
    final names = filters.map((f) => f.name).toList()..sort();
    return '$destination|${names.join(',')}';
  }

  @override
  void dispose() {
    _queryDebounce?.cancel();
    super.dispose();
  }
}
