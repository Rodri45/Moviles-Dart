import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/ports/speech_recognizer.dart';

class DeviceSpeechRecognizer implements SpeechRecognizer {
  DeviceSpeechRecognizer([SpeechToText? speech])
    : _speech = speech ?? SpeechToText();

  static const listenFor = Duration(seconds: 15);
  static const pauseFor = Duration(seconds: 3);

  final SpeechToText _speech;
  StreamController<SpeechUpdate>? _session;
  String _heard = '';

  @override
  Stream<SpeechUpdate> listen(String localeId) {
    _close();
    final session = StreamController<SpeechUpdate>();
    _session = session;
    _heard = '';
    unawaited(_start(localeId));
    return session.stream;
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    _close();
    await _speech.cancel();
  }

  Future<void> _start(String localeId) async {
    try {
      final ready = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
        options: [SpeechToText.androidNoBluetooth],
      );
      if (!ready) {
        final allowed = await _speech.hasPermission;
        _finish(
          SpeechFailed(
            allowed ? SpeechFailure.unavailable : SpeechFailure.noPermission,
          ),
        );
        return;
      }
      await _speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenMode: ListenMode.search,
          cancelOnError: true,
          listenFor: listenFor,
          pauseFor: pauseFor,
        ),
      );
    } catch (e) {
      debugPrint('speech recognition could not start: $e');
      _finish(const SpeechFailed(SpeechFailure.unavailable));
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    _heard = result.recognizedWords;
    if (result.finalResult) {
      _finish(SpeechHeard(_heard, isFinal: true));
    } else {
      _emit(SpeechHeard(_heard));
    }
  }

  void _onError(SpeechRecognitionError error) {
    final failure = _failureFor(error.errorMsg);
    if (failure == SpeechFailure.noMatch && _heard.isNotEmpty) {
      _finish(SpeechHeard(_heard, isFinal: true));
    } else {
      _finish(SpeechFailed(failure));
    }
  }

  void _onStatus(String status) {
    if (status != SpeechToText.doneStatus) return;
    _finish(
      _heard.isEmpty
          ? const SpeechFailed(SpeechFailure.noMatch)
          : SpeechHeard(_heard, isFinal: true),
    );
  }

  void _emit(SpeechUpdate update) {
    final session = _session;
    if (session == null || session.isClosed) return;
    session.add(update);
  }

  void _finish(SpeechUpdate update) {
    _emit(update);
    _close();
  }

  void _close() {
    unawaited(_session?.close());
    _session = null;
  }

  static SpeechFailure _failureFor(String message) => switch (message) {
    'error_no_match' || 'error_speech_timeout' => SpeechFailure.noMatch,
    'error_network' ||
    'error_network_timeout' ||
    'error_server' ||
    'error_server_disconnected' => SpeechFailure.network,
    'error_permission' => SpeechFailure.noPermission,
    'error_language_not_supported' ||
    'error_language_unavailable' => SpeechFailure.unavailable,
    _ => SpeechFailure.other,
  };
}
