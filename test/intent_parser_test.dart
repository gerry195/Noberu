import 'package:flutter_test/flutter_test.dart';
import 'package:tutur/intent/intent_parser.dart';

void main() {
  const parser = IntentParser();
  // Sabtu, 24 Oktober 2026.
  final now = DateTime(2026, 10, 24, 11, 46);

  Intent? ask(String s) => parser.parse(s, now);

  test('cuaca besok di kota lain', () {
    final i = ask('cuaca besok di Medan')!;
    expect(i.topic, Topic.weather);
    expect(i.date, DateTime(2026, 10, 25));
    expect(i.placeName, 'medan');
  });

  test('tanggal dengan angka dalam kata', () {
    final i = ask('tanggal dua puluh lima desember hari apa')!;
    expect(i.topic, Topic.day);
    expect(i.date, DateTime(2026, 12, 25));
  });

  test('tanggal dan tempat dalam satu kalimat', () {
    final i = ask('cuaca tanggal sepuluh desember di Medan')!;
    expect(i.topic, Topic.weather);
    expect(i.date, DateTime(2026, 12, 10));
    expect(i.placeName, 'medan');
  });

  test('selisih hari', () {
    expect(ask('cuaca tiga hari lagi')!.date, DateTime(2026, 10, 27));
    expect(ask('cuaca lusa')!.date, DateTime(2026, 10, 26));
    expect(ask('kemarin hari apa')!.date, DateTime(2026, 10, 23));
  });

  test('nama hari mengarah ke kemunculan berikutnya', () {
    expect(ask('cuaca hari Rabu')!.date, DateTime(2026, 10, 28));
    expect(ask('cuaca hari Sabtu')!.date, DateTime(2026, 10, 24));
  });

  test('lokasi sendiri dan lokasi bernama', () {
    expect(ask('lokasi saya')!.placeName, isNull);
    expect(ask('di mana saya sekarang')!.topic, Topic.place);
    expect(ask('lokasi Politeknik Negeri Batam')!.placeName,
        'politeknik negeri batam');
  });

  test('jam', () {
    expect(ask('jam berapa sekarang')!.topic, Topic.time);
  });

  test('kalimat di luar topik', () {
    expect(ask('ceritakan lelucon'), isNull);
  });
}
