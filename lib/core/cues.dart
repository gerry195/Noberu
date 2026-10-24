import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Getar dan bip penanda mulai/selesai merekam.
class Cues {
  final AudioPlayer _player = AudioPlayer();
  late final Uint8List _high = _tone(880, 90);
  late final Uint8List _low = _tone(560, 110);

  /// Selesai setelah bip habis, supaya mikrofon tidak merekam bipnya sendiri.
  Future<void> recordingStarts() async {
    HapticFeedback.mediumImpact();
    await _play(_high);
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  void recordingEnds() {
    HapticFeedback.lightImpact();
    _play(_low);
  }

  void failed() {
    HapticFeedback.vibrate();
  }

  Future<void> _play(Uint8List wav) async {
    try {
      await _player.stop();
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    } catch (_) {
      // Bip hanya pelengkap getar; gagal putar tidak boleh menghentikan alur.
    }
  }

  void dispose() => _player.dispose();

  static Uint8List _tone(double hz, int ms) {
    const rate = 22050;
    final n = rate * ms ~/ 1000;
    final data = ByteData(44 + n * 2);

    void tag(int at, String s) {
      for (var i = 0; i < 4; i++) {
        data.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    tag(36, 'data');
    data.setUint32(40, n * 2, Endian.little);

    final ramp = rate * 0.01;
    for (var i = 0; i < n; i++) {
      final edge = math.min(i, n - i) / ramp;
      final env = edge > 1 ? 1.0 : edge;
      final v = math.sin(2 * math.pi * hz * i / rate) * env * 0.6 * 32767;
      data.setInt16(44 + i * 2, v.round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
