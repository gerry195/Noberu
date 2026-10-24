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
        Problem.micDenied => 'Mikrofon tidak bisa dipakai',
        Problem.noSpeech => 'Saya tidak mendengar suara',
        Problem.notUnderstood => 'Saya belum mengerti perintahnya',
        Problem.gpsOff => 'Lokasi belum aktif',
        Problem.gpsDenied => 'Izin lokasi ditolak',
        Problem.noInternet => 'Tidak ada sambungan internet',
        Problem.placeNotFound => 'Tempat itu tidak ketemu',
        Problem.serviceFailed => 'Data belum bisa diambil',
        Problem.ttsFailed => 'Suara gagal diputar',
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
