import '../data/forecast.dart';
import '../data/place_finder.dart';
import '../intent/intent_parser.dart';

class Answer {
  const Answer({required this.spoken, required this.headline, this.detail = ''});

  final String spoken;
  final String headline;
  final String detail;
}

const _dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String dayName(DateTime d) => _dayNames[d.weekday - 1];
String fullDate(DateTime d) => '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

class Answerer {
  Answerer({
    PlaceFinder? places,
    ForecastClient? forecast,
    DateTime Function()? clock,
  })  : _places = places ?? PlaceFinder(),
        _forecast = forecast ?? ForecastClient(),
        _clock = clock ?? DateTime.now;

  final PlaceFinder _places;
  final ForecastClient _forecast;
  final DateTime Function() _clock;

  Future<Answer> reply(Intent intent) {
    switch (intent.topic) {
      case Topic.day:
      case Topic.date:
        return Future.value(_calendar(intent));
      case Topic.time:
        return Future.value(_clockTime());
      case Topic.place:
        return _place(intent);
      case Topic.weather:
        return _weather(intent);
    }
  }

  DateTime get _today {
    final n = _clock();
    return DateTime(n.year, n.month, n.day);
  }

  int _offset(DateTime day) => (day.difference(_today).inHours / 24).round();

  String? _relative(int offset) => switch (offset) {
        0 => 'Hari ini',
        1 => 'Besok',
        2 => 'Lusa',
        -1 => 'Kemarin',
        -2 => 'Kemarin lusa',
        _ => null,
      };

  Answer _calendar(Intent intent) {
    final day = intent.date ?? _today;
    final name = dayName(day);
    final rel = _relative(_offset(day));
    final long = fullDate(day);

    if (intent.topic == Topic.day) {
      return Answer(
        spoken: rel != null
            ? '$rel hari $name.'
            : '$long jatuh pada hari $name.',
        headline: name,
        detail: rel == null ? long : '$rel, $long',
      );
    }
    return Answer(
      spoken: rel != null
          ? '$rel hari $name, tanggal $long.'
          : '$long jatuh pada hari $name.',
      headline: long,
      detail: rel == null ? name : '$rel, $name',
    );
  }

  Answer _clockTime() {
    final n = _clock();
    final h = n.hour;
    final m = n.minute;
    final spoken =
        m == 0 ? 'Pukul $h tepat.' : 'Pukul $h lewat $m menit.';
    return Answer(
      spoken: spoken,
      headline: '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}',
      detail: '${dayName(n)}, ${fullDate(n)}',
    );
  }

  Future<Answer> _place(Intent intent) async {
    final name = intent.placeName;
    if (name != null) {
      final spot = await _places.find(name);
      final parts = (spot.label ?? name).split(', ');
      return Answer(
        spoken: '$name berada di ${parts.take(4).join(', ')}.',
        headline: _title(name),
        detail: parts.take(4).join(', '),
      );
    }
    final spot = await _places.here();
    final a = await _places.describe(spot);
    final where = a.spoken;
    return Answer(
      spoken: 'Anda berada di $where.',
      headline: a.road ?? a.area ?? 'Posisi Anda',
      detail: where,
    );
  }

  Future<Answer> _weather(Intent intent) async {
    final day = intent.date ?? _today;
    final named = intent.placeName;

    final Spot spot;
    String? area;
    if (named != null) {
      spot = await _places.find(named);
      area = _title(named);
    } else {
      spot = await _places.here();
      try {
        area = (await _places.describe(spot)).area;
      } catch (_) {
        // Nama wilayah hanya pelengkap kalimat; cuaca tetap bisa dibacakan.
      }
    }

    final w = await _forecast.forDay(spot.lat, spot.lon, day, _today);
    final offset = _offset(day);
    final when = _relative(offset)?.toLowerCase() ?? fullDate(day);
    final at = area == null ? '' : ' di $area';
    final sentences = <String>[];

    switch (w.basis) {
      case Basis.typical:
        sentences.add(
            'Prakiraan untuk ${fullDate(day)}$at belum tersedia. '
            'Menurut data ${w.years} tahun terakhir, ${w.description.toLowerCase()}, '
            'suhu ${w.range} celsius');
      case Basis.observed:
        sentences.add(
            'Cuaca $when$at: ${w.description.toLowerCase()}, suhu ${w.range} celsius');
      case Basis.forecast:
        final now = w.nowC;
        sentences.add(offset == 0 && now != null
            ? 'Saat ini$at ${now.round()} derajat. Hari ini ${w.description.toLowerCase()}, suhu ${w.range} celsius'
            : 'Cuaca $when$at: ${w.description.toLowerCase()}, suhu ${w.range} celsius');
    }
    if (w.rain != null) sentences.add(w.rain!);

    return Answer(
      spoken: '${sentences.join('. ')}.',
      headline: w.description,
      detail: [
        if (w.nowC != null && offset == 0) '${w.nowC!.round()}° sekarang',
        w.rangeShort,
        if (area != null) area,
        if (w.rain != null) w.rain!,
      ].join('\n'),
    );
  }

  String _title(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
