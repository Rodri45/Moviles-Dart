import 'dart:async';

import '../../domain/ports/speech_recognizer.dart';

class MockSpeechRecognizer implements SpeechRecognizer {
  final List<String> locales = [];
  StreamController<SpeechUpdate>? _session;
  bool stopped = false;
  bool cancelled = false;

  @override
  Stream<SpeechUpdate> listen(String localeId) {
    locales.add(localeId);
    final session = StreamController<SpeechUpdate>();
    _session = session;
    return session.stream;
  }

  void hear(String words, {bool isFinal = false}) {
    _session?.add(SpeechHeard(words, isFinal: isFinal));
    if (isFinal) unawaited(_session?.close());
  }

  void fail(SpeechFailure reason) {
    _session?.add(SpeechFailed(reason));
    unawaited(_session?.close());
  }

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> cancel() async {
    cancelled = true;
    unawaited(_session?.close());
  }
}
