import 'package:flutter/material.dart';

import 'glyphs.dart';
import 'theme.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.big = false});

  final bool big;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 3),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Palette.ink, width: 2.5)),
          ),
          child: Text(
            'noberu',
            style: NoberuType.wordmark.copyWith(fontSize: big ? 48 : 30),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '述べる',
          style: TextStyle(
            fontSize: big ? 26 : 19,
            fontWeight: FontWeight.w500,
            color: Palette.ink,
          ),
        ),
      ],
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          Positioned(left: 26, top: 14, child: Glyph(logoSvg(), size: 34)),
          const Align(alignment: Alignment.topCenter, child: Wordmark()),
        ],
      ),
    );
  }
}
