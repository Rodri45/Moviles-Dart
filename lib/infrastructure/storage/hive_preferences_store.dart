import 'package:hive_ce/hive_ce.dart';

import '../../domain/ports/preferences_store.dart';

class HivePreferencesStore implements PreferencesStore {
  HivePreferencesStore(this._box);

  static const _destinationKey = 'destination';

  static const defaultDestination = 'ml';

  final Box<String> _box;

  @override
  String get destination => _box.get(_destinationKey) ?? defaultDestination;

  @override
  Future<void> saveDestination(String buildingId) =>
      _box.put(_destinationKey, buildingId);
}
