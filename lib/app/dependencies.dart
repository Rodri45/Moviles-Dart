import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../domain/ports/auth_repository.dart';
import '../domain/ports/connectivity_port.dart';
import '../domain/ports/parking_repository.dart';
import '../domain/ports/reservation_repository.dart';
import '../domain/ports/vehicle_locator.dart';
import '../infrastructure/http/api_client.dart';
import '../infrastructure/http/http_auth_repository.dart';
import '../infrastructure/mock/mock_auth_repository.dart';
import '../infrastructure/mock/mock_connectivity.dart';
import '../infrastructure/mock/mock_parking_repository.dart';
import '../infrastructure/mock/mock_reservation_repository.dart';
import '../infrastructure/mock/mock_vehicle_locator.dart';
import '../infrastructure/storage/session_store.dart';
import '../presentation/screens/login/auth_view_model.dart';
import '../presentation/screens/profile/profile_view_model.dart';
import '../presentation/shell/shell_view_model.dart';

// aqui se arma todo lo que usa la app. los view models solo reciben puertos,
// asi en las pruebas se cambian por los mocks
class AppDependencies {
  AppDependencies({
    required this.auth,
    required this.parking,
    required this.reservations,
    required this.vehicles,
    required this.connectivity,
  });

  static Future<AppDependencies> create() async {
    final session = SessionStore();
    await session.load();
    final client = ApiClient(
      httpClient: http.Client(),
      readToken: () => session.token,
    );

    return AppDependencies(
      auth: HttpAuthRepository(client, session),
      parking: MockParkingRepository(),
      reservations: MockReservationRepository(),
      vehicles: MockVehicleLocator(),
      connectivity: MockConnectivity(),
    );
  }

  factory AppDependencies.mock() => AppDependencies(
    auth: MockAuthRepository(saved: MockAuthRepository.user),
    parking: MockParkingRepository(),
    reservations: MockReservationRepository(),
    vehicles: MockVehicleLocator(),
    connectivity: MockConnectivity(),
  );

  final AuthRepository auth;
  final ParkingRepository parking;
  final ReservationRepository reservations;
  final VehicleLocator vehicles;
  final ConnectivityPort connectivity;

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider(create: (_) => AuthViewModel(auth)),
    ChangeNotifierProvider(create: (_) => ShellViewModel()),
    ChangeNotifierProvider(create: (_) => ProfileViewModel(reservations)),
  ];
}
