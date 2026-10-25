import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';
import 'glyphs.dart';
import 'home_page.dart';
import 'theme.dart';

/// Layar pembuka: logo dengan cincin yang berdenyut keluar dan satu busur
/// yang mengelilinginya.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2600), _enter);
  }

  void _enter() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: Palette.ground,
      body: Semantics(
        label: 'Noberu. Memuat aplikasi.',
        excludeSemantics: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 340,
                height: 340,
                child: AnimatedBuilder(
                  animation: _loop,
                  builder: (context, _) => CustomPaint(
                    painter: _OrbitPainter(still ? 0.15 : _loop.value),
                    child: Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: const BoxDecoration(
                          color: Palette.brown,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Glyph(barsSvg(), size: 58),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const Wordmark(big: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.t);

  /// Posisi dalam satu putaran, 0 sampai 1.
  final double t;

  static const _orbit = 138.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);

    Paint line(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;

    // Tiga cincin berdenyut keluar, masing-masing bergeser sepertiga putaran.
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      canvas.drawCircle(
        c,
        90 + p * 80,
        line(Palette.tan.withValues(alpha: (1 - p) * 0.55), 1.6),
      );
    }

    canvas.drawCircle(c, _orbit, line(Palette.edge, 1.6));
    canvas.drawCircle(c, 108, line(Palette.tan, 1.6));
    canvas.drawCircle(c, 82, Paint()..color = Palette.cream);

    final head = t * 2 * math.pi - math.pi / 2;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: _orbit),
      head - math.pi / 2,
      math.pi / 2,
      false,
      line(Palette.brown, 4)..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      c + Offset(math.cos(head), math.sin(head)) * _orbit,
      7,
      Paint()..color = Palette.brown,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t;
}
