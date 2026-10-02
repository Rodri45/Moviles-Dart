import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/levels_overview.dart';
import 'package:parkwise/infrastructure/mock/mock_directions_launcher.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/parking_mock_data.dart';
import 'package:parkwise/presentation/screens/no_spots/no_spots_view_model.dart';

LevelsOverview campus({required bool full}) => LevelsOverview(
  generatedAt: ParkingMockData.now,
  campusFull: full,
  levels: ParkingMockData.levels.levels,
);

void main() {
  late MockParkingRepository parking;
  late MockDirectionsLauncher directions;
  late NoSpotsViewModel noSpots;

  setUp(() {
    parking = MockParkingRepository(levels: campus(full: true));
    directions = MockDirectionsLauncher();
    noSpots = NoSpotsViewModel(
      parking,
      directions,
      checkEvery: const Duration(milliseconds: 10),
    );
  });

  tearDown(() => noSpots.dispose());

  test('nearby lots come closest first', () async {
    await noSpots.load();

    expect(noSpots.lots.map((lot) => lot.id), ['nearby-1', 'nearby-2']);
    expect(noSpots.closestId, 'nearby-1');
  });

  test('navigate opens the lot in the maps app', () async {
    await noSpots.load();

    expect(await noSpots.navigate(noSpots.lots.first), isTrue);
    expect(directions.opened.single, contains('Park Central'));
  });

  test('notify me keeps checking while the campus is full', () async {
    noSpots.toggleNotify();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(noSpots.watching, isTrue);
    expect(noSpots.campusOpened, isFalse);
  });

  test('notify me fires when a spot opens and stops checking', () async {
    noSpots.toggleNotify();
    parking.levels = campus(full: false);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(noSpots.campusOpened, isTrue);
    expect(noSpots.watching, isFalse);
  });

  test('tapping notify me again turns it off', () {
    noSpots
      ..toggleNotify()
      ..toggleNotify();

    expect(noSpots.watching, isFalse);
  });
}
