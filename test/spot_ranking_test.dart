import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_filter.dart';
import 'package:parkwise/domain/services/spot_ranking.dart';

ParkingSpot _spot(
  String level,
  String code,
  int minutes, {
  SpotStatus status = SpotStatus.free,
  bool ev = false,
}) => ParkingSpot(
  id: '$level-$code',
  code: code,
  zone: code[0],
  levelCode: level,
  status: status,
  walkMinutes: minutes,
  isEv: ev,
);

void main() {
  final spots = [
    _spot('P2', 'A-01', 6),
    _spot('P1', 'B-02', 3, status: SpotStatus.occupied),
    _spot('P1', 'A-04', 3),
    _spot('P3', 'B-10', 8, ev: true),
    _spot('P1', 'C-01', 2, ev: true),
  ];

  test('sorts by walking minutes, then level and code', () {
    final result = rankSpots(SpotSearchInput(spots: spots));

    expect(result.results.map((s) => s.id), [
      'P1-C-01',
      'P1-A-04',
      'P1-B-02',
      'P2-A-01',
      'P3-B-10',
    ]);
    expect(result.recommended!.id, 'P1-C-01');
  });

  test('applies the filters and the search text', () {
    final result = rankSpots(
      SpotSearchInput(
        spots: spots,
        filters: {SpotFilter.available},
        query: 'p1',
      ),
    );

    expect(result.results.map((s) => s.id), ['P1-C-01', 'P1-A-04']);
  });

  test('the recommended spot respects the filters', () {
    final result = rankSpots(
      SpotSearchInput(spots: spots, filters: {SpotFilter.electric}),
    );

    expect(result.recommended!.id, 'P1-C-01');
    expect(result.results, hasLength(2));
  });

  test('the background isolate returns the same answer', () async {
    final input = SpotSearchInput(
      spots: spots,
      filters: {SpotFilter.available},
    );

    final inBackground = await rankSpotsInBackground(input);
    final inline = rankSpots(input);

    expect(
      inBackground.results.map((s) => s.id),
      inline.results.map((s) => s.id),
    );
    expect(inBackground.recommended!.id, inline.recommended!.id);
  });
}
