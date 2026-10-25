import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/weather_glyph.dart';
import 'theme.dart';

const _brown = '#7A5233';
const _mid = '#A47E57';
const _ink = '#3A2214';
const svgWhite = '#FFFFFF';

String _svg(String inner) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none" '
    'stroke-linecap="round" stroke-linejoin="round">$inner</svg>';

String _p(double v) => v.toStringAsFixed(1);

String _cloud({int dy = 0}) =>
    '<path d="M20 ${46 + dy}C11 ${46 + dy} 9 ${35 + dy} 18 ${33 + dy}'
    'C18 ${23 + dy} 32 ${19 + dy} 38 ${27 + dy}C47 ${23 + dy} 55 ${32 + dy} 49 ${40 + dy}'
    'C55 ${42 + dy} 53 ${46 + dy} 46 ${46 + dy}Z" fill="#FFFFFF" stroke="$_brown" stroke-width="2.6"/>';

String _sun(double cx, double cy, {double r = 8}) {
  final rays = StringBuffer();
  for (var k = 0; k < 8; k++) {
    final a = k * math.pi / 4;
    rays.write('<path d="M${_p(cx + math.cos(a) * (r + 4))} ${_p(cy + math.sin(a) * (r + 4))}'
        'L${_p(cx + math.cos(a) * (r + 9))} ${_p(cy + math.sin(a) * (r + 9))}" '
        'stroke="$_brown" stroke-width="2.6"/>');
  }
  return '<circle cx="$cx" cy="$cy" r="$r" stroke="$_brown" stroke-width="2.6"/>$rays';
}

String _streaks(List<int> xs) => xs
    .map((x) => '<path d="M$x 46l-3 8" stroke="$_brown" stroke-width="2.6"/>')
    .join();

String weatherSvg(WeatherGlyph g) {
  switch (g) {
    case WeatherGlyph.clear:
      return _svg(_sun(32, 32, r: 11));
    case WeatherGlyph.partly:
      return _svg('${_sun(23, 23)}${_cloud(dy: 4)}');
    case WeatherGlyph.cloudy:
      return _svg(_cloud(dy: 4));
    case WeatherGlyph.fog:
      return _svg('${_cloud(dy: -4)}<path d="M14 50h36M20 56h24" stroke="$_brown" stroke-width="2.6"/>');
    case WeatherGlyph.drizzle:
      return _svg('${_cloud(dy: -4)}${_streaks([28, 40])}');
    case WeatherGlyph.rain:
      return _svg('${_cloud(dy: -4)}${_streaks([24, 34, 44])}');
    case WeatherGlyph.storm:
      return _svg('${_cloud(dy: -4)}<path d="M35 44l-7 10h8l-5 9" stroke="$_brown" stroke-width="2.6"/>');
    case WeatherGlyph.snow:
      return _svg('${_cloud(dy: -4)}'
          '<circle cx="24" cy="52" r="1.8" fill="$_brown"/>'
          '<circle cx="34" cy="57" r="1.8" fill="$_brown"/>'
          '<circle cx="44" cy="52" r="1.8" fill="$_brown"/>');
  }
}

String micSvg([String c = svgWhite]) => _svg(
    '<rect x="25" y="10" width="14" height="26" rx="7" stroke="$c" stroke-width="3"/>'
    '<path d="M19 30a13 13 0 0 0 26 0M32 43v10M24 53h16" stroke="$c" stroke-width="3"/>');

String barsSvg([String c = svgWhite]) {
  const xs = [16, 23, 32, 41, 48];
  const hs = [12, 24, 38, 24, 12];
  final b = StringBuffer();
  for (var i = 0; i < xs.length; i++) {
    b.write('<path d="M${xs[i]} ${32 - hs[i] / 2}v${hs[i]}" stroke="$c" stroke-width="3.4"/>');
  }
  return _svg(b.toString());
}

String logoSvg() => _svg(
    '<circle cx="32" cy="32" r="26" stroke="$_brown" stroke-width="4"/>'
    '<circle cx="32" cy="32" r="15" stroke="$_brown" stroke-width="4"/>'
    '<circle cx="32" cy="32" r="5" fill="$_brown"/>');

String bangSvg() => _svg(
    '<path d="M32 15v21" stroke="#FFFFFF" stroke-width="5.5"/>'
    '<circle cx="32" cy="47" r="3.6" fill="#FFFFFF"/>');

String pinSvg({bool ground = true}) => _svg(
    '<path d="M32 54C32 54 14 38 14 26a18 18 0 0 1 36 0C50 38 32 54 32 54Z" stroke="$_brown" stroke-width="2.6"/>'
    '<circle cx="32" cy="26" r="6.5" stroke="$_brown" stroke-width="2.6"/>'
    '${ground ? '<ellipse cx="32" cy="58" rx="12" ry="3" stroke="$_mid" stroke-width="2"/>' : ''}');

String dropSvg() => _svg(
    '<path d="M32 10C32 10 18 26 18 37a14 14 0 0 0 28 0C46 26 32 10 32 10Z" stroke="$_brown" stroke-width="3"/>');

String windSvg() => _svg(
    '<path d="M8 26h30a7 7 0 1 0-7-7M8 38h40a7 7 0 1 1-7 7M8 32h18" stroke="$_brown" stroke-width="3"/>');

String umbrellaSvg() => _svg(
    '<path d="M8 34a24 22 0 0 1 48 0ZM32 34v16a5 5 0 0 1-10 0" stroke="$_brown" stroke-width="3"/>');

String checkSvg() => _svg(
    '<circle cx="32" cy="32" r="24" stroke="$_brown" stroke-width="3.4"/>'
    '<path d="M21 33l8 8 15-17" stroke="$_brown" stroke-width="3.6"/>');

String clockSvg(int h, int m) {
  final ah = ((h % 12) + m / 60) * 30 * math.pi / 180;
  final am = m * 6 * math.pi / 180;
  final ticks = StringBuffer();
  for (var k = 0; k < 12; k++) {
    final a = k * math.pi / 6;
    ticks.write('<path d="M${_p(32 + math.sin(a) * 19)} ${_p(32 - math.cos(a) * 19)}'
        'L${_p(32 + math.sin(a) * 22)} ${_p(32 - math.cos(a) * 22)}" stroke="$_mid" stroke-width="2"/>');
  }
  return _svg('<circle cx="32" cy="32" r="26" stroke="$_brown" stroke-width="2.6"/>$ticks'
      '<path d="M32 32L${_p(32 + math.sin(ah) * 10)} ${_p(32 - math.cos(ah) * 10)}" stroke="$_ink" stroke-width="3.4"/>'
      '<path d="M32 32L${_p(32 + math.sin(am) * 16)} ${_p(32 - math.cos(am) * 16)}" stroke="$_brown" stroke-width="2.6"/>'
      '<circle cx="32" cy="32" r="2.4" fill="$_ink"/>');
}

final String _calendarFrame = _svg(
    '<rect x="8" y="14" width="48" height="42" rx="7" stroke="$_brown" stroke-width="2.6"/>'
    '<path d="M8 26h48M21 8v11M43 8v11" stroke="$_brown" stroke-width="2.6"/>');

class Glyph extends StatelessWidget {
  const Glyph(this.svg, {super.key, required this.size});

  final String svg;
  final double size;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(svg, width: size, height: size);
}

/// Kalender bergaris dengan bulan dan tanggal ditulis sebagai teks.
class CalendarGlyph extends StatelessWidget {
  const CalendarGlyph({
    super.key,
    required this.day,
    required this.month,
    required this.size,
  });

  final int day;
  final String month;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          SvgPicture.string(_calendarFrame, width: size, height: size),
          Positioned(
            top: size * 0.24,
            left: 0,
            right: 0,
            child: Text(
              month,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size * 0.115,
                height: 1,
                fontWeight: FontWeight.w600,
                color: Palette.brown,
              ),
            ),
          ),
          Positioned(
            top: size * 0.47,
            left: 0,
            right: 0,
            child: Text(
              '$day',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size * 0.30,
                height: 1,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
