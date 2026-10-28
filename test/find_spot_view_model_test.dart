import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/spot_filter.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/infrastructure/mock/mock_telemetry.dart';
import 'package:parkwise/presentation/screens/find_spot/find_spot_view_model.dart';

void main() {
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
    final telemetry = MockTelemetry();
    final finder = FindSpotViewModel(
      MockParkingRepository(),
      MockPreferencesStore(),
      telemetry,
      MockConnectivity(),
    );
    addTearDown(finder.dispose);

    await finder.load();

    expect(telemetry.named('availability_viewed'), hasLength(1));
    expect(
      telemetry.named('availability_viewed').single['source'],
      'find_spot',
    );
  });
}
