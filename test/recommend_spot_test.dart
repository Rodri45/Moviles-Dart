import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/geo_point.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_filter.dart';
import 'package:parkwise/domain/services/recommend_spot.dart';

ParkingSpot _spot(
  String code,
  int minutes, {
  SpotStatus status = SpotStatus.free,
  bool ev = false,
}) => ParkingSpot(
  id: 'P1-$code',
  code: code,
  zone: code[0],
  levelCode: 'P1',
  status: status,
  walkMinutes: minutes,
  isEv: ev,
);

void main() {
  final spots = [
    _spot('A-01', 1, status: SpotStatus.occupied),
    _spot('A-02', 2, status: SpotStatus.reserved),
    _spot('B-01', 4),
    _spot('B-02', 3),
    _spot('C-01', 5, ev: true),
  ];

  test('picks the free spot with the fewest walking minutes', () {
    expect(recommendSpot(spots)!.code, 'B-02');
  });

  test('only considers spots that match the chosen filter', () {
    expect(recommendSpot(spots, {SpotFilter.electric})!.code, 'C-01');
  });

  test('returns null when nothing free matches', () {
    expect(recommendSpot(spots, {SpotFilter.vip}), isNull);
    expect(
      recommendSpot([_spot('A-01', 1, status: SpotStatus.occupied)]),
      isNull,
    );
  });

  test('BQ4 zone rounds the position to 2 decimals', () {
    expect(const GeoPoint(4.60183, -74.06598).toZone(), '4.60,-74.07');
  });
}
