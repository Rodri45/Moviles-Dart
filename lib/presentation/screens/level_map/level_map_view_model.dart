import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/spot_filter.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/services/recommend_spot.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';

// el mapa de un nivel. se refresca cada 5 s solo mientras se esta viendo
class LevelMapViewModel extends ChangeNotifier with ConnectivityAware {
  LevelMapViewModel(
    this._parking,
    this._preferences,
    ConnectivityPort connectivity, {
    this.refreshEvery = const Duration(seconds: 5),
  }) {
    watchConnectivity(connectivity, load);
  }

  static const levelCodes = ['P1', 'P2', 'P3'];

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final Duration refreshEvery;
  Timer? _timer;

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
    await load();
  }

  void toggleFilter(SpotFilter filter) {
    filters = filters.contains(filter)
        ? ({...filters}..remove(filter))
        : {...filters, filter};
    notifyListeners();
  }

  void selectSpot(ParkingSpot spot) {
    selected = spot;
    notice = null;
    notifyListeners();
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
    } catch (e) {
      if (code == levelCode) errorMessage = errorMessageFor(e);
    } finally {
      if (code == levelCode) isLoading = false;
      notifyListeners();
    }
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
