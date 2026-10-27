import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/cached.dart';
import 'package:parkwise/domain/entities/device_description.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_filter.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/infrastructure/mock/mock_telemetry.dart';
import 'package:parkwise/presentation/screens/level_map/level_map_view_model.dart';

class _CachedParking extends MockParkingRepository {
  @override
  Future<Cached<List<ParkingSpot>>> getSpots(
    String levelCode, {
    required String destination,
    Set<SpotFilter> filters = const {},
  }) async {
    final result = await super.getSpots(
      levelCode,
      destination: destination,
    );
    return Cached(result.data, savedAt: result.savedAt, fromCache: true);
  }
}

void main() {
  test('a visible live map reports availability and a completed map load', () async {
    final telemetry = MockTelemetry();
    final map = LevelMapViewModel(
      MockParkingRepository(),
      MockPreferencesStore(),
      telemetry,
      const DeviceDescription(model: 'Test device', osVersion: '1'),
      MockConnectivity(),
    );
    addTearDown(map.dispose);

    map.setVisible(true);
    await map.load();
    map.gridPainted();

    expect(telemetry.named('availability_viewed'), hasLength(1));
    expect(
      telemetry.named('availability_viewed').single['source'],
      'level_map',
    );
    expect(telemetry.named('map_loaded'), hasLength(1));
    expect(telemetry.named('map_loaded').single['success'], isTrue);
  });

  test('cached map data is not reported as live availability or a successful load', () async {
    final telemetry = MockTelemetry();
    final map = LevelMapViewModel(
      _CachedParking(),
      MockPreferencesStore(),
      telemetry,
      const DeviceDescription(model: 'Test device', osVersion: '1'),
      MockConnectivity(),
    );
    addTearDown(map.dispose);

    map.setVisible(true);
    await map.load();
    map.gridPainted();

    expect(telemetry.named('availability_viewed'), isEmpty);
    expect(telemetry.named('map_loaded').single['success'], isFalse);
  });
}
