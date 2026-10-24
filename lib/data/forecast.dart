import '../core/problem.dart';
import 'net.dart';

enum Basis { forecast, observed, typical }

class DayWeather {
  const DayWeather({
    required this.description,
    required this.minC,
    required this.maxC,
    required this.basis,
    this.nowC,
    this.rain,
    this.years,
  });

  final String description;
  final double minC;
  final double maxC;
  final Basis basis;
  final double? nowC;
  final String? rain;

  /// Jumlah tahun arsip yang dipakai untuk [Basis.typical].
  final int? years;

  String get range => '${minC.round()} sampai ${maxC.round()} derajat';
  String get rangeShort => '${minC.round()}–${maxC.round()}°';
}

/// Open-Meteo: gratis dan tanpa kunci API.
class ForecastClient {
  static const maxAhead = 15;
  static const _forecastPastDays = 90;
  static const _typicalYears = 5;

  Future<DayWeather> forDay(double lat, double lon, DateTime day, DateTime today) {
    final offset = (day.difference(today).inHours / 24).round();
    if (offset > maxAhead) return _typical(lat, lon, day);
    return _daily(lat, lon, day, offset);
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<DayWeather> _daily(double lat, double lon, DateTime day, int offset) async {
    final archive = offset < -_forecastPastDays;
    final params = {
      'latitude': '$lat',
      'longitude': '$lon',
      'daily': archive
          ? 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum'
          : 'weather_code,temperature_2m_max,temperature_2m_min,'
              'precipitation_probability_max,precipitation_sum',
      'timezone': 'auto',
      'start_date': _ymd(day),
      'end_date': _ymd(day),
      if (offset == 0) 'current': 'temperature_2m',
    };
    final uri = Uri.https(
      archive ? 'archive-api.open-meteo.com' : 'api.open-meteo.com',
      archive ? '/v1/archive' : '/v1/forecast',
      params,
    );
    final data = await getJson(uri);
    final daily = data is Map ? data['daily'] : null;
    if (daily is! Map) throw const ProblemException(Problem.serviceFailed);

    num? first(String key) {
      final v = daily[key];
      return v is List && v.isNotEmpty && v.first is num ? v.first as num : null;
    }

    final hi = first('temperature_2m_max');
    final lo = first('temperature_2m_min');
    final code = first('weather_code');
    if (hi == null || lo == null || code == null) {
      throw const ProblemException(Problem.serviceFailed);
    }

    final prob = first('precipitation_probability_max');
    final sum = first('precipitation_sum');
    String? rain;
    if (prob != null) {
      rain = 'peluang hujan ${prob.round()} persen';
    } else if (sum != null) {
      rain = sum >= 1
          ? 'curah hujan sekitar ${sum.round()} milimeter'
          : 'hampir tidak ada hujan';
    }

    final current = data is Map ? data['current'] : null;
    final nowC = current is Map && current['temperature_2m'] is num
        ? (current['temperature_2m'] as num).toDouble()
        : null;

    return DayWeather(
      description: _describe(code.toInt()),
      minC: lo.toDouble(),
      maxC: hi.toDouble(),
      basis: offset < 0 ? Basis.observed : Basis.forecast,
      nowC: nowC,
      rain: rain,
    );
  }

  /// Rata-rata tanggal yang sama (plus minus tiga hari) dari arsip beberapa tahun.
  Future<DayWeather> _typical(double lat, double lon, DateTime day) async {
    final thisYear = DateTime.now().year;

    Future<List<List<num?>>> oneYear(int year) async {
      try {
        final mid = DateTime(year, day.month, day.day);
        final data = await getJson(
          Uri.https('archive-api.open-meteo.com', '/v1/archive', {
            'latitude': '$lat',
            'longitude': '$lon',
            'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum',
            'timezone': 'auto',
            'start_date': _ymd(mid.subtract(const Duration(days: 3))),
            'end_date': _ymd(mid.add(const Duration(days: 3))),
          }),
          seconds: 15,
        );
        final d = data is Map ? data['daily'] : null;
        if (d is! Map) return const [];
        final hi = d['temperature_2m_max'];
        final lo = d['temperature_2m_min'];
        final rain = d['precipitation_sum'];
        if (hi is! List || lo is! List || rain is! List) return const [];
        return [
          for (var i = 0; i < hi.length; i++)
            if (hi[i] is num && lo[i] is num)
              [hi[i] as num, lo[i] as num, rain[i] is num ? rain[i] as num : null],
        ];
      } catch (_) {
        // Satu tahun yang gagal diambil tidak membatalkan rata-ratanya.
        return const [];
      }
    }

    final perYear = await Future.wait([
      for (var i = 1; i <= _typicalYears; i++) oneYear(thisYear - i),
    ]);
    final days = perYear.expand((e) => e).toList();
    if (days.length < 7) throw const ProblemException(Problem.serviceFailed);

    final hi = days.map((e) => e[0]!).reduce((a, b) => a + b) / days.length;
    final lo = days.map((e) => e[1]!).reduce((a, b) => a + b) / days.length;
    final wet = days.where((e) => e[2] != null).toList();
    final wetShare = wet.isEmpty
        ? null
        : (100 * wet.where((e) => e[2]! >= 1).length / wet.length).round();

    final description = wetShare == null
        ? 'Data hujan tidak tersedia'
        : wetShare >= 60
            ? 'Biasanya hujan'
            : wetShare >= 30
                ? 'Kadang hujan'
                : 'Biasanya kering';

    return DayWeather(
      description: description,
      minC: lo,
      maxC: hi,
      basis: Basis.typical,
      rain: wetShare == null ? null : 'hujan turun sekitar $wetShare persen harinya',
      years: perYear.where((e) => e.isNotEmpty).length,
    );
  }

  String _describe(int code) {
    if (code == 0) return 'Cerah';
    if (code == 1) return 'Cerah berawan';
    if (code == 2) return 'Berawan sebagian';
    if (code == 3) return 'Berawan';
    if (code >= 45 && code <= 48) return 'Berkabut';
    if (code >= 51 && code <= 57) return 'Gerimis';
    if (code == 61 || code == 66 || code == 80) return 'Hujan ringan';
    if (code == 63 || code == 81) return 'Hujan sedang';
    if (code == 65 || code == 67) return 'Hujan lebat';
    if (code == 82) return 'Hujan deras';
    if (code >= 71 && code <= 77) return 'Salju';
    if (code >= 95) return 'Badai petir';
    return 'Cuaca tidak diketahui';
  }
}
