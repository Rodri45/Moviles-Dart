import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/infrastructure/mock/mock_telemetry.dart';
import 'package:parkwise/presentation/screens/find_spot/find_spot_view_model.dart';

void main() {
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
