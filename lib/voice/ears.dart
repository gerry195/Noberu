import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import '../core/problem.dart';

import 'package:speech_to_text/speech_recognition_error.dart';

/// Merekam selama layar ditahan. [finish] dipanggil saat jari dilepas.
class Ears {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  String _words = '';
  Problem? _engineProblem;
  Completer<String>? _final;

  Future<void> begin() async {
    _words = '';
    _engineProblem = null;
    _final = Completer<String>();

    if (!_ready) {
      _ready = await _stt.initialize(onError: _onEngineError);
      if (!_ready) throw const ProblemException(Problem.micDenied);
    }

    await _stt.listen(
      localeId: 'id_ID',
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 60),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
      onResult: (r) {
        _words = r.recognizedWords;
        final done = _final;
        if (r.finalResult && done != null && !done.isCompleted) {
          done.complete(_words);
        }
      },
    );
  }

  /// Menghentikan rekaman dan mengembalikan teks akhir. Android sering
  /// mengirim hasil final terlambat, jadi teks parsial dipakai bila habis waktu.
  Future<String> finish() async {
    final pending = _final;
    if (pending == null) return '';
    await _stt.stop();
    String text;
    try {
      text = await pending.future.timeout(const Duration(milliseconds: 1500));
    } on TimeoutException {
      text = _words;
    }
    text = text.trim();
    final problem = _engineProblem;
    if (text.isEmpty && problem != null) throw ProblemException(problem);
    return text;
  }

  Future<void> abort() async {
    _final = null;
    await _stt.cancel();
  }

  void _onEngineError(SpeechRecognitionError e) {
    final msg = e.errorMsg;
    if (msg == 'error_permission') {
      _engineProblem = Problem.micDenied;
    } else if (msg.startsWith('error_network') || msg == 'error_server') {
      _engineProblem = Problem.noInternet;
    }
  }
}
