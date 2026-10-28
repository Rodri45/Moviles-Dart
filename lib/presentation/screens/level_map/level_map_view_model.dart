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
    _connectivity = connectivity;
    final lastOpenedLevel = _preferences.lastOpenedLevel;
    if (levelCodes.contains(lastOpenedLevel)) {
      levelCode = lastOpenedLevel!;
    }
    watchConnectivity(connectivity, load);
  }

  static const levelCodes = ['P1', 'P2', 'P3'];

  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final Telemetry _telemetry;
  final DeviceDescription _device;
  final DateTime Function() _clock;
  late final ConnectivityPort _connectivity;
  final Duration refreshEvery;
  StreamSubscription<void>? _refreshSubscription;
  StreamSubscription<bool>? _refreshConnectivitySubscription;

  DateTime? _mapLoadStartedAt;
  bool _visible = false;
  bool _availabilityReportedForVisit = false;

  String levelCode = levelCodes.first;
  List<ParkingSpot> spots = const [];
  Set<SpotFilter> filters = {};
  ParkingSpot? selected;
  DateTime? savedAt;
  bool fromCache = false;
  bool isLoading = false;
  String? errorMessage;

  String? notice;

  bool get showOffline => !online || fromCache;

  bool get awaitingPaint => _mapLoadStartedAt != null && spots.isNotEmpty;

  String? get lastOpenedLevel => _preferences.lastOpenedLevel;

  ParkingSpot? get recommended => recommendSpot(spots, filters);

  ParkingSpot? get highlighted => selected ?? recommended;

  Map<String, List<ParkingSpot>> get zones {
    final result = <String, List<ParkingSpot>>{};
    for (final spot in spots) {
      (result[spot.zone] ??= []).add(spot);
    }
    return result;
  }

  void setVisible(bool visible) {
    _stopRefresh();
    _visible = visible;
    if (!visible) {
      _availabilityReportedForVisit = false;
      return;
    }
    if (spots.isEmpty) _mapLoadStartedAt ??= _clock();
    load(silent: true);
    _refreshSubscription = Stream<void>.periodic(refreshEvery).listen((_) {
      unawaited(load(silent: true));
    });
    _refreshConnectivitySubscription = _connectivity.changes.listen(
      _setRefreshRunning,
    );
    _connectivity.isOnline().then((online) {
      if (_visible) _setRefreshRunning(online);
    });
  }

  void _setRefreshRunning(bool online) {
    final refresh = _refreshSubscription;
    if (refresh == null) return;
    if (online && refresh.isPaused) refresh.resume();
    if (!online && !refresh.isPaused) refresh.pause();
  }

  Future<void> selectLevel(String code) async {
    if (!levelCodes.contains(code)) {
      throw ArgumentError.value(code, 'code', 'Unknown parking level');
    }
    if (code == levelCode && spots.isNotEmpty) return;
    levelCode = code;
    try {
      await _preferences.saveLastOpenedLevel(code);
    } catch (e) {
      errorMessage = errorMessageFor(e);
    }
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
      if (code != levelCode) return;
      spots = result.data;
      savedAt = result.savedAt;
      fromCache = result.fromCache;
      errorMessage = null;
      _refreshSelection();
      _reportAvailabilityViewed();
      final started = _mapLoadStartedAt;
      if (spots.isEmpty && started != null) {
        _reportMapLoad(
          started,
          success: !fromCache,
          errorType: fromCache ? 'offline_cache' : null,
        );
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

  void _reportAvailabilityViewed() {
    if (!_visible || _availabilityReportedForVisit || fromCache) return;
    _availabilityReportedForVisit = true;
    _telemetry.track('availability_viewed', {
      'source': 'level_map',
      'levelCode': levelCode,
    });
  }

  void _refreshSelection() {
    final current = selected;
    if (current == null) return;
    final fresh = spots.where((s) => s.id == current.id).firstOrNull;
    if (fresh != null && fresh.isFree) {
      selected = fresh;
      return;
    }
    selected = null;
    if (fresh == null || !fresh.mine) {
      notice = 'Spot ${current.code} was just taken. Pick another one.';
    }
  }

  @override
  void dispose() {
    _stopRefresh();
    super.dispose();
  }

  void _stopRefresh() {
    unawaited(_refreshSubscription?.cancel());
    unawaited(_refreshConnectivitySubscription?.cancel());
    _refreshSubscription = null;
    _refreshConnectivitySubscription = null;
  }
}
