import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/cues.dart';
import '../core/problem.dart';
import '../intent/intent_parser.dart';
import '../voice/ears.dart';
import '../voice/speaker.dart';
import 'answerer.dart';

enum Phase { idle, listening, thinking, speaking, problem }

/// Menghubungkan sentuhan layar, suara, dan jawaban.
///
/// Sentuhan di bawah [holdDelay] dianggap ketukan; lebih lama dari itu mulai
/// merekam sampai jari dilepas.
class Session extends ChangeNotifier {
  Session({Ears? ears, Speaker? speaker, Cues? cues, Answerer? answerer})
      : _ears = ears ?? Ears(),
        _speaker = speaker ?? Speaker(),
        _cues = cues ?? Cues(),
        _answerer = answerer ?? Answerer();

  static const holdDelay = Duration(milliseconds: 300);
  static const _doubleTapWindow = Duration(milliseconds: 500);

  static const welcome =
      'Noberu siap. Tahan layar lalu bicara, lepas untuk mengirim. '
      'Ketuk dua kali untuk mengulang jawaban.';
  static const _usage =
      'Tahan layar lalu bicara. Lepas untuk mengirim. '
      'Ketuk dua kali untuk mengulang jawaban terakhir.';

  final Ears _ears;
  final Speaker _speaker;
  final Cues _cues;
  final Answerer _answerer;
  final IntentParser _parser = const IntentParser();

  /// Volume suara 0..1 saat merekam, dipakai animasi gelombang.
  final ValueNotifier<double> level = ValueNotifier(0);

  Phase phase = Phase.idle;
  String heard = '';
  Answer? answer;
  Problem? problem;

  String? _lastSpoken;
  int _gen = 0;
  bool _capturing = false;
  bool _micOpen = false;
  bool _released = false;
  DateTime? _lastTap;
  Timer? _holdTimer;
  Timer? _hintTimer;
  bool _disposed = false;

  void _onLevel(double raw) {
    level.value = ((raw + 2) / 12).clamp(0.0, 1.0).toDouble();
  }

  void _emit(Phase p) {
    phase = p;
    if (!_disposed) notifyListeners();
  }

  Future<void> start() => _say(welcome);

  void touchDown() {
    _hintTimer?.cancel();
    _holdTimer?.cancel();
    _holdTimer = Timer(holdDelay, _beginCapture);
  }

  void touchUp() {
    if (_capturing) {
      _released = true;
      if (_micOpen) _endCapture(_gen);
      return;
    }
    if (!(_holdTimer?.isActive ?? false)) return;
    _holdTimer!.cancel();
    _onTap();
  }

  void touchCancel() {
    _holdTimer?.cancel();
    if (_capturing) _abortCapture();
  }

  /// Jalur untuk TalkBack: ketuk dua kali memulai, ketuk dua kali lagi mengirim.
  void toggleCapture() {
    if (_capturing) {
      _released = true;
      if (_micOpen) _endCapture(_gen);
    } else {
      _beginCapture();
    }
  }

  void repeatLast() {
    _gen++;
    final text = _lastSpoken;
    _say(text ?? _usage);
  }

  void _onTap() {
    final now = DateTime.now();
    final prev = _lastTap;
    if (prev != null && now.difference(prev) < _doubleTapWindow) {
      _lastTap = null;
      _hintTimer?.cancel();
      repeatLast();
      return;
    }
    _lastTap = now;
    _hintTimer = Timer(_doubleTapWindow, () {
      _lastTap = null;
      _say(_usage);
    });
  }

  Future<void> _beginCapture() async {
    final gen = ++_gen;
    _capturing = true;
    _micOpen = false;
    _released = false;
    heard = '';
    answer = null;
    problem = null;
    await _speaker.stop();
    _emit(Phase.listening);

    await _cues.recordingStarts();
    if (gen != _gen) return;
    try {
      await _ears.begin(onLevel: _onLevel);
    } catch (e) {
      if (gen == _gen) await _fail(e, gen);
      return;
    }
    if (gen != _gen) {
      await _ears.abort();
      return;
    }
    _micOpen = true;
    if (_released) _endCapture(gen);
  }

  Future<void> _endCapture(int gen) async {
    _capturing = false;
    _micOpen = false;
    level.value = 0;
    _emit(Phase.thinking);
    try {
      final text = await _ears.finish();
      if (gen != _gen) return;
      _cues.recordingEnds();
      if (text.isEmpty) throw const ProblemException(Problem.noSpeech);

      heard = text;
      final intent = _parser.parse(text, DateTime.now());
      if (intent == null) throw const ProblemException(Problem.notUnderstood);

      final result = await _answerer.reply(intent);
      if (gen != _gen) return;
      answer = result;
      _lastSpoken = result.spoken;
      _emit(Phase.speaking);
      await _say(result.spoken, keepScreen: true);
      if (gen == _gen) _emit(Phase.idle);
    } catch (e) {
      if (gen == _gen) await _fail(e, gen);
    }
  }

  Future<void> _abortCapture() async {
    _gen++;
    _capturing = false;
    _micOpen = false;
    level.value = 0;
    await _ears.abort();
    _emit(Phase.idle);
  }

  Future<void> _fail(Object error, int gen) async {
    if (gen != _gen) return;
    _capturing = false;
    _micOpen = false;
    level.value = 0;
    final p = classify(error);
    problem = p;
    answer = null;
    _lastSpoken = '${p.message}. ${p.hint}.';
    _cues.failed();
    _emit(Phase.problem);
    await _say(_lastSpoken!, keepScreen: true);
  }

  /// Mengucapkan [text]. Bila suara gagal, pesannya tetap tampil di layar.
  Future<void> _say(String text, {bool keepScreen = false}) async {
    try {
      await _speaker.say(text);
    } catch (_) {
      problem = Problem.ttsFailed;
      answer = null;
      _emit(Phase.problem);
      return;
    }
    if (!keepScreen && phase == Phase.speaking) _emit(Phase.idle);
  }

  @override
  void dispose() {
    _disposed = true;
    _gen++;
    _holdTimer?.cancel();
    _hintTimer?.cancel();
    _ears.abort();
    _speaker.stop();
    _cues.dispose();
    level.dispose();
    super.dispose();
  }
}
