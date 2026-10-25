# Noberu

Asisten suara berbahasa Indonesia untuk tunanetra. Nama dari 述べる (noberu), "menuturkan, menyampaikan". Tahan layar, bicara, lepas, lalu dengarkan jawabannya. Bisa menjawab hari, tanggal, jam, cuaca, dan lokasi.

## Cara pakai

- **Tahan layar** di mana saja. Ponsel bergetar dan berbunyi bip, lalu bicara.
- Pita gelombang kuning keselamatan mengikuti volume suara Anda saat merekam. Saat siap ia menjadi garis redup, saat mencari ia bergulir pelan.
- **Lepas jari** untuk mengirim. Getar pendek dan bip rendah menandai rekaman selesai.
- **Ketuk dua kali cepat** untuk mengulang jawaban terakhir.
- **Ketuk sekali** untuk mendengar petunjuk singkat.
- **TalkBack aktif**: ketuk dua kali untuk mulai merekam, ketuk dua kali lagi untuk mengirim. Aksi "Ulangi jawaban terakhir" ada di menu aksi TalkBack.

Contoh: "cuaca besok di Medan", "tanggal 25 Desember hari apa", "cuaca tiga hari lagi", "jam berapa sekarang", "lokasi saya", "lokasi Politeknik Negeri Batam".

## Menjalankan

Folder ini hanya berisi `lib/`, `test/`, `pubspec.yaml`, dan manifest Android. Rangka proyek dibuat oleh Flutter:

```
flutter create --org id.noberu --project-name noberu --platforms android noberu_app
```

1. Salin `lib/`, `test/`, `pubspec.yaml`, dan `analysis_options.yaml` dari sini ke `noberu_app/` (timpa yang ada).
2. Salin isi `<manifest>` dari `android/app/src/main/AndroidManifest.xml` di sini ke manifest `noberu_app`. Pertahankan `package`/namespace bawaan Flutter.
3. Di `android/app/build.gradle(.kts)` set `minSdk` ke 23 atau lebih.
4. `flutter pub get`, lalu `flutter run`.
5. `flutter test` untuk uji pengurai perintah.

Perangkat perlu Google Text-to-Speech dengan paket bahasa Indonesia, layanan suara Google, dan internet.

## Sumber data

Semua gratis dan tanpa kunci API: Open-Meteo (prakiraan, arsip, geocoding cadangan), OpenStreetMap Nominatim (alamat dan pencarian tempat), dan GPS perangkat. Tanggal lebih dari 15 hari ke depan dijawab dengan rata-rata lima tahun terakhir.

## Struktur

```
lib/
  main.dart
  app/        tema gelap, layar utama, pita gelombang (wave_ribbon.dart)
  core/       jenis masalah, getar dan bip
  voice/      pengenalan suara (Ears), pembacaan suara (Speaker)
  intent/     pengurai kalimat menjadi perintah
  data/       lokasi dan cuaca
  flow/       Session (gestur tahan/lepas) dan Answerer (isi jawaban)
```
