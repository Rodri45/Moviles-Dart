import 'parking_spot.dart';

enum SpotFilter {
  available,
  vip,
  electric,
  accessible;

  bool matches(ParkingSpot spot) => switch (this) {
    SpotFilter.available => spot.isFree,
    SpotFilter.vip => spot.isVip,
    SpotFilter.electric => spot.isEv,
    SpotFilter.accessible => spot.isAccessible,
  };
}
