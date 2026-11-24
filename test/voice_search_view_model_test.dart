import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/spot_filter.dart';
import 'package:parkwise/domain/entities/voice_language.dart';
import 'package:parkwise/domain/ports/speech_recognizer.dart';
import 'package:parkwise/domain/services/voice_query_parser.dart';
import 'package:parkwise/infrastructure/mock/memory_recent_search_store.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/infrastructure/mock/mock_speech_recognizer.dart';
import 'package:parkwise/presentation/screens/voice_search/voice_search_view_model.dart';

void main() {
  late DateTime now;
  late MockSpeechRecognizer speech;
  late MemoryRecentSearchStore recent;
  late MockPreferencesStore preferences;
  late MockConnectivity connectivity;
  late VoiceSearchViewModel voice;

  setUp(() {
    now = DateTime(2026, 11, 24, 7, 30);
    speech = MockSpeechRecognizer();
    recent = MemoryRecentSearchStore();
    preferences = MockPreferencesStore();
    connectivity = MockConnectivity();
    voice = VoiceSearchViewModel(
      speech,
      recent,
      MockParkingRepository(),
      preferences,
      connectivity,
      interpret: interpretPhraseInline,
      clock: () => now,
    );
  });

  tearDown(() => voice.dispose());

  test('a phrase is read while it is said and ends in a search', () async {
    await voice.open();
    expect(voice.isListening, isTrue);
    expect(speech.locales, ['es-CO']);

    speech.hear('eléctrico en el');
    await pumpEventQueue();
    expect(voice.words, 'eléctrico en el');
    expect(voice.heard.filters, contains(SpotFilter.electric));

    speech.hear('eléctrico en el P2', isFinal: true);
    await pumpEventQueue();

    final outcome = voice.takeOutcome()! as PhraseSearch;
    expect(outcome.spoken, isTrue);
    expect(outcome.query.levelCode, 'P2');
    expect(voice.takeOutcome(), isNull);
    expect((await recent.recent()).single.phrase, 'eléctrico en el P2');
  });

  test('a phrase without a level, zone or type asks to try again', () async {
    await voice.open();

    speech.hear('hola', isFinal: true);
    await pumpEventQueue();

    expect(voice.status, VoiceStatus.notUnderstood);
    expect(voice.takeOutcome(), isNull);
    expect(await recent.recent(), isEmpty);
  });

  test('without internet it says why and moves to the keyboard', () async {
    connectivity.online = false;
    await voice.open();

    speech.hear('zona');
    speech.fail(SpeechFailure.network);
    await pumpEventQueue();

    expect(voice.status, VoiceStatus.failed);
    expect(voice.failure, SpeechFailure.network);

    await voice.typeInstead();
    final outcome = voice.takeOutcome()! as TypeInstead;
    expect(outcome.words, 'zona');
    expect(speech.cancelled, isTrue);
  });

  test('the language is saved and used for the next listen', () async {
    await voice.open();

    await voice.chooseLanguage(VoiceLanguage.english);

    expect(preferences.voiceLanguage, VoiceLanguage.english);
    expect(speech.locales, ['es-CO', 'en-US']);
    expect(voice.tryPhrases.first, 'Free spot in P1');
  });

  test('a recent search is repeated without speaking', () async {
    await recent.save('VIP en P1', now);
    await voice.open();
    expect(voice.recent.single.phrase, 'VIP en P1');

    await voice.repeat(voice.recent.single);

    final outcome = voice.takeOutcome()! as PhraseSearch;
    expect(outcome.spoken, isFalse);
    expect(outcome.query.filters, contains(SpotFilter.vip));
  });

  test('the destination comes from the buildings of the server', () async {
    await voice.open();

    expect(voice.destination?.name, 'Edificio Santo Domingo');
  });
}
