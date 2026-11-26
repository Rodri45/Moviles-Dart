import '../entities/voice_language.dart';

abstract interface class PreferencesStore {
  String get destination;

  DateTime? get arrivalTime;

  String? get lastOpenedLevel;

  VoiceLanguage get voiceLanguage;

  String? get lastReportKind;

  Future<void> saveDestination(String buildingId);

  Future<void> saveArrivalTime(DateTime arrivalTime);

  Future<void> saveLastOpenedLevel(String levelCode);

  Future<void> saveVoiceLanguage(VoiceLanguage language);

  Future<void> saveLastReportKind(String kind);
}
