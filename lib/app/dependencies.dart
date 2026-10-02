import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../domain/ports/connectivity_port.dart';
import '../domain/ports/parking_repository.dart';
import '../domain/ports/reservation_repository.dart';
import '../domain/ports/vehicle_locator.dart';
import '../infrastructure/mock/mock_connectivity.dart';
import '../infrastructure/mock/mock_parking_repository.dart';
import '../infrastructure/mock/mock_reservation_repository.dart';
import '../infrastructure/mock/mock_vehicle_locator.dart';

// aqui se arma todo lo que usa la app. las pantallas solo ven los puertos
class AppDependencies {
  AppDependencies({
    required this.parking,
    required this.reservations,
    required this.vehicles,
    required this.connectivity,
  });

  factory AppDependencies.mock() => AppDependencies(
    parking: MockParkingRepository(),
    reservations: MockReservationRepository(),
    vehicles: MockVehicleLocator(),
    connectivity: MockConnectivity(),
  );

  final ParkingRepository parking;
  final ReservationRepository reservations;
  final VehicleLocator vehicles;
  final ConnectivityPort connectivity;

  List<SingleChildWidget> get providers => [
    Provider<ParkingRepository>.value(value: parking),
    Provider<ReservationRepository>.value(value: reservations),
    Provider<VehicleLocator>.value(value: vehicles),
    Provider<ConnectivityPort>.value(value: connectivity),
  ];
}
