import 'parking_spot.dart';

// los filtros de puestos. el name es el mismo que pide la telemetria
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
