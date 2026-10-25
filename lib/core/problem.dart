import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

enum Problem {
  micDenied,
  noSpeech,
  notUnderstood,
  gpsOff,
  gpsDenied,
  noInternet,
  placeNotFound,
  serviceFailed,
  ttsFailed,
}

class ProblemException implements Exception {
  const ProblemException(this.problem);
  final Problem problem;

  @override
  String toString() => 'ProblemException($problem)';
}

extension ProblemText on Problem {
  String get message => switch (this) {
        Problem.micDenied => 'Maaf, mikrofon belum bisa dipakai',
        Problem.noSpeech => 'Maaf, aku tidak mendengar suara',
        Problem.notUnderstood => 'Maaf, aku belum mengerti perintahnya',
        Problem.gpsOff => 'Maaf, lokasi belum aktif',
        Problem.gpsDenied => 'Maaf, izin lokasi ditolak',
        Problem.noInternet => 'Maaf, tidak ada internet',
        Problem.placeNotFound => 'Maaf, tempat itu tidak ketemu',
        Problem.serviceFailed => 'Maaf, data belum bisa diambil',
        Problem.ttsFailed => 'Maaf, suara gagal diputar',
      };

  String get hint => switch (this) {
        Problem.micDenied => 'Izinkan mikrofon di pengaturan ponsel, lalu coba lagi',
        Problem.noSpeech => 'Tahan layar, tunggu bunyi bip, lalu bicara',
        Problem.notUnderstood =>
          'Coba tanya hari, tanggal, jam, cuaca, atau lokasi',
        Problem.gpsOff => 'Nyalakan lokasi di ponsel, lalu coba lagi',
        Problem.gpsDenied => 'Izinkan lokasi di pengaturan ponsel, lalu coba lagi',
        Problem.noInternet => 'Periksa sambungan internet, lalu coba lagi',
        Problem.placeNotFound => 'Sebutkan nama tempat yang lebih lengkap',
        Problem.serviceFailed => 'Tunggu sebentar, lalu coba lagi',
        Problem.ttsFailed => 'Periksa suara ponsel dan mesin suara Google',
      };
}

Problem classify(Object error) {
  if (error is ProblemException) return error.problem;
  if (error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return Problem.noInternet;
  }
  return Problem.serviceFailed;
}
