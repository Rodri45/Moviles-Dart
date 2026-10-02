import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../domain/ports/auth_repository.dart';
import '../domain/ports/connectivity_port.dart';
import '../domain/ports/parking_repository.dart';
import '../domain/ports/preferences_store.dart';
import '../domain/ports/reservation_repository.dart';
import '../domain/ports/vehicle_locator.dart';
import '../infrastructure/device/connectivity_plus_adapter.dart';
import '../infrastructure/http/api_client.dart';
import '../infrastructure/http/http_auth_repository.dart';
import '../infrastructure/http/http_parking_repository.dart';
import '../infrastructure/mock/mock_auth_repository.dart';
import '../infrastructure/mock/mock_connectivity.dart';
import '../infrastructure/mock/mock_parking_repository.dart';
import '../infrastructure/mock/mock_preferences_store.dart';
import '../infrastructure/mock/mock_reservation_repository.dart';
import '../infrastructure/mock/mock_vehicle_locator.dart';
import '../infrastructure/storage/hive_preferences_store.dart';
import '../infrastructure/storage/local_cache.dart';
import '../infrastructure/storage/session_store.dart';
import '../presentation/screens/find_spot/find_spot_view_model.dart';
import '../presentation/screens/home/home_view_model.dart';
import '../presentation/screens/level_map/level_map_view_model.dart';
import '../presentation/screens/login/auth_view_model.dart';
import '../presentation/screens/no_spots/no_spots_view_model.dart';
import '../presentation/screens/offline/offline_view_model.dart';
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
    required this.preferences,
  });

  static Future<AppDependencies> create() async {
    await Hive.initFlutter();
    final cacheBox = await Hive.openBox<String>('cache');
    final prefsBox = await Hive.openBox<String>('prefs');

    final session = SessionStore();
    await session.load();
    final client = ApiClient(
      httpClient: http.Client(),
      readToken: () => session.token,
    );
    final cache = LocalCache(cacheBox);

    return AppDependencies(
      auth: HttpAuthRepository(client, session),
      parking: HttpParkingRepository(client, cache),
      reservations: MockReservationRepository(),
      vehicles: MockVehicleLocator(),
      connectivity: ConnectivityPlusAdapter(),
      preferences: HivePreferencesStore(prefsBox),
    );
  }

  factory AppDependencies.mock() => AppDependencies(
    auth: MockAuthRepository(saved: MockAuthRepository.user),
    parking: MockParkingRepository(),
    reservations: MockReservationRepository(),
    vehicles: MockVehicleLocator(),
    connectivity: MockConnectivity(),
    preferences: MockPreferencesStore(),
  );

  final AuthRepository auth;
  final ParkingRepository parking;
  final ReservationRepository reservations;
  final VehicleLocator vehicles;
  final ConnectivityPort connectivity;
  final PreferencesStore preferences;

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider(create: (_) => AuthViewModel(auth)),
    ChangeNotifierProvider(create: (_) => ShellViewModel()),
    ChangeNotifierProvider(
      create: (_) => HomeViewModel(parking, preferences, connectivity),
    ),
    ChangeNotifierProvider(
      create: (_) => LevelMapViewModel(parking, preferences, connectivity),
    ),
    ChangeNotifierProvider(
      create: (_) => FindSpotViewModel(parking, preferences, connectivity),
    ),
    ChangeNotifierProvider(
      create: (_) =>
          OfflineViewModel(parking, reservations, preferences, connectivity),
    ),
    ChangeNotifierProvider(create: (_) => NoSpotsViewModel(parking)),
    ChangeNotifierProvider(create: (_) => ProfileViewModel(reservations)),
  ];
}
