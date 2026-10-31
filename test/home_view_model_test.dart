import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/cached.dart';
import 'package:parkwise/domain/entities/level_forecast.dart';
import 'package:parkwise/domain/entities/levels_overview.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_filter.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_location_provider.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/infrastructure/mock/mock_telemetry.dart';
import 'package:parkwise/infrastructure/storage/forecast_file_store.dart';
import 'package:parkwise/presentation/screens/home/home_view_model.dart';

class _CountingParking extends MockParkingRepository {
  int levelCalls = 0;
  int spotCalls = 0;

  @override
  Future<Cached<LevelsOverview>> getLevels({String? zone}) {
    levelCalls++;
    return super.getLevels(zone: zone);
  }

  @override
  Future<Cached<List<ParkingSpot>>> getSpots(
    String levelCode, {
    required String destination,
    Set<SpotFilter> filters = const {},
  }) {
    spotCalls++;
    return super.getSpots(levelCode, destination: destination);
  }
}

class _OfflineForecastParking extends _CountingParking {
  @override
  Future<List<LevelForecast>> getPredictions({
    String? level,
    DateTime? date,
  }) async {
    throw const NetworkException('offline');
  }
}

void main() {
  late _CountingParking parking;
  late MockConnectivity connectivity;
  late MockTelemetry telemetry;
  late HomeViewModel home;

  setUp(() {
    parking = _CountingParking();
    connectivity = MockConnectivity();
    telemetry = MockTelemetry();
    home = HomeViewModel(
      parking,
      MockPreferencesStore(),
      MockLocationProvider(),
      telemetry,
      connectivity,
      refreshEvery: const Duration(milliseconds: 20),
    );
  });

  tearDown(() => home.dispose());

  test('a destination no longer offered moves to the offered one', () async {
    final preferences = MockPreferencesStore(destination: 'ml');
    final moved = HomeViewModel(
      parking,
      preferences,
      MockLocationProvider(),
      telemetry,
      connectivity,
      refreshEvery: const Duration(milliseconds: 20),
    );
    addTearDown(moved.dispose);

    await moved.load();

    expect(moved.destination, 'sd');
    expect(preferences.destination, 'sd');
  });

  test('coming back to Home asks for the free spots again', () async {
    await home.load();
    home.setVisible(true);
    final afterLoad = parking.levelCalls;

    home.setVisible(false);
    home.setVisible(true);
    await Future<void>.delayed(Duration.zero);

    expect(parking.levelCalls, afterLoad + 1);
  });

  test('while Home is on screen the counts are refreshed', () async {
    await home.load();
    home.setVisible(true);
    final afterLoad = parking.levelCalls;

    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(parking.levelCalls, greaterThanOrEqualTo(afterLoad + 2));
  });

  test('nothing is asked while Home is hidden or offline', () async {
    await home.load();
    home.setVisible(false);
    final hidden = parking.levelCalls;
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(parking.levelCalls, hidden);

    connectivity.setOnline(false);
    await Future<void>.delayed(Duration.zero);
    home.setVisible(true);
    final offline = parking.levelCalls;
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(parking.levelCalls, offline);
  });

  test('tracks the forecast when visible and when arrival time changes', () async {
    await home.load();
    expect(telemetry.named('forecast_viewed'), isEmpty);

    home.setVisible(true);
    expect(
      telemetry.named('forecast_viewed').single['source'],
      'home_forecast',
    );

    await home.load();
    expect(telemetry.named('forecast_viewed'), hasLength(1));

    await home.setArrivalTime(10, 30);
    expect(
      telemetry.named('forecast_viewed').last['source'],
      'arrival_time_changed',
    );
  });

  test('restores a saved arrival time to its next future occurrence', () {
    home = HomeViewModel(
      parking,
      MockPreferencesStore(arrivalTime: DateTime(2026, 10, 10, 10, 30)),
      MockLocationProvider(),
      telemetry,
      connectivity,
      clock: () => DateTime(2026, 10, 12, 9),
    );

    expect(home.arrivalAt, DateTime(2026, 10, 12, 10, 30));
  });

  test('prefetches each level and calculates recommendations from saved forecast', () async {
    final directory = await Directory.systemTemp.createTemp(
      'parkwise-home-forecast',
    );
    addTearDown(() => directory.delete(recursive: true));
    final arrival = DateTime(2026, 10, 12, 8, 29);
    final store = ForecastFileStore(directory);
    await store.write(arrival, [
      LevelForecast(
        code: 'P1',
        points: const [ForecastPoint(slot: '08:15', occupancy: 0.8)],
      ),
      LevelForecast(
        code: 'P2',
        points: const [ForecastPoint(slot: '08:15', occupancy: 0.4)],
      ),
    ]);

    parking = _OfflineForecastParking();
    home = HomeViewModel(
      parking,
      MockPreferencesStore(arrivalTime: arrival),
      MockLocationProvider(),
      telemetry,
      connectivity,
      forecastStore: store,
      clock: () => DateTime(2026, 10, 12, 8),
    );

    await home.load();

    expect(parking.spotCalls, 3);
    expect(home.forecastFromCache, isTrue);
    expect(home.recommendation?.slot, '08:15');
    expect(home.recommendation?.recommended, 'P2');
  });
}
