import '../../domain/entities/building.dart';
import '../../domain/entities/cached.dart';
import '../../domain/entities/level_forecast.dart';
import '../../domain/entities/level_recommendation.dart';
import '../../domain/entities/levels_overview.dart';
import '../../domain/entities/nearby_lot.dart';
import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/spot_filter.dart';
import '../../domain/ports/parking_repository.dart';
import '../storage/local_cache.dart';
import 'api_client.dart';

// niveles, puestos y catalogo desde el backend. guarda la ultima respuesta
// buena y la devuelve marcada como fromCache si la red o el servidor fallan
class HttpParkingRepository implements ParkingRepository {
  HttpParkingRepository(this._client, this._cache, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ApiClient _client;
  final LocalCache _cache;
  final DateTime Function() _clock;

  @override
  Future<Cached<LevelsOverview>> getLevels({String? zone}) => _withCache(
    'levels',
    () => _client.get('/levels', query: {'zone': ?zone}),
    (json) => LevelsOverview.fromJson(json as Map<String, dynamic>),
  );

  @override
  Future<Cached<List<ParkingSpot>>> getSpots(
    String levelCode, {
    required String destination,
    Set<SpotFilter> filters = const {},
  }) async {
    final baseKey = 'spots:$levelCode:$destination';
    final names = filters.map((f) => f.name).toList()..sort();
    final key = filters.isEmpty ? baseKey : '$baseKey:${names.join(',')}';

    try {
      return await _withCache(
        key,
        () => _client.get(
          '/levels/$levelCode/spots',
          query: {
            'destination': destination,
            for (final filter in filters) _queryKey(filter): 'true',
          },
        ),
        _parseSpots,
      );
    } catch (e) {
      // si nunca se pidio con estos filtros, se filtra la copia completa
      final entry = filters.isEmpty || !ApiClient.isNetworkFailure(e)
          ? null
          : _cache.read(baseKey);
      if (entry == null) rethrow;
      final spots = _parseSpots(entry.data)
          .where((spot) => filters.every((f) => f.matches(spot)))
          .toList();
      return Cached(spots, savedAt: entry.savedAt, fromCache: true);
    }
  }

  @override
  Future<List<Building>> getBuildings() async {
    final result = await _withCache(
      'buildings',
      () => _client.get('/buildings'),
      (json) => [
        for (final b in json as List)
          Building.fromJson(b as Map<String, dynamic>),
      ],
    );
    return result.data;
  }

  @override
  Future<List<LevelForecast>> getPredictions({
    String? level,
    DateTime? date,
  }) async {
    final json = await _client.get(
      '/predictions',
      query: {'level': ?level, 'date': ?(date == null ? null : _day(date))},
    );
    return [
      for (final l in (json as Map<String, dynamic>)['levels'] as List)
        LevelForecast.fromJson(l as Map<String, dynamic>),
    ];
  }

  @override
  Future<LevelRecommendation> getRecommendedLevel(DateTime arrivalAt) async {
    final json = await _client.get(
      '/recommendations/level',
      query: {'arrivalAt': arrivalAt.toUtc().toIso8601String()},
    );
    return LevelRecommendation.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<NearbyLot>> getNearbyLots() async {
    final json = await _client.get('/nearby-lots') as List;
    return [
      for (final l in json) NearbyLot.fromJson(l as Map<String, dynamic>),
    ];
  }

  Future<Cached<T>> _withCache<T>(
    String key,
    Future<dynamic> Function() fetch,
    T Function(Object? json) parse,
  ) async {
    try {
      final json = await fetch();
      final data = parse(json);
      final savedAt = _clock();
      await _cache.write(key, json, savedAt: savedAt);
      return Cached(data, savedAt: savedAt);
    } catch (e) {
      final entry = ApiClient.isNetworkFailure(e) ? _cache.read(key) : null;
      if (entry == null) rethrow;
      return Cached(parse(entry.data), savedAt: entry.savedAt, fromCache: true);
    }
  }

  static List<ParkingSpot> _parseSpots(Object? json) => [
    for (final s in json as List)
      ParkingSpot.fromJson(s as Map<String, dynamic>),
  ];

  static String _queryKey(SpotFilter filter) => switch (filter) {
    SpotFilter.available => 'available',
    SpotFilter.vip => 'vip',
    SpotFilter.electric => 'ev',
    SpotFilter.accessible => 'accessible',
  };

  static String _day(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
