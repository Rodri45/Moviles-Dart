import '../entities/parking_spot.dart';
import '../entities/spot_filter.dart';

ParkingSpot? recommendSpot(
  Iterable<ParkingSpot> spots, [
  Set<SpotFilter> filters = const {},
]) {
  ParkingSpot? best;
  for (final spot in spots) {
    if (!spot.isFree || !filters.every((f) => f.matches(spot))) continue;
    if (best == null || spot.walkMinutes < best.walkMinutes) best = spot;
  }
  return best;
}
