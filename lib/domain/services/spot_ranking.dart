import 'dart:isolate';

import '../entities/parking_spot.dart';
import '../entities/spot_filter.dart';
import 'recommend_spot.dart';

class SpotSearchInput {
  const SpotSearchInput({
    required this.spots,
    this.filters = const {},
    this.query = '',
  });

  final List<ParkingSpot> spots;
  final Set<SpotFilter> filters;
  final String query;
}

class SpotSearchResult {
  const SpotSearchResult({required this.results, this.recommended});

  static const empty = SpotSearchResult(results: []);

  final List<ParkingSpot> results;
  final ParkingSpot? recommended;
}

typedef SpotRanker = Future<SpotSearchResult> Function(SpotSearchInput input);

SpotSearchResult rankSpots(SpotSearchInput input) {
  final text = input.query.trim().toLowerCase();
  final results =
      input.spots
          .where((spot) => input.filters.every((f) => f.matches(spot)))
          .where(
            (spot) =>
                text.isEmpty ||
                '${spot.levelCode} ${spot.zone} ${spot.code}'
                    .toLowerCase()
                    .contains(text),
          )
          .toList()
        ..sort((a, b) {
          final byWalk = a.walkMinutes.compareTo(b.walkMinutes);
          if (byWalk != 0) return byWalk;
          final byLevel = a.levelCode.compareTo(b.levelCode);
          return byLevel != 0 ? byLevel : a.code.compareTo(b.code);
        });
  return SpotSearchResult(
    results: results,
    recommended: recommendSpot(results, input.filters),
  );
}

Future<SpotSearchResult> rankSpotsInBackground(SpotSearchInput input) =>
    Isolate.run(() => rankSpots(input), debugName: 'spot-ranking');

Future<SpotSearchResult> rankSpotsInline(SpotSearchInput input) async =>
    rankSpots(input);
