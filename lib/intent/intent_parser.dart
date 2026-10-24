enum Topic { day, date, time, weather, place }

class Intent {
  const Intent(this.topic, {this.date, this.placeName});

  final Topic topic;

  /// Null bila pengguna tidak menyebut hari tertentu (artinya hari ini).
  final DateTime? date;

  /// Null bila pengguna tidak menyebut tempat (artinya posisi sekarang).
  final String? placeName;
}

/// Mengubah kalimat hasil pengenalan suara menjadi [Intent].
class IntentParser {
  const IntentParser();

  static const _months = {
    'januari': 1,
    'februari': 2,
    'maret': 3,
    'april': 4,
    'mei': 5,
    'juni': 6,
    'juli': 7,
    'agustus': 8,
    'september': 9,
    'oktober': 10,
    'november': 11,
    'desember': 12,
  };

  static const _weekdays = {
    'senin': 1,
    'selasa': 2,
    'rabu': 3,
    'kamis': 4,
    'jumat': 5,
    'sabtu': 6,
    'minggu': 7,
    'ahad': 7,
  };

  static const _units = {
    'nol': 0,
    'satu': 1,
    'dua': 2,
    'tiga': 3,
    'empat': 4,
    'lima': 5,
    'enam': 6,
    'tujuh': 7,
    'delapan': 8,
    'sembilan': 9,
  };

  /// Tanggal yang sudah lewat lebih dari ini dianggap tahun depan.
  static const _pastWindowDays = 90;

  Intent? parse(String raw, DateTime now) {
    final text = _normalize(raw);
    final topic = _topicOf(text);
    if (topic == null) return null;

    final today = DateTime(now.year, now.month, now.day);
    final found = _takeDate(text, today);
    return Intent(
      topic,
      date: found.date,
      placeName: _placeIn(found.rest, topic),
    );
  }

  String _normalize(String raw) {
    var t = raw.toLowerCase().replaceAll("jum'at", 'jumat');
    t = t.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _wordsToDigits(t);
  }

  String _wordsToDigits(String text) {
    final w = text.split(' ');
    final out = <String>[];
    for (var i = 0; i < w.length; i++) {
      final cur = w[i];
      if (cur == 'sepuluh') {
        out.add('10');
        continue;
      }
      if (cur == 'sebelas') {
        out.add('11');
        continue;
      }
      final unit = _units[cur];
      if (unit == null) {
        out.add(cur);
        continue;
      }
      final next = i + 1 < w.length ? w[i + 1] : '';
      if (next == 'belas') {
        out.add('${10 + unit}');
        i++;
      } else if (next == 'puluh') {
        var n = unit * 10;
        i++;
        final extra = i + 1 < w.length ? _units[w[i + 1]] : null;
        if (extra != null && extra > 0) {
          n += extra;
          i++;
        }
        out.add('$n');
      } else {
        out.add('$unit');
      }
    }
    return out.join(' ');
  }

  bool _has(String text, String pattern) => RegExp(pattern).hasMatch(text);

  Topic? _topicOf(String t) {
    if (_has(t, r'\b(cuaca|hujan|gerimis|mendung|cerah|suhu|panas|dingin|berawan)\b')) {
      return Topic.weather;
    }
    if (_has(t, r'\b(lokasi|alamat|posisi|dimana|di mana|jalan apa)\b')) {
      return Topic.place;
    }
    if (_has(t, r'\b(jam berapa|pukul berapa|jam sekarang|waktu sekarang|sekarang jam)\b')) {
      return Topic.time;
    }
    if (_has(t, r'\bhari apa\b')) return Topic.day;
    if (_has(t, r'\b(tanggal|bulan|tahun|kalender)\b')) return Topic.date;
    if (_has(t, r'\bhari\b')) return Topic.day;
    if (_has(t, r'\bjam\b')) return Topic.time;
    return null;
  }

  /// Mengambil penyebutan hari dari [text] dan mengembalikan sisanya.
  ({DateTime? date, String rest}) _takeDate(String text, DateTime today) {
    var rest = text;
    DateTime? date;

    Match? take(String pattern) {
      final m = RegExp(pattern).firstMatch(rest);
      if (m != null) rest = rest.replaceRange(m.start, m.end, ' ');
      return m;
    }

    DateTime shift(int days) =>
        DateTime(today.year, today.month, today.day + days);

    if (take(r'\bkemarin (lusa|dulu)\b') != null) {
      date = shift(-2);
    } else if (take(r'\bkemarin\b') != null) {
      date = shift(-1);
    } else if (take(r'\blusa\b') != null) {
      date = shift(2);
    } else if (take(r'\bbesok\b') != null) {
      date = shift(1);
    }

    if (date == null) {
      final m = take(
          r'\b(\d{1,3}) hari (lagi|ke depan|kedepan|mendatang|lalu|yang lalu|sebelumnya)\b');
      if (m != null) {
        final n = int.parse(m.group(1)!);
        final past = m.group(2)!.contains('lalu') ||
            m.group(2)! == 'sebelumnya';
        date = shift(past ? -n : n);
      }
    }

    if (date == null) {
      final m = take(r'\bminggu (depan|lalu)\b');
      if (m != null) date = shift(m.group(1) == 'depan' ? 7 : -7);
    }

    if (date == null) {
      final m = take(
          r'\b(?:tanggal )?(\d{1,2}) (januari|februari|maret|april|mei|juni|juli|agustus|september|oktober|november|desember)(?: (\d{4}))?\b');
      if (m != null) {
        date = _calendarDate(
          int.parse(m.group(1)!),
          _months[m.group(2)!]!,
          m.group(3) == null ? null : int.parse(m.group(3)!),
          today,
        );
      }
    }

    if (date == null) {
      final m = take(r'\btanggal (\d{1,2})\b');
      if (m != null) {
        date = _calendarDate(int.parse(m.group(1)!), today.month, today.year, today);
      }
    }

    take(r'\bminggu ini\b');

    if (date == null) {
      final m = take(
          r'\b(?:hari )?(senin|selasa|rabu|kamis|jumat|sabtu|minggu|ahad)\b');
      if (m != null) {
        final ahead = (_weekdays[m.group(1)!]! - today.weekday + 7) % 7;
        date = shift(ahead);
      }
    }

    take(r'\b(hari ini|sekarang|nanti)\b');
    return (date: date, rest: rest.replaceAll(RegExp(r'\s+'), ' ').trim());
  }

  DateTime? _calendarDate(int day, int month, int? year, DateTime today) {
    DateTime build(int y) => DateTime(y, month, day);

    var d = build(year ?? today.year);
    if (d.month != month) return null;
    if (year == null &&
        d.isBefore(today.subtract(const Duration(days: _pastWindowDays)))) {
      d = build(today.year + 1);
    }
    return d.month == month ? d : null;
  }

  static const _fillers =
      r'\b(saya|aku|ini|sini|situ|sekarang|dong|ya|tolong|apa|berapa|hari|nih)\b';

  String? _placeIn(String rest, Topic topic) {
    final byLabel = RegExp(r'\b(?:lokasi|alamat|posisi|koordinat) (.+)$');
    final byDi = RegExp(r'\bdi (.+)$');
    final order = topic == Topic.place ? [byLabel, byDi] : [byDi, byLabel];

    for (final re in order) {
      final m = re.firstMatch(rest);
      if (m == null) continue;
      final name = m
          .group(1)!
          .replaceAll(RegExp(_fillers), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (name.isEmpty || name.startsWith('mana')) continue;
      return name;
    }
    return null;
  }
}
