import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/cached.dart';
import 'package:parkwise/domain/entities/levels_overview.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_location_provider.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/presentation/screens/home/home_view_model.dart';

class _CountingParking extends MockParkingRepository {
  int levelCalls = 0;

  @override
  Future<Cached<LevelsOverview>> getLevels({String? zone}) {
    levelCalls++;
    return super.getLevels(zone: zone);
  }
}

void main() {
  late _CountingParking parking;
  late MockConnectivity connectivity;
  late HomeViewModel home;

  setUp(() {
    parking = _CountingParking();
    connectivity = MockConnectivity();
    home = HomeViewModel(
      parking,
      MockPreferencesStore(),
      MockLocationProvider(),
      connectivity,
      refreshEvery: const Duration(milliseconds: 20),
    );
  });

  tearDown(() => home.dispose());

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
}
