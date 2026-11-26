enum SpeechFailure { noPermission, unavailable, noMatch, network, other }

sealed class SpeechUpdate {
  const SpeechUpdate();
}

final class SpeechHeard extends SpeechUpdate {
  const SpeechHeard(this.words, {this.isFinal = false});

  final String words;
  final bool isFinal;
}

final class SpeechFailed extends SpeechUpdate {
  const SpeechFailed(this.reason);

  final SpeechFailure reason;
}

abstract interface class SpeechRecognizer {
  Stream<SpeechUpdate> listen(String localeId);

  Future<void> stop();

  Future<void> cancel();
}
