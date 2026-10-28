import 'dart:io';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/device_description.dart';
import '../domain/ports/auth_repository.dart';
import '../domain/ports/connectivity_port.dart';
import '../domain/ports/directions_launcher.dart';
import '../domain/ports/form_draft_store.dart';
import '../domain/ports/location_provider.dart';
import '../domain/ports/lot_redirect_store.dart';
import '../domain/ports/nearby_lot_repository.dart';
import '../domain/ports/parking_repository.dart';
import '../domain/ports/preferences_store.dart';
import '../domain/ports/reservation_outbox.dart';
import '../domain/ports/reservation_repository.dart';
import '../domain/ports/telemetry.dart';
import '../domain/ports/vehicle_locator.dart';
import '../domain/services/spot_ranking.dart';
import '../infrastructure/device/connectivity_plus_adapter.dart';
import '../infrastructure/device/device_info_reader.dart';
import '../infrastructure/device/geolocator_location_provider.dart';
import '../infrastructure/device/url_launcher_directions.dart';
import '../infrastructure/http/api_client.dart';
import '../infrastructure/http/cached_nearby_lot_repository.dart';
import '../infrastructure/http/http_auth_repository.dart';
import '../infrastructure/http/http_parking_repository.dart';
import '../infrastructure/http/http_reservation_repository.dart';
import '../infrastructure/http/http_vehicle_locator.dart';
import '../infrastructure/http/outbox_reservation_repository.dart';
import '../infrastructure/http/telemetry_client.dart';
import '../infrastructure/mock/memory_lot_redirect_store.dart';
import '../infrastructure/mock/memory_nearby_lot_store.dart';
import '../infrastructure/mock/mock_auth_repository.dart';
import '../infrastructure/mock/mock_connectivity.dart';
import '../infrastructure/mock/mock_directions_launcher.dart';
import '../infrastructure/mock/mock_form_draft_store.dart';
import '../infrastructure/mock/mock_location_provider.dart';
import '../infrastructure/mock/mock_parking_repository.dart';
import '../infrastructure/mock/mock_preferences_store.dart';
import '../infrastructure/mock/mock_reservation_outbox.dart';
import '../infrastructure/mock/mock_reservation_repository.dart';
import '../infrastructure/mock/mock_telemetry.dart';
import '../infrastructure/mock/mock_vehicle_locator.dart';
import '../infrastructure/storage/hive_form_draft_store.dart';
import '../infrastructure/storage/local_cache.dart';
import '../infrastructure/storage/local_database.dart';
import '../infrastructure/storage/car_location_file_store.dart';
import '../infrastructure/storage/device_preferences_store.dart';
import '../infrastructure/storage/forecast_file_store.dart';
import '../infrastructure/storage/reservation_history_store.dart';
import '../infrastructure/storage/session_store.dart';
import '../infrastructure/storage/sqlite_lot_redirect_store.dart';
import '../infrastructure/storage/sqlite_nearby_lot_store.dart';
import '../infrastructure/storage/sqlite_pending_action_store.dart';
import '../presentation/screens/find_my_car/find_my_car_view_model.dart';
import '../presentation/screens/find_spot/find_spot_view_model.dart';
import '../presentation/screens/home/home_view_model.dart';
import '../presentation/screens/level_map/level_map_view_model.dart';
import '../presentation/screens/login/auth_view_model.dart';
import '../presentation/screens/no_spots/lot_arrival_view_model.dart';
import '../presentation/screens/no_spots/no_spots_view_model.dart';
import '../presentation/screens/offline/offline_view_model.dart';
import '../presentation/screens/profile/profile_view_model.dart';
import '../presentation/screens/reserve/reserve_view_model.dart';
import '../presentation/shell/shell_view_model.dart';

class AppDependencies {
  AppDependencies({
    required this.auth,
    required this.parking,
    required this.reservations,
    required this.vehicles,
    required this.connectivity,
    required this.preferences,
    required this.location,
    required this.directions,
    required this.telemetry,
    required this.device,
    required this.outbox,
    required this.drafts,
    required this.spotRanker,
    required this.nearbyLots,
    required this.lotRedirects,
    this.forecastStore,
  });

  static Future<AppDependencies> create() async {
    await Hive.initFlutter();
    final cacheBox = await Hive.openBox<String>('cache');
    final prefsBox = await Hive.openBox<String>('prefs');
    final telemetryBox = await Hive.openBox<String>('telemetry');
    final draftsBox = await Hive.openBox<String>('drafts');
    final database = await LocalDatabase.open();
    final historyStore = ReservationHistoryStore(database);
    final supportDirectory = await getApplicationSupportDirectory();
    final sharedPreferences = await SharedPreferences.getInstance();
    final carLocationStore = CarLocationFileStore(
      File(path.join(supportDirectory.path, 'parked_vehicle.json')),
    );
    final forecastStore = ForecastFileStore(supportDirectory);

    final session = SessionStore();
    await session.load();
    final client = ApiClient(
      httpClient: http.Client(),
      readToken: () => session.token,
    );
    final cache = LocalCache(cacheBox);
    final connectivity = ConnectivityPlusAdapter();
    final telemetry = TelemetryClient(client, telemetryBox, connectivity)
      ..flush();
    final httpReservations = HttpReservationRepository(
      client,
      cache,
      historyStore,
      () => session.user?.id,
    );
    final reservations = OutboxReservationRepository(
      httpReservations,
      SqlitePendingActionStore(database),
      connectivity,
      remember: httpReservations.remember,
    )..flush();
    final parking = HttpParkingRepository(client, cache);

    return AppDependencies(
      auth: HttpAuthRepository(
        client,
        session,
        cache,
        historyStore,
        carLocationStore,
      ),
      parking: parking,
      nearbyLots: CachedNearbyLotRepository(
        parking,
        SqliteNearbyLotStore(database),
      ),
      lotRedirects: SqliteLotRedirectStore(database),
      reservations: reservations,
      outbox: reservations,
      drafts: HiveFormDraftStore(draftsBox),
      spotRanker: rankSpotsInBackground,
      vehicles: HttpVehicleLocator(client, carLocationStore),
      connectivity: connectivity,
      preferences: DevicePreferencesStore(prefsBox, sharedPreferences),
      location: GeolocatorLocationProvider(),
      directions: UrlLauncherDirections(),
      telemetry: telemetry,
      device: await readDeviceDescription(),
      forecastStore: forecastStore,
    );
  }

  factory AppDependencies.mock() {
    final parking = MockParkingRepository();
    return AppDependencies(
      auth: MockAuthRepository(saved: MockAuthRepository.user),
      parking: parking,
      nearbyLots: CachedNearbyLotRepository(parking, MemoryNearbyLotStore()),
      lotRedirects: MemoryLotRedirectStore(),
      reservations: MockReservationRepository(),
      vehicles: MockVehicleLocator(),
      connectivity: MockConnectivity(),
      preferences: MockPreferencesStore(),
      location: MockLocationProvider(),
      directions: MockDirectionsLauncher(),
      telemetry: MockTelemetry(),
      device: const DeviceDescription(model: 'Test phone', osVersion: '15'),
      outbox: MockReservationOutbox(),
      drafts: MockFormDraftStore(),
      spotRanker: rankSpotsInline,
    );
  }

  final AuthRepository auth;
  final ParkingRepository parking;
  final ReservationRepository reservations;
  final VehicleLocator vehicles;
  final ConnectivityPort connectivity;
  final PreferencesStore preferences;
  final LocationProvider location;
  final DirectionsLauncher directions;
  final Telemetry telemetry;
  final DeviceDescription device;
  final ReservationOutbox outbox;
  final FormDraftStore drafts;
  final SpotRanker spotRanker;
  final NearbyLotRepository nearbyLots;
  final LotRedirectStore lotRedirects;
  final ForecastFileStore? forecastStore;

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(
        auth,
        telemetry,
        connectivity: connectivity,
        drafts: drafts,
        onSignedOut: outbox.clear,
      ),
    ),
    ChangeNotifierProvider(create: (_) => ShellViewModel()),
    ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        parking,
        preferences,
        location,
        telemetry,
        connectivity,
        forecastStore: forecastStore,
      ),
    ),
    ChangeNotifierProvider(
      create: (_) => LevelMapViewModel(
        parking,
        preferences,
        telemetry,
        device,
        connectivity,
      ),
    ),
    ChangeNotifierProvider(
      create: (_) => FindSpotViewModel(
        parking,
        preferences,
        telemetry,
        connectivity,
        rank: spotRanker,
      ),
    ),
    ChangeNotifierProvider(
      create: (_) =>
          OfflineViewModel(parking, reservations, preferences, connectivity),
    ),
    ChangeNotifierProvider(
      create: (_) =>
          NoSpotsViewModel(parking, nearbyLots, directions, connectivity),
    ),
    ChangeNotifierProvider(
      create: (_) => LotArrivalViewModel(lotRedirects, telemetry),
    ),
    ChangeNotifierProvider(
      create: (_) => FindMyCarViewModel(vehicles, location, outbox),
    ),
    ChangeNotifierProvider(
      create: (_) => ReserveViewModel(
        reservations,
        vehicles,
        location,
        connectivity,
        telemetry: telemetry,
        outbox: outbox,
      ),
    ),
    ChangeNotifierProvider(create: (_) => ProfileViewModel(reservations)),
  ];
}
