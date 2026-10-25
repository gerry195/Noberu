import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../flow/session.dart';
import 'theme.dart';

/// Pita gelombang berlapis. Tinggi pita mengikuti volume suara saat merekam;
/// saat siap ia menjadi garis redup, saat mencari ia bergulir pelan.
class WaveRibbon extends StatefulWidget {
  const WaveRibbon({super.key, required this.phase, required this.level});

  final Phase phase;
  final ValueListenable<double> level;

  @override
  State<WaveRibbon> createState() => _WaveRibbonState();
}

class _RibbonModel extends ChangeNotifier {
  double t = 0;
  double energy = 0;

  void bump() => notifyListeners();
}

class _WaveRibbonState extends State<WaveRibbon>
    with SingleTickerProviderStateMixin {
  final _model = _RibbonModel();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = elapsed;

    final double target = switch (widget.phase) {
      Phase.listening =>
        0.14 + 0.86 * widget.level.value.clamp(0.0, 1.0).toDouble(),
      Phase.thinking => 0.38,
      _ => 0.0,
    };
    final speed = widget.phase == Phase.thinking ? 0.55 : 1.0;
    final still = MediaQuery.of(context).disableAnimations;

    _model.energy += (target - _model.energy) * (1 - math.exp(-dt * 10));
    if (!still) _model.t += dt * speed;
    _model.bump();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _RibbonPainter(_model),
        size: Size.infinite,
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.m) : super(repaint: m);

  final _RibbonModel m;

  static const _layers = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final e = m.energy;
    final cy = size.height / 2;
    final spread = size.height * 0.34 * e;
    final amp = size.height * 0.30 * e;
    final breathe = 0.5 + 0.5 * math.sin(m.t * 1.6);
    final double presence = 0.32 +
        0.12 * breathe * (1 - e).clamp(0.0, 1.0).toDouble() +
        0.68 * math.min(1.0, e * 2);
    final steps = math.max(24, (size.width / 6).ceil());

    // Lapisan paling belakang digambar dulu supaya yang depan menimpanya.
    for (var i = _layers - 1; i >= 0; i--) {
      final d = i / (_layers - 1);
      final color = Color.lerp(
        Palette.signal,
        Palette.signalDeep,
        math.pow(d, 0.85).toDouble(),
      )!
          .withValues(
              alpha: ((1 - 0.5 * d) * presence).clamp(0.0, 1.0).toDouble());

      final path = Path();
      for (var s = 0; s <= steps; s++) {
        final u = s / steps;
        final env = math.pow(math.max(0.0, math.sin(math.pi * u)), 0.9).toDouble();
        final y = cy +
            (d - 0.5) * spread * env +
            _shape(u, m.t, d * 3.1) * amp * (1 - 0.3 * d) * env;
        final x = u * size.width;
        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2.4 - 1.3 * d
          ..color = color,
      );
    }
  }

  /// Tiga gelombang sinus berbeda frekuensi dan arah gerak, digeser per lapisan.
  double _shape(double u, double t, double ph) {
    const tau = 2 * math.pi;
    final bump = 1 + 0.5 * math.sin(u * tau * 0.9 - t * 0.7);
    return (math.sin(u * tau * 1.3 + t * 1.1 + ph) * 0.55 +
            math.sin(u * tau * 2.7 - t * 0.8 + ph * 1.7) * 0.30 +
            math.sin(u * tau * 5.1 + t * 1.9 + ph * 0.6) * 0.15) *
        bump;
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => false;
}
