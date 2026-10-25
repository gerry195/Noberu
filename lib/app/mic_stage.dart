import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../flow/session.dart';
import 'glyphs.dart';
import 'theme.dart';
import 'wave_ribbon.dart';

/// Lingkaran mikrofon di tengah. Saat layar ditahan, lingkaran mengecil dan
/// pita gelombang melebar ke kiri dan kanan di belakangnya.
class MicStage extends StatelessWidget {
  const MicStage({super.key, required this.phase, required this.level});

  final Phase phase;
  final ValueListenable<double> level;

  static const _fast = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final active = phase == Phase.listening || phase == Phase.thinking;
    final cream = active ? 140.0 : 192.0;
    final disc = active ? 92.0 : 128.0;

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            Positioned.fill(child: WaveRibbon(phase: phase, level: level)),
          AnimatedContainer(
            duration: _fast,
            curve: Curves.easeOut,
            width: cream,
            height: cream,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Palette.cream,
              shape: BoxShape.circle,
              border: active ? Border.all(color: Colors.white, width: 10) : null,
            ),
            child: AnimatedContainer(
              duration: _fast,
              curve: Curves.easeOut,
              width: disc,
              height: disc,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Palette.brown,
                shape: BoxShape.circle,
              ),
              child: Glyph(micSvg(), size: disc * 0.47),
            ),
          ),
        ],
      ),
    );
  }
}
