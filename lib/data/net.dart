import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/problem.dart';

/// Nominatim mewajibkan User-Agent yang mengenali aplikasi.
const _headers = {'User-Agent': 'Noberu/1.0 (aplikasi asisten suara Android)'};

Future<Object?> getJson(Uri uri, {int seconds = 12}) async {
  final res = await http
      .get(uri, headers: _headers)
      .timeout(Duration(seconds: seconds));
  if (res.statusCode != 200) {
    throw const ProblemException(Problem.serviceFailed);
  }
  return jsonDecode(utf8.decode(res.bodyBytes));
}
