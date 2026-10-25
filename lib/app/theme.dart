import 'package:flutter/material.dart';

/// Kontras di atas putih: ink 15:1, inkSoft 9:1, brown 6,8:1.
/// Krem dan tan hanya untuk dekorasi, bukan teks.
class Palette {
  static const ground = Color(0xFFFFFFFF);
  static const ink = Color(0xFF3A2214);
  static const inkSoft = Color(0xFF5C4636);
  static const brown = Color(0xFF7A5233);
  static const mid = Color(0xFFA47E57);
  static const tan = Color(0xFFD8C3A5);
  static const cream = Color(0xFFF1E8D9);
  static const edge = Color(0xFFE4D6BF);
}

class NoberuType {
  static const wordmark = TextStyle(
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.1,
    color: Palette.ink,
  );
  static const title = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: Palette.ink,
  );
  static const body = TextStyle(
    fontSize: 18,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: Palette.inkSoft,
  );
  static const label = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Palette.inkSoft,
  );
  static const question = TextStyle(
    fontSize: 27,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: Palette.ink,
  );
  static const sentence = TextStyle(
    fontSize: 18,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: Palette.ink,
  );
}

ThemeData noberuTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.brown,
        surface: Palette.ground,
      ),
      scaffoldBackgroundColor: Palette.ground,
    );
