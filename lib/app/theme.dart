import 'package:flutter/material.dart';

/// Kontras: tinta di atas kertas 15:1, kertas di atas terakota 5,7:1.
class Palette {
  static const paper = Color(0xFFF5F0E6);
  static const ink = Color(0xFF1C1A16);
  static const clay = Color(0xFFA8381A);
  static const inkSoft = Color(0xFF4A453C);
}

const _serif = TextStyle(
  fontFamily: 'serif',
  fontFamilyFallback: ['Noto Serif', 'Georgia', 'Times New Roman'],
);

class TuturType {
  static final wordmark = _serif.copyWith(fontSize: 26, fontWeight: FontWeight.w700);
  static final headline = _serif.copyWith(fontSize: 52, height: 1.05, fontWeight: FontWeight.w600);
  static const detail = TextStyle(fontSize: 22, height: 1.4, fontWeight: FontWeight.w500);
  static const heard = TextStyle(fontSize: 18, height: 1.35, fontStyle: FontStyle.italic);
  static const label = TextStyle(fontSize: 14, letterSpacing: 1.6, fontWeight: FontWeight.w700);
}

ThemeData tuturTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.clay,
        surface: Palette.paper,
      ),
      scaffoldBackgroundColor: Palette.paper,
    );
