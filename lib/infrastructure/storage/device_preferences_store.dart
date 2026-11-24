import 'package:hive_ce/hive_ce.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/voice_language.dart';
import '../../domain/ports/preferences_store.dart';

class DevicePreferencesStore implements PreferencesStore {
  DevicePreferencesStore(this._box, this._preferences);

  static const _destinationKey = 'destination';
  static const _arrivalTimeKey = 'arrival_time';
  static const _lastOpenedLevelKey = 'last_opened_level';
  static const _voiceLanguageKey = 'voice_language';
  static const defaultDestination = 'sd';

  final Box<String> _box;
  final SharedPreferences _preferences;

  @override
  String get destination => _box.get(_destinationKey) ?? defaultDestination;

  @override
  DateTime? get arrivalTime {
    final value = _preferences.getString(_arrivalTimeKey);
    return value == null ? null : DateTime.parse(value);
  }

  @override
  String? get lastOpenedLevel => _preferences.getString(_lastOpenedLevelKey);

  @override
  VoiceLanguage get voiceLanguage {
    final saved = _preferences.getString(_voiceLanguageKey);
    return VoiceLanguage.values.asNameMap()[saved] ?? VoiceLanguage.spanish;
  }

  @override
  Future<void> saveDestination(String buildingId) =>
      _box.put(_destinationKey, buildingId);

  @override
  Future<void> saveArrivalTime(DateTime arrivalTime) async {
    await _preferences.setString(
      _arrivalTimeKey,
      arrivalTime.toIso8601String(),
    );
  }

  @override
  Future<void> saveLastOpenedLevel(String levelCode) async {
    await _preferences.setString(_lastOpenedLevelKey, levelCode);
  }

  @override
  Future<void> saveVoiceLanguage(VoiceLanguage language) async {
    await _preferences.setString(_voiceLanguageKey, language.name);
  }
}
