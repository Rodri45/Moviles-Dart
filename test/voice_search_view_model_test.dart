import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/spot_filter.dart';
import 'package:parkwise/domain/entities/voice_language.dart';
import 'package:parkwise/domain/ports/speech_recognizer.dart';
import 'package:parkwise/domain/services/voice_query_parser.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_parking_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_preferences_store.dart';
import 'package:parkwise/infrastructure/mock/mock_speech_recognizer.dart';
import 'package:parkwise/presentation/screens/voice_search/voice_search_view_model.dart';

void main() {
  late MockSpeechRecognizer speech;
  late MockPreferencesStore preferences;
  late MockConnectivity connectivity;
  late VoiceSearchViewModel voice;

  setUp(() {
    speech = MockSpeechRecognizer();
    preferences = MockPreferencesStore();
    connectivity = MockConnectivity();
    voice = VoiceSearchViewModel(
      speech,
      MockParkingRepository(),
      preferences,
      connectivity,
      interpret: interpretPhraseInline,
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
  });

  test('a phrase without a level, zone or type asks to try again', () async {
    await voice.open();

    speech.hear('hola', isFinal: true);
    await pumpEventQueue();

    expect(voice.status, VoiceStatus.notUnderstood);
    expect(voice.takeOutcome(), isNull);
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

  test('the destination comes from the buildings of the server', () async {
    await voice.open();

    expect(voice.destination?.name, 'Edificio Santo Domingo');
  });
}
