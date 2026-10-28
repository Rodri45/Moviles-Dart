import 'package:hive_ce/hive_ce.dart';

import '../../domain/ports/preferences_store.dart';

class HivePreferencesStore implements PreferencesStore {
  HivePreferencesStore(this._box);

  static const _destinationKey = 'destination';
  static const _arrivalTimeKey = 'arrival_time';
  static const _lastOpenedLevelKey = 'last_opened_level';

  static const defaultDestination = 'ml';

  final Box<String> _box;

  @override
  String get destination => _box.get(_destinationKey) ?? defaultDestination;

  @override
  DateTime? get arrivalTime {
    final value = _box.get(_arrivalTimeKey);
    return value == null ? null : DateTime.parse(value);
  }

  @override
  String? get lastOpenedLevel => _box.get(_lastOpenedLevelKey);

  @override
  Future<void> saveDestination(String buildingId) =>
      _box.put(_destinationKey, buildingId);

  @override
  Future<void> saveArrivalTime(DateTime arrivalTime) =>
      _box.put(_arrivalTimeKey, arrivalTime.toIso8601String());

  @override
  Future<void> saveLastOpenedLevel(String levelCode) =>
      _box.put(_lastOpenedLevelKey, levelCode);
}
