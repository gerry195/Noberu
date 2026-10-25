import '../data/forecast.dart';
import '../data/place_finder.dart';
import '../data/weather_glyph.dart';
import '../intent/intent_parser.dart';

enum Visual { none, weather, calendar, clock, pin }

class WeatherCard {
  const WeatherCard({
    required this.place,
    required this.when,
    required this.temp,
    required this.description,
    required this.glyph,
    required this.high,
    required this.low,
    this.humidity,
    this.windKmh,
    this.rainPct,
    this.note,
  });

  final String place;
  final String when;
  final int temp;
  final String description;
  final WeatherGlyph glyph;
  final int high;
  final int low;
  final int? humidity;
  final int? windKmh;
  final int? rainPct;
  final String? note;
}

class Answer {
  const Answer({
    required this.spoken,
    required this.headline,
    this.detail = '',
    this.visual = Visual.none,
    this.weather,
    this.dayNumber = 1,
    this.month = '',
    this.hour = 0,
    this.minute = 0,
  });

  final String spoken;
  final String headline;
  final String detail;
  final Visual visual;
  final WeatherCard? weather;
  final int dayNumber;
  final String month;
  final int hour;
  final int minute;
}

const _dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _monthShort = [
  'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
  'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES',
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
        spoken: rel != null ? '$rel hari $name.' : '$long jatuh pada hari $name.',
        headline: name,
        detail: rel == null ? long : '$rel · $long',
        visual: Visual.calendar,
        dayNumber: day.day,
        month: _monthShort[day.month - 1],
      );
    }
    return Answer(
      spoken: rel != null
          ? '$rel hari $name, tanggal $long.'
          : '$long jatuh pada hari $name.',
      headline: long,
      detail: rel == null ? name : '$rel · $name',
      visual: Visual.calendar,
      dayNumber: day.day,
      month: _monthShort[day.month - 1],
    );
  }

  Answer _clockTime() {
    final n = _clock();
    final h = n.hour;
    final m = n.minute;
    return Answer(
      spoken: m == 0 ? 'Pukul $h tepat.' : 'Pukul $h lewat $m menit.',
      headline: '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}',
      detail: '${dayName(n)}, ${fullDate(n)}',
      visual: Visual.clock,
      hour: h,
      minute: m,
    );
  }

  Future<Answer> _place(Intent intent) async {
    final name = intent.placeName;
    if (name != null) {
      final spot = await _places.find(name);
      final parts = (spot.label ?? name).split(', ');
      final where = parts.take(4).join(', ');
      return Answer(
        spoken: '$name berada di $where.',
        headline: _title(name),
        detail: where,
        visual: Visual.pin,
      );
    }
    final spot = await _places.here();
    final a = await _places.describe(spot);
    return Answer(
      spoken: 'Anda berada di ${a.spoken}.',
      headline: a.road ?? a.area ?? 'Posisi Anda',
      detail: a.road == null ? '' : a.withoutRoad,
      visual: Visual.pin,
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
    final rel = _relative(offset);
    final when = rel?.toLowerCase() ?? fullDate(day);
    final at = area == null ? '' : ' di $area';
    final sentences = <String>[];

    switch (w.basis) {
      case Basis.typical:
        sentences.add('Prakiraan untuk ${fullDate(day)}$at belum tersedia. '
            'Menurut data ${w.years} tahun terakhir, ${w.description.toLowerCase()}, '
            'suhu ${w.range} celsius');
      case Basis.observed:
        sentences.add(
            'Cuaca $when$at: ${w.description.toLowerCase()}, suhu ${w.range} celsius');
      case Basis.forecast:
        final current = w.nowC;
        sentences.add(offset == 0 && current != null
            ? 'Saat ini$at ${current.round()} derajat. Hari ini ${w.description.toLowerCase()}, suhu ${w.range} celsius'
            : 'Cuaca $when$at: ${w.description.toLowerCase()}, suhu ${w.range} celsius');
    }
    if (w.rain != null) sentences.add(w.rain!);

    final now = w.nowC;
    final temp = offset == 0 && now != null
        ? now.round()
        : ((w.minC + w.maxC) / 2).round();

    return Answer(
      spoken: '${sentences.join('. ')}.',
      headline: w.description,
      visual: Visual.weather,
      weather: WeatherCard(
        place: area ?? 'Lokasi Anda',
        when: rel ?? fullDate(day),
        temp: temp,
        description: w.description,
        glyph: w.glyph,
        high: w.maxC.round(),
        low: w.minC.round(),
        humidity: w.humidity,
        windKmh: w.windKmh,
        rainPct: w.rainPct,
        note: w.basis == Basis.typical
            ? 'Rata-rata ${w.years} tahun terakhir'
            : null,
      ),
    );
  }

  String _title(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
