import 'package:flutter/material.dart';

/// Kontras di atas [ground]: ink 15:1, signal 13:1, alert 8:1.
class Palette {
  static const ground = Color(0xFF16150F);
  static const ink = Color(0xFFF4EFE0);
  static const inkSoft = Color(0xFFB9B2A0);
  static const signal = Color(0xFFFFD100);
  static const signalDeep = Color(0xFF6B5300);
  static const alert = Color(0xFFFF7A59);
}

const _serif = TextStyle(
  fontFamily: 'serif',
  fontFamilyFallback: ['Noto Serif', 'Georgia', 'Times New Roman'],
);

class NoberuType {
  static final wordmark = _serif.copyWith(fontSize: 26, fontWeight: FontWeight.w700);
  static final headline = _serif.copyWith(fontSize: 52, height: 1.05, fontWeight: FontWeight.w600);
  static const detail = TextStyle(fontSize: 22, height: 1.4, fontWeight: FontWeight.w500);
  static const heard = TextStyle(fontSize: 18, height: 1.35, fontStyle: FontStyle.italic);
}

ThemeData noberuTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.signal,
        brightness: Brightness.dark,
        surface: Palette.ground,
      ),
      scaffoldBackgroundColor: Palette.ground,
    );
