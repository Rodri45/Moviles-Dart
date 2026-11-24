import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/building.dart';
import '../../../domain/entities/voice_language.dart';
import '../../../domain/entities/voice_query.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/speech_recognizer.dart';
import '../../../domain/services/voice_query_parser.dart';
import '../../shared/connectivity_aware.dart';

enum VoiceStatus { ready, listening, notUnderstood, failed }

sealed class VoiceSearchOutcome {
  const VoiceSearchOutcome();
}

final class PhraseSearch extends VoiceSearchOutcome {
  const PhraseSearch(this.phrase, this.query, {required this.spoken});

  final String phrase;
  final VoiceQuery query;
  final bool spoken;
}

final class TypeInstead extends VoiceSearchOutcome {
  const TypeInstead(this.words);

  final String words;
}

class VoiceSearchViewModel extends ChangeNotifier with ConnectivityAware {
  VoiceSearchViewModel(
    this._speech,
    this._parking,
    this._preferences,
    ConnectivityPort connectivity, {
    this._interpret = interpretPhraseInBackground,
  }) {
    watchConnectivity(connectivity, _loadDestination);
  }

  static const examples = {
    VoiceLanguage.spanish: [
      'Puesto libre en el P1',
      'Eléctrico en el P2',
      'Accesible en la zona B',
    ],
    VoiceLanguage.english: [
      'Free spot in P1',
      'Electric spot in P2',
      'Accessible spot in zone B',
    ],
  };

  final SpeechRecognizer _speech;
  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final PhraseInterpreter _interpret;
  StreamSubscription<SpeechUpdate>? _session;
  int _generation = 0;
  VoiceSearchOutcome? _outcome;

  VoiceStatus status = VoiceStatus.ready;
  String words = '';
  VoiceQuery heard = VoiceQuery.empty;
  SpeechFailure? failure;
  Building? destination;

  VoiceLanguage get language => _preferences.voiceLanguage;

  List<String> get tryPhrases => examples[language]!;

  bool get isListening => status == VoiceStatus.listening;

  Future<void> open() async {
    _outcome = null;
    await listen();
    await _loadDestination();
  }

  Future<void> close() => _endSession();

  VoiceSearchOutcome? takeOutcome() {
    final outcome = _outcome;
    _outcome = null;
    return outcome;
  }

  Future<void> listen() async {
    await _endSession();
    status = VoiceStatus.listening;
    words = '';
    heard = VoiceQuery.empty;
    failure = null;
    notifyListeners();
    _session = _speech.listen(language.localeId).listen(_onSpeech);
  }

  Future<void> stopListening() => _speech.stop();

  Future<void> chooseLanguage(VoiceLanguage value) async {
    if (value == language) return;
    await _preferences.saveVoiceLanguage(value);
    await listen();
  }

  Future<void> typeInstead() async {
    final typed = words;
    await _endSession();
    _complete(TypeInstead(typed));
  }

  void _onSpeech(SpeechUpdate update) {
    switch (update) {
      case SpeechHeard(:final words, isFinal: true):
        unawaited(_finish(words));
      case SpeechHeard(:final words):
        this.words = words;
        notifyListeners();
        unawaited(_preview(words));
      case SpeechFailed(:final reason):
        _fail(reason);
    }
  }

  Future<void> _preview(String phrase) async {
    final generation = ++_generation;
    final query = await _interpret(phrase);
    if (generation != _generation || !isListening) return;
    heard = query;
    notifyListeners();
  }

  Future<void> _finish(String phrase) async {
    final generation = ++_generation;
    words = phrase;
    final query = await _interpret(phrase);
    if (generation != _generation) return;
    heard = query;
    if (!query.understood) {
      status = VoiceStatus.notUnderstood;
      notifyListeners();
      return;
    }
    _complete(PhraseSearch(phrase, query, spoken: true));
  }

  void _fail(SpeechFailure reason) {
    _generation++;
    status = VoiceStatus.failed;
    failure = reason;
    notifyListeners();
  }

  void _complete(VoiceSearchOutcome outcome) {
    _outcome = outcome;
    status = VoiceStatus.ready;
    notifyListeners();
  }

  Future<void> _loadDestination() async {
    try {
      final buildings = await _parking.getBuildings();
      final id = _preferences.destination;
      destination =
          buildings.where((building) => building.id == id).firstOrNull ??
          destination;
      notifyListeners();
    } catch (e) {
      debugPrint('destination not loaded: $e');
    }
  }

  Future<void> _endSession() async {
    _generation++;
    final session = _session;
    _session = null;
    if (session == null) return;
    await session.cancel();
    await _speech.cancel();
  }

  @override
  void dispose() {
    unawaited(_session?.cancel());
    super.dispose();
  }
}
