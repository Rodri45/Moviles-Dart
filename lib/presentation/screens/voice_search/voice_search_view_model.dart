import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/building.dart';
import '../../../domain/entities/device_description.dart';
import '../../../domain/entities/recent_search.dart';
import '../../../domain/entities/voice_language.dart';
import '../../../domain/entities/voice_query.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/recent_search_store.dart';
import '../../../domain/ports/speech_recognizer.dart';
import '../../../domain/ports/telemetry.dart';
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
    this._recentSearches,
    this._parking,
    this._preferences,
    this._telemetry,
    this._device,
    ConnectivityPort connectivity, {
    this._interpret = interpretPhraseInBackground,
    this._previewDelay = defaultPreviewDelay,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    watchConnectivity(connectivity, _loadDestination);
  }

  static const defaultPreviewDelay = Duration(milliseconds: 300);

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
  final RecentSearchStore _recentSearches;
  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final Telemetry _telemetry;
  final DeviceDescription _device;
  final PhraseInterpreter _interpret;
  final Duration _previewDelay;
  final DateTime Function() _clock;
  Timer? _previewTimer;
  StreamSubscription<SpeechUpdate>? _session;
  DateTime? _startedAt;
  int _generation = 0;
  int _interpreted = 0;
  int _thrownAway = 0;
  VoiceSearchOutcome? _outcome;

  VoiceStatus status = VoiceStatus.ready;
  String words = '';
  VoiceQuery heard = VoiceQuery.empty;
  SpeechFailure? failure;
  List<RecentSearch> recent = const [];
  Building? destination;

  VoiceLanguage get language => _preferences.voiceLanguage;

  List<String> get tryPhrases => examples[language]!;

  bool get isListening => status == VoiceStatus.listening;

  Future<void> open() async {
    _outcome = null;
    await listen();
    await Future.wait([_loadRecent(), _loadDestination()]);
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
    _startedAt = _clock();
    _interpreted = 0;
    _thrownAway = 0;
    notifyListeners();
    _session = _speech.listen(language.localeId).listen(_onSpeech);
  }

  Future<void> stopListening() => _speech.stop();

  Future<void> chooseLanguage(VoiceLanguage value) async {
    if (value == language) return;
    await _preferences.saveVoiceLanguage(value);
    await listen();
  }

  Future<void> repeat(RecentSearch search) async {
    await _endSession();
    final query = await _interpret(search.phrase);
    _remember(search.phrase);
    _complete(PhraseSearch(search.phrase, query, spoken: false));
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
        _previewTimer?.cancel();
        _previewTimer = Timer(_previewDelay, () => unawaited(_preview(words)));
      case SpeechFailed(:final reason):
        _fail(reason);
    }
  }

  Future<void> _preview(String phrase) async {
    final generation = ++_generation;
    _interpreted++;
    final query = await _interpret(phrase);
    if (generation != _generation || !isListening) {
      _thrownAway++;
      return;
    }
    heard = query;
    notifyListeners();
  }

  Future<void> _finish(String phrase) async {
    _previewTimer?.cancel();
    final generation = ++_generation;
    words = phrase;
    _track('ok');
    final query = await _interpret(phrase);
    debugPrint(
      'voice previews: $_interpreted interpreted, $_thrownAway thrown away',
    );
    if (generation != _generation) return;
    heard = query;
    if (!query.understood) {
      status = VoiceStatus.notUnderstood;
      notifyListeners();
      return;
    }
    _remember(phrase);
    _complete(PhraseSearch(phrase, query, spoken: true));
  }

  void _fail(SpeechFailure reason) {
    _previewTimer?.cancel();
    _generation++;
    _track(_outcomeOf(reason));
    status = VoiceStatus.failed;
    failure = reason;
    notifyListeners();
  }

  void _complete(VoiceSearchOutcome outcome) {
    _outcome = outcome;
    status = VoiceStatus.ready;
    notifyListeners();
  }

  void _remember(String phrase) {
    unawaited(
      _recentSearches
          .save(phrase, _clock())
          .then((_) => _loadRecent())
          .catchError((Object e) => debugPrint('recent search not saved: $e')),
    );
  }

  Future<void> _loadRecent() async {
    try {
      recent = await _recentSearches.recent();
      notifyListeners();
    } catch (e) {
      debugPrint('recent searches not read: $e');
    }
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
    _previewTimer?.cancel();
    _generation++;
    final session = _session;
    _session = null;
    if (session == null) return;
    await session.cancel();
    await _speech.cancel();
  }

  void _track(String outcome) {
    final startedAt = _startedAt;
    _telemetry.track('voice_recognition', {
      'outcome': outcome,
      if (startedAt != null)
        'latencyMs': _clock().difference(startedAt).inMilliseconds,
      ..._device.toProperties(),
    });
  }

  static String _outcomeOf(SpeechFailure reason) => switch (reason) {
    SpeechFailure.noMatch => 'no_match',
    SpeechFailure.noPermission => 'no_permission',
    SpeechFailure.network => 'offline',
    SpeechFailure.unavailable || SpeechFailure.other => 'error',
  };

  @override
  void dispose() {
    _previewTimer?.cancel();
    unawaited(_session?.cancel());
    super.dispose();
  }
}
