import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/device_description.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/spot_filter.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/telemetry.dart';
import '../../../domain/services/recommend_spot.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';

// el mapa de un nivel. se refresca cada 5 s solo mientras se esta viendo
class LevelMapViewModel extends ChangeNotifier with ConnectivityAware {
  LevelMapViewModel(
    this._parking,
    this._preferences,
    this._telemetry,
    this._device,
    ConnectivityPort connectivity, {
    this.refreshEvery = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    watchConnectivity(connectivity, load);
  }

  static const levelCodes = ['P1', 'P2', 'P3'];

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final Telemetry _telemetry;
  final DeviceDescription _device;
  final DateTime Function() _clock;
  final Duration refreshEvery;
  Timer? _timer;

  // BQ1: desde que se elige el nivel hasta que la cuadricula se pinta
  DateTime? _mapLoadStartedAt;

  String levelCode = levelCodes.first;
  List<ParkingSpot> spots = const [];
  Set<SpotFilter> filters = {};
  ParkingSpot? selected;
  DateTime? savedAt;
  bool fromCache = false;
  bool isLoading = false;
  String? errorMessage;

  // aviso cuando el puesto elegido se lo gano otra persona
  String? notice;

  bool get showOffline => !online || fromCache;

  // la pantalla avisa con gridPainted cuando ya dibujo los puestos
  bool get awaitingPaint => _mapLoadStartedAt != null && spots.isNotEmpty;

  ParkingSpot? get recommended => recommendSpot(spots, filters);

  // la hoja de abajo muestra el elegido o, si no hay, el recomendado
  ParkingSpot? get highlighted => selected ?? recommended;

  // los puestos agrupados por zona, en el orden que manda el backend
  Map<String, List<ParkingSpot>> get zones {
    final result = <String, List<ParkingSpot>>{};
    for (final spot in spots) {
      (result[spot.zone] ??= []).add(spot);
    }
    return result;
  }

  void setVisible(bool visible) {
    _timer?.cancel();
    _timer = null;
    if (!visible) return;
    load(silent: true);
    _timer = Timer.periodic(refreshEvery, (_) => load(silent: true));
  }

  Future<void> selectLevel(String code) async {
    if (code == levelCode && spots.isNotEmpty) return;
    levelCode = code;
    spots = const [];
    selected = null;
    _mapLoadStartedAt = _clock();
    await load();
  }

  void toggleFilter(SpotFilter filter) {
    if (filters.contains(filter)) {
      filters = {...filters}..remove(filter);
    } else {
      filters = {...filters, filter};
      _telemetry.track('filter_applied', {'filter': filter.name});
    }
    notifyListeners();
  }

  void selectSpot(ParkingSpot spot) {
    selected = spot;
    notice = null;
    _telemetry.track('walking_time_viewed', {
      'spotCode': spot.code,
      'levelCode': spot.levelCode,
      'minutes': spot.walkMinutes,
      'source': 'level_map',
    });
    notifyListeners();
  }

  void gridPainted() {
    final started = _mapLoadStartedAt;
    if (started == null) return;
    _reportMapLoad(
      started,
      success: !fromCache,
      errorType: fromCache ? 'offline_cache' : null,
    );
  }

  void clearSelection() {
    selected = null;
    notifyListeners();
  }

  // silent es para el refresco de cada 5 s: no muestra el loader
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }
    final code = levelCode;
    try {
      final result = await _parking.getSpots(
        code,
        destination: _preferences.destination,
      );
      // si cambiaron de nivel mientras cargaba, esta respuesta ya no sirve
      if (code != levelCode) return;
      spots = result.data;
      savedAt = result.savedAt;
      fromCache = result.fromCache;
      errorMessage = null;
      _refreshSelection();
      // un nivel sin puestos no pinta nada, se reporta de una vez
      final started = _mapLoadStartedAt;
      if (spots.isEmpty && started != null) {
        _reportMapLoad(started, success: true);
      }
    } catch (e) {
      if (code != levelCode) return;
      errorMessage = errorMessageFor(e);
      final started = _mapLoadStartedAt;
      if (started != null) {
        _reportMapLoad(started, success: false, errorType: errorTypeFor(e));
      }
    } finally {
      if (code == levelCode) isLoading = false;
      notifyListeners();
    }
  }

  void _reportMapLoad(
    DateTime started, {
    required bool success,
    String? errorType,
  }) {
    _mapLoadStartedAt = null;
    _telemetry.track('map_loaded', {
      'levelCode': levelCode,
      'durationMs': _clock().difference(started).inMilliseconds,
      'success': success,
      'errorType': ?errorType,
      ..._device.toProperties(),
    });
  }

  void _refreshSelection() {
    final current = selected;
    if (current == null) return;
    final fresh = spots.where((s) => s.id == current.id).firstOrNull;
    if (fresh != null && fresh.isFree) {
      selected = fresh;
    } else {
      selected = null;
      notice = 'Spot ${current.code} was just taken. Pick another one.';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
