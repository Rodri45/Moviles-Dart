import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/cached.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_filter.dart';
import 'package:parkwise/domain/services/spot_ranking.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/infrastructure/mock/mock_telemetry.dart';
import 'package:parkwise/presentation/screens/find_spot/find_spot_view_model.dart';

class _CountingParking extends MockParkingRepository {
  int calls = 0;

  @override
  Future<Cached<List<ParkingSpot>>> getSpots(
    String levelCode, {
    required String destination,
    Set<SpotFilter> filters = const {},
  }) {
    calls++;
    return super.getSpots(
      levelCode,
      destination: destination,
      filters: filters,
    );
  }
}

void main() {
  late DateTime now;
  late _CountingParking parking;
  late MockTelemetry telemetry;
  late FindSpotViewModel finder;

  setUp(() {
    now = DateTime(2026, 10, 26, 8);
    parking = _CountingParking();
    telemetry = MockTelemetry();
    finder = FindSpotViewModel(
      parking,
      MockPreferencesStore(),
      telemetry,
      MockConnectivity(),
      rank: rankSpotsInline,
      clock: () => now,
    );
  });

  tearDown(() => finder.dispose());

  test('a filter combination seen 30 s ago is served from memory', () async {
    await finder.load();
    final askedLevels = parking.calls;

    await finder.toggleFilter(SpotFilter.electric);
    await finder.toggleFilter(SpotFilter.electric);

    expect(parking.calls, askedLevels * 2);
    expect(finder.fromMemory, isTrue);
  });

  test('after the time to live the levels are asked again', () async {
    await finder.load();
    final askedLevels = parking.calls;

    now = now.add(const Duration(seconds: 31));
    await finder.load();

    expect(parking.calls, askedLevels * 2);
    expect(finder.fromMemory, isFalse);
  });

  test('pull to refresh skips the memory', () async {
    await finder.load();
    final askedLevels = parking.calls;

    await finder.refresh();

    expect(parking.calls, askedLevels * 2);
  });

  test('the recommended spot is free and the closest on foot', () async {
    await finder.load();

    final best = finder.recommended!;
    expect(best.isFree, isTrue);
    expect(
      finder.results.where((s) => s.isFree).every(
        (s) => s.walkMinutes >= best.walkMinutes,
      ),
      isTrue,
    );
  });

  test('opening a new search resets the previous filter and query', () async {
    final finder = FindSpotViewModel(
      MockParkingRepository(),
      MockPreferencesStore(),
      MockTelemetry(),
      MockConnectivity(),
    );
    addTearDown(finder.dispose);

    await finder.setFilters({SpotFilter.available, SpotFilter.electric});
    finder.setQuery('P3');
    await finder.setFilters({SpotFilter.available});

    expect(finder.query, isEmpty);
    expect(finder.filters, {SpotFilter.available});
    expect(finder.results, isNotEmpty);
    expect(finder.results.every((spot) => spot.isFree), isTrue);
  });

  test(
    'a special-spots entry applies only its requested special filter',
    () async {
      final finder = FindSpotViewModel(
        MockParkingRepository(),
        MockPreferencesStore(),
        MockTelemetry(),
        MockConnectivity(),
      );
      addTearDown(finder.dispose);

      await finder.setFilters({SpotFilter.available, SpotFilter.accessible});

      expect(finder.filters, {SpotFilter.available, SpotFilter.accessible});
      expect(
        finder.results.every((spot) => spot.isFree && spot.isAccessible),
        isTrue,
      );
    },
  );

  test('a successful live spot search reports availability viewed', () async {
    await finder.load();

    expect(telemetry.named('availability_viewed'), hasLength(1));
    expect(
      telemetry.named('availability_viewed').single['source'],
      'find_spot',
    );
  });

  test('a list served from memory is not counted twice', () async {
    await finder.load();
    await finder.toggleFilter(SpotFilter.electric);
    await finder.toggleFilter(SpotFilter.electric);

    expect(finder.fromMemory, isTrue);
    expect(telemetry.named('availability_viewed'), hasLength(2));
  });
}
