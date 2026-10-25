import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/problem.dart';
import '../flow/answerer.dart';
import '../flow/session.dart';
import 'brand.dart';
import 'glyphs.dart';
import 'mic_stage.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.ground,
      body: Semantics(
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
    final Widget body;
    if (phase == Phase.listening || phase == Phase.thinking) {
      body = _StageView(session: session);
    } else if (session.problem != null) {
      body = _ProblemView(problem: session.problem!);
    } else if (session.answer != null) {
      body = _ResultView(answer: session.answer!, heard: session.heard);
    } else {
      body = _StageView(session: session);
    }
    return SafeArea(
      child: Column(
        children: [
          const BrandHeader(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _NoteBar extends StatelessWidget {
  const _NoteBar(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.edge, width: 1.5),
      ),
      child: Row(
        children: [
          Glyph(checkSvg(), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: NoberuType.body.copyWith(fontSize: 16, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageView extends StatelessWidget {
  const _StageView({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final phase = session.phase;
    final String title;
    final String sub;
    switch (phase) {
      case Phase.listening:
        title = 'Mendengarkan';
        sub = 'Sampaikan pertanyaan Anda.\nLepas jari jika sudah selesai.';
      case Phase.thinking:
        title = 'Sebentar, mencari.';
        sub = '';
      default:
        title = 'Tahan layar, lalu bicara';
        sub = 'Lepas jari untuk mengirim.\nKetuk dua kali untuk mengulang jawaban.';
    }
    final ready = phase != Phase.listening && phase != Phase.thinking;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MicStage(phase: phase, level: session.level),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(title,
                        textAlign: TextAlign.center, style: NoberuType.title),
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(sub,
                          textAlign: TextAlign.center, style: NoberuType.body),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (ready)
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: _NoteBar('Tahan di mana saja pada layar. Tidak perlu mencari tombol.'),
          )
        else
          const SizedBox(height: 40),
      ],
    );
  }
}

class _ProblemView extends StatelessWidget {
  const _ProblemView({required this.problem});

  final Problem problem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 160,
              height: 160,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Palette.brown,
                shape: BoxShape.circle,
              ),
              child: Glyph(bangSvg(), size: 110),
            ),
            const SizedBox(height: 40),
            Text(problem.message,
                textAlign: TextAlign.center, style: NoberuType.title),
            const SizedBox(height: 12),
            Text(problem.hint,
                textAlign: TextAlign.center, style: NoberuType.body),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.answer, required this.heard});

  final Answer answer;
  final String heard;

  @override
  Widget build(BuildContext context) {
    final card = answer.visual == Visual.weather && answer.weather != null
        ? _WeatherCardView(card: answer.weather!)
        : _SimpleCard(answer: answer);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heard.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pertanyaanmu', style: NoberuType.label),
                        const SizedBox(height: 6),
                        Text('“$heard”', style: NoberuType.question),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                card,
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(answer.spoken, style: NoberuType.sentence),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: _NoteBar('Tahan layar untuk bertanya lagi.'),
        ),
      ],
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Palette.ground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.edge, width: 1.5),
      ),
      child: child,
    );
  }
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({required this.answer});

  final Answer answer;

  @override
  Widget build(BuildContext context) {
    final Widget icon;
    switch (answer.visual) {
      case Visual.calendar:
        icon = CalendarGlyph(day: answer.dayNumber, month: answer.month, size: 120);
      case Visual.clock:
        icon = Glyph(clockSvg(answer.hour, answer.minute), size: 120);
      default:
        icon = Glyph(pinSvg(), size: 120);
    }
    final long = answer.headline.length > 14;

    return _CardFrame(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 10),
          Text(
            answer.headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: long ? 34 : 46,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: Palette.ink,
            ),
          ),
          if (answer.detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              answer.detail,
              textAlign: TextAlign.center,
              style: NoberuType.body.copyWith(
                fontSize: 19,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeatherCardView extends StatelessWidget {
  const _WeatherCardView({required this.card});

  final WeatherCard card;

  @override
  Widget build(BuildContext context) {
    final stats = <Widget>[
      if (card.humidity != null)
        _Stat(dropSvg(), '${card.humidity}%', 'Kelembapan'),
      if (card.windKmh != null) _Stat(windSvg(), '${card.windKmh} km/j', 'Angin'),
      if (card.rainPct != null)
        _Stat(umbrellaSvg(), '${card.rainPct}%', 'Peluang hujan'),
    ];

    return _CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Glyph(pinSvg(ground: false), size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        card.place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Palette.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(card.when,
                  style: NoberuType.label.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${card.temp}',
                          style: const TextStyle(
                            fontSize: 68,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2,
                            color: Palette.ink,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 8, left: 2),
                          child: Text(
                            '°C',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Palette.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.description,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tertinggi ${card.high}°\nTerendah ${card.low}°',
                      style: NoberuType.body.copyWith(fontSize: 15, height: 1.3),
                    ),
                    if (card.note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(card.note!,
                            style: NoberuType.body.copyWith(fontSize: 15, height: 1.3)),
                      ),
                  ],
                ),
              ),
              Glyph(weatherSvg(card.glyph), size: 104),
            ],
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1.5, color: Palette.edge),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [for (final s in stats) Expanded(child: s)],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.svg, this.value, this.label);

  final String svg;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Glyph(svg, size: 30),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Palette.ink,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: NoberuType.body.copyWith(fontSize: 14.5, height: 1.2),
        ),
      ],
    );
  }
}
