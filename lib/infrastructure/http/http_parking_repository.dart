import '../../domain/entities/building.dart';
import '../../domain/entities/level_forecast.dart';
import '../../domain/entities/level_recommendation.dart';
import '../../domain/entities/levels_overview.dart';
import '../../domain/entities/nearby_lot.dart';
import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/saved.dart';
import '../../domain/entities/spot_filter.dart';
import '../../domain/entities/week_forecast.dart';
import '../../domain/ports/parking_repository.dart';
import '../storage/offline_store.dart';
import 'api_client.dart';

class HttpParkingRepository implements ParkingRepository {
  HttpParkingRepository(
    this._client,
    this._offline, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ApiClient _client;
  final OfflineStore _offline;
  final DateTime Function() _clock;

  @override
  Future<Saved<LevelsOverview>> getLevels({String? zone}) => _withOfflineCopy(
    'levels',
    () => _client.get('/levels', query: {'zone': ?zone}),
    (json) => LevelsOverview.fromJson(
      json as Map<String, dynamic>,
      imageBase: _client.baseUrl,
    ),
  );

  @override
  Future<Saved<List<ParkingSpot>>> getSpots(
    String levelCode, {
    required String destination,
    Set<SpotFilter> filters = const {},
  }) async {
    final baseKey = 'spots:$levelCode:$destination';
    final names = filters.map((f) => f.name).toList()..sort();
    final key = filters.isEmpty ? baseKey : '$baseKey:${names.join(',')}';

    try {
      return await _withOfflineCopy(
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
      final entry = filters.isEmpty || !ApiClient.isNetworkFailure(e)
          ? null
          : _offline.read(baseKey);
      if (entry == null) rethrow;
      final spots = _parseSpots(entry.data)
          .where((spot) => filters.every((f) => f.matches(spot)))
          .toList();
      return Saved(spots, savedAt: entry.savedAt, fromStorage: true);
    }
  }

  @override
  Future<List<Building>> getBuildings() async {
    final result = await _withOfflineCopy(
      'buildings',
      () => _client.get('/buildings'),
      (json) => [
        for (final b in json as List)
          Building.fromJson(
            b as Map<String, dynamic>,
            imageBase: _client.baseUrl,
          ),
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
  Future<WeekForecast> getWeekForecast(
    String level, {
    required DateTime from,
  }) async {
    final json = await _client.get(
      '/predictions/week',
      query: {'level': level, 'from': isoDay(from)},
    );
    return WeekForecast.fromApi(json as Map<String, dynamic>);
  }

  @override
  Future<List<NearbyLot>> getNearbyLots() async {
    final json = await _client.get('/nearby-lots') as List;
    return [
      for (final l in json)
        NearbyLot.fromJson(
          l as Map<String, dynamic>,
          imageBase: _client.baseUrl,
        ),
    ];
  }

  Future<Saved<T>> _withOfflineCopy<T>(
    String key,
    Future<dynamic> Function() fetch,
    T Function(Object? json) parse,
  ) async {
    try {
      final json = await fetch();
      final data = parse(json);
      final savedAt = _clock();
      await _offline.write(key, json, savedAt: savedAt);
      return Saved(data, savedAt: savedAt);
    } catch (e) {
      final entry = ApiClient.isNetworkFailure(e) ? _offline.read(key) : null;
      if (entry == null) rethrow;
      return Saved(
        parse(entry.data),
        savedAt: entry.savedAt,
        fromStorage: true,
      );
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
