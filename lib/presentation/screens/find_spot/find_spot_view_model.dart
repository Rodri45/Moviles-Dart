import 'package:flutter/foundation.dart';

import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/spot_filter.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/telemetry.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';
import '../level_map/level_map_view_model.dart';

// lista de puestos de todos los niveles con filtros, ordenada por minutos
class FindSpotViewModel extends ChangeNotifier with ConnectivityAware {
  FindSpotViewModel(
    this._parking,
    this._preferences,
    this._telemetry,
    ConnectivityPort connectivity,
  ) {
    watchConnectivity(connectivity, load);
  }

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final Telemetry _telemetry;

  Set<SpotFilter> filters = {SpotFilter.available};
  String query = '';
  List<ParkingSpot> _spots = const [];
  DateTime? savedAt;
  bool fromCache = false;
  bool isLoading = false;
  String? errorMessage;

  bool get showOffline => !online || fromCache;

  List<ParkingSpot> get results {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return _spots;
    return _spots
        .where(
          (s) =>
              '${s.levelCode} ${s.zone} ${s.code}'.toLowerCase().contains(text),
        )
        .toList();
  }

  Future<void> toggleFilter(SpotFilter filter) async {
    if (filters.contains(filter)) {
      filters = {...filters}..remove(filter);
    } else {
      filters = {...filters, filter};
      _telemetry.track('filter_applied', {'filter': filter.name});
    }
    await load();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final requested = filters;
    try {
      final perLevel = await Future.wait([
        for (final code in LevelMapViewModel.levelCodes)
          _parking.getSpots(
            code,
            destination: _preferences.destination,
            filters: requested,
          ),
      ]);
      // si cambiaron los filtros mientras cargaba se descarta
      if (requested != filters) return;
      _spots = [for (final level in perLevel) ...level.data]
        ..sort((a, b) => a.walkMinutes.compareTo(b.walkMinutes));
      fromCache = perLevel.any((level) => level.fromCache);
      savedAt = perLevel
          .map((level) => level.savedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
    } catch (e) {
      errorMessage = errorMessageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
