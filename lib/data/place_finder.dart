import 'package:geolocator/geolocator.dart';

import '../core/problem.dart';
import 'net.dart';

class Spot {
  const Spot(this.lat, this.lon, {this.label});

  final double lat;
  final double lon;

  /// Alamat lengkap bila titik ini hasil pencarian nama tempat.
  final String? label;
}

class Address {
  const Address({this.road, this.quarter, this.district, this.city, this.region});

  final String? road;
  final String? quarter;
  final String? district;
  final String? city;
  final String? region;

  /// Nama wilayah paling kecil yang dikenal, untuk kalimat cuaca.
  String? get area => quarter ?? district ?? city;

  String get spoken => [road, quarter, district, city, region]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(', ');
}

class PlaceFinder {
  Future<Spot> here() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ProblemException(Problem.gpsOff);
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw const ProblemException(Problem.gpsDenied);
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Spot(p.latitude, p.longitude);
    } catch (_) {
      throw const ProblemException(Problem.gpsOff);
    }
  }

  /// Mencari nama tempat; Open-Meteo menjadi cadangan bila Nominatim kosong.
  Future<Spot> find(String name) async {
    final osm = await getJson(Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': name,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'id',
      'accept-language': 'id',
    }));
    if (osm is List && osm.isNotEmpty && osm.first is Map) {
      final hit = osm.first as Map;
      final lat = double.tryParse('${hit['lat']}');
      final lon = double.tryParse('${hit['lon']}');
      if (lat != null && lon != null) {
        return Spot(lat, lon, label: hit['display_name'] as String?);
      }
    }

    final geo = await getJson(Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': name,
      'count': '1',
      'language': 'id',
    }));
    final results = geo is Map ? geo['results'] : null;
    if (results is List && results.isNotEmpty && results.first is Map) {
      final hit = results.first as Map;
      final lat = (hit['latitude'] as num?)?.toDouble();
      final lon = (hit['longitude'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        final label = [hit['name'], hit['admin1'], hit['country']]
            .whereType<String>()
            .join(', ');
        return Spot(lat, lon, label: label);
      }
    }
    throw const ProblemException(Problem.placeNotFound);
  }

  Future<Address> describe(Spot spot) async {
    final data = await getJson(Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': '${spot.lat}',
      'lon': '${spot.lon}',
      'format': 'jsonv2',
      'zoom': '18',
      'addressdetails': '1',
      'accept-language': 'id',
    }));
    final a = data is Map ? data['address'] : null;
    if (a is! Map) throw const ProblemException(Problem.serviceFailed);

    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = a[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    return Address(
      road: pick(['road', 'pedestrian', 'footway']),
      quarter: pick(['suburb', 'village', 'neighbourhood', 'quarter']),
      district: pick(['city_district', 'subdistrict', 'district']),
      city: pick(['city', 'town', 'municipality', 'county', 'regency']),
      region: pick(['state']),
    );
  }
}
