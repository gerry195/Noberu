
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../flow/session.dart';
import 'theme.dart';

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

  static String _phaseLabel(Phase p) => switch (p) {
        Phase.idle => 'SIAP',
        Phase.listening => 'MENDENGARKAN',
        Phase.thinking => 'MENCARI',
        Phase.speaking => 'MENJAWAB',
        Phase.problem => 'ADA MASALAH',
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: 'Tutur. Tahan layar lalu bicara, lepas untuk mengirim. '
          'Dengan TalkBack, ketuk dua kali untuk mulai merekam dan '
          'ketuk dua kali lagi untuk mengirim.',
      onTap: _session.toggleCapture,
      customSemanticsActions: {
        CustomSemanticsAction(
          label: 'Ulangi jawaban terakhir',
        ): _session.repeatLast,
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
            builder: (context, _) => _Board(
              session: _session,
              label: _phaseLabel(_session.phase),
            ),
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.session,
    required this.label,
  });

  final Session session;
  final String label;

  @override
  Widget build(BuildContext context) {
    final listening = session.phase == Phase.listening;
    final problem = session.phase == Phase.problem;
    final bg = listening ? Palette.clay : Palette.paper;
    final fg = listening ? Palette.paper : Palette.ink;
    final accent = listening ? Palette.paper : Palette.clay;

    final empty = session.headline.isEmpty && !listening;

    final headline = listening
        ? 'Bicara\nsekarang.'
        : empty
            ? 'Tahan layar,\nlalu bicara.'
            : session.headline;

    final detail = listening
        ? 'Lepas jari saat selesai.'
        : empty
            ? 'Ketuk dua kali untuk mengulang jawaban terakhir.'
            : session.detail;

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tutur',
                    style: TuturType.wordmark.copyWith(color: fg),
                  ),
                  Text(
                    label,
                    style: TuturType.label.copyWith(color: accent),
                  ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (session.heard.isNotEmpty && !listening) ...[
                          Text(
                            '“${session.heard}”',
                            style: TuturType.heard.copyWith(
                              color: Palette.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          headline,
                          style: TuturType.headline.copyWith(
                            color: problem ? Palette.clay : fg,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          detail,
                          style: TuturType.detail.copyWith(color: fg),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: listening ? 10 : 4,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
