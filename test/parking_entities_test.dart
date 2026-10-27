import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/parking_level.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';

void main() {
  test('parking level separates unavailable spots from usable capacity', () {
    final level = ParkingLevel.fromJson({
      'code': 'P1',
      'name': 'Level P1',
      'underground': false,
      'total': 58,
      'free': 40,
      'reserved': 5,
      'occupied': 13,
      'disabled': 2,
    });

    expect(level.total, level.free + level.reserved + level.occupied);
    expect(level.physicalTotal, 60);
    expect(level.occupancy, 18 / 58);
  });

  test('parking level accepts cached summaries without disabled count', () {
    final level = ParkingLevel.fromJson({
      'code': 'P1',
      'name': 'Level P1',
      'underground': false,
      'total': 60,
      'free': 52,
      'reserved': 0,
      'occupied': 8,
    });

    expect(level.disabled, 0);
    expect(level.physicalTotal, level.total);
  });

  test('parking spot parser rejects unknown statuses', () {
    expect(
      () => ParkingSpot.fromJson({
        'id': 'P1-A-01',
        'code': 'A-01',
        'zone': 'A',
        'levelCode': 'P1',
        'status': 'unknown',
        'walkMinutes': 2,
      }),
      throwsFormatException,
    );
  });

  test('parking spot parser preserves the unavailable status', () {
    final spot = ParkingSpot.fromJson({
      'id': 'P1-A-01',
      'code': 'A-01',
      'zone': 'A',
      'levelCode': 'P1',
      'status': 'disabled',
      'walkMinutes': 2,
    });

    expect(spot.status, SpotStatus.disabled);
  });
}
