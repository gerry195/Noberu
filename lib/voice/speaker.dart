import 'package:flutter_tts/flutter_tts.dart';

import '../core/problem.dart';

class Speaker {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _setup() async {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.5);
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  /// Selesai setelah kalimat habis diucapkan.
  Future<void> say(String text) async {
    try {
      if (!_ready) await _setup();
      await _tts.stop();
      final r = await _tts.speak(text);
      if (r == 0) throw const ProblemException(Problem.ttsFailed);
    } catch (_) {
      throw const ProblemException(Problem.ttsFailed);
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Tidak ada yang perlu dihentikan bila mesin suara belum siap.
    }
  }
}
