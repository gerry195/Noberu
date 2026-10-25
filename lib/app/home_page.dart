import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../flow/session.dart';
import 'theme.dart';
import 'wave_ribbon.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Session _session = Session();
  int? _pointer;

  @override
  void initState() {
    super.initState();
    _session.start();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: 'Noberu. Tahan layar lalu bicara, lepas untuk mengirim. '
          'Dengan TalkBack, ketuk dua kali untuk mulai merekam dan ketuk dua kali lagi untuk mengirim.',
      onTap: _session.toggleCapture,
      customSemanticsActions: {
        CustomSemanticsAction(label: 'Ulangi jawaban terakhir'):
            _session.repeatLast,
      },
      child: ExcludeSemantics(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            if (_pointer != null) return;
            _pointer = e.pointer;
            _session.touchDown();
          },
          onPointerUp: (e) {
            if (e.pointer != _pointer) return;
            _pointer = null;
            _session.touchUp();
          },
          onPointerCancel: (e) {
            if (e.pointer != _pointer) return;
            _pointer = null;
            _session.touchCancel();
          },
          child: ListenableBuilder(
            listenable: _session,
            builder: (context, _) => _Board(session: _session),
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final phase = session.phase;
    final empty = session.headline.isEmpty;

    final String headline;
    final String detail;
    switch (phase) {
      case Phase.listening:
        headline = 'Bicara\nsekarang.';
        detail = 'Lepas jari saat selesai.';
      case Phase.thinking:
        headline = 'Sebentar,\nmencari.';
        detail = '';
      default:
        headline = empty ? 'Tahan layar,\nlalu bicara.' : session.headline;
        detail = empty
            ? 'Ketuk dua kali untuk mengulang jawaban terakhir.'
            : session.detail;
    }

    final showHeard = session.heard.isNotEmpty &&
        phase != Phase.listening &&
        phase != Phase.thinking;

    return ColoredBox(
      color: Palette.ground,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final ribbonHeight = (box.maxHeight * 0.34).clamp(160.0, 320.0).toDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: Text('Noberu',
                      style: NoberuType.wordmark.copyWith(color: Palette.ink)),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      height: ribbonHeight,
                      width: double.infinity,
                      child: WaveRibbon(phase: phase, level: session.level),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: box.maxHeight * 0.5),
                  child: SingleChildScrollView(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showHeard) ...[
                            Text('“${session.heard}”',
                                style: NoberuType.heard
                                    .copyWith(color: Palette.inkSoft)),
                            const SizedBox(height: 20),
                          ],
                          Text(
                            headline,
                            style: NoberuType.headline.copyWith(
                              color: phase == Phase.problem
                                  ? Palette.alert
                                  : Palette.ink,
                            ),
                          ),
                          if (detail.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(detail,
                                style: NoberuType.detail
                                    .copyWith(color: Palette.ink)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
