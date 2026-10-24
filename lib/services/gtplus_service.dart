import 'dart:convert';

import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

import '../models/gt_auto/gt_auto_data.dart';

// START_MODULE_CONTRACT
// PURPOSE: Fetch GTPlus stock specifications and engine-swap records.
// SCOPE: Public Next.js Flight payload, reference resolution, validation, timeout.
// DEPENDS: M-MODEL-GT-AUTO
// LINKS: M-SERVICE-GTPLUS, V-M-SERVICE-GTPLUS
// END_MODULE_CONTRACT
// START_MODULE_MAP
// GtPlusService - fetch and parse the public engine-swaps source
// END_MODULE_MAP

class GtPlusService {
  GtPlusService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();
  final http.Client _http;
  static const sourceUrl = 'https://gtplus.app/gt7/engine-swaps';
  static const _timeout = Duration(seconds: 25);

  Future<GtPlusData> fetch() async {
    final response = await _http.get(Uri.parse(sourceUrl)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('GTPlus HTTP ${response.statusCode}');
    }
    return parse(utf8.decode(response.bodyBytes), fetchedAt: DateTime.now());
  }

  /// Flight chunks may split a JSON record between script tags. Join the
  /// transport stream first, then decode complete rows; never evaluate scripts.
  static GtPlusData parse(String source, {required DateTime fetchedAt}) {
    final stream = StringBuffer();
    for (final script in html.parse(source).querySelectorAll('script')) {
      for (final match in RegExp(
        r'self\.__next_f\.push\((\[.*?\])\)\s*;?',
        dotAll: true,
      ).allMatches(script.text)) {
        try {
          final chunk = jsonDecode(match.group(1)!) as List;
          if (chunk.length > 1 && chunk[0] == 1 && chunk[1] is String) {
            stream.write(chunk[1]);
          }
        } on FormatException {
          continue;
        }
      }
    }
    final rows = <String, dynamic>{};
    for (final line in const LineSplitter().convert(stream.toString())) {
      final colon = line.indexOf(':');
      if (colon < 1) continue;
      final id = line.substring(0, colon);
      if (!RegExp(r'^[0-9a-f]+$').hasMatch(id)) continue;
      try {
        rows[id] = jsonDecode(line.substring(colon + 1));
      } on FormatException {
        continue;
      }
    }
    final cars = <String, Map<String, dynamic>>{};
    final swaps = <String, Map<String, dynamic>>{};
    void visit(dynamic value) {
      if (value is Map<String, dynamic>) {
        if (value['entity'] == 'car' &&
            value['id'] is String &&
            value['code'] is num) {
          cars[value['id'] as String] = value;
        }
        if (value['entity'] == 'engine-swap' && value['id'] is String) {
          swaps[value['id'] as String] = value;
        }
        for (final child in value.values) {
          visit(child);
        }
      } else if (value is List) {
        for (final child in value) {
          visit(child);
        }
      }
    }

    for (final value in rows.values) {
      visit(value);
    }
    dynamic resolve(dynamic value) {
      final seen = <String>{};
      while (value is String && RegExp(r'^\$[0-9a-f]+$').hasMatch(value)) {
        if (!seen.add(value)) return null;
        value = rows[value.substring(1)];
      }
      return value;
    }

    final result = <GtAutoSwap>[];
    for (final swap in swaps.values) {
      final resolved = resolve(swap['car']);
      final car = resolved is Map<String, dynamic>
          ? resolved
          : cars[swap['carId']];
      if (car == null || car['code'] is! num) continue;
      cars[car['id'] as String] = car;
      final origin = resolve(swap['origin']);
      final donor = origin is Map<String, dynamic>
          ? origin
          : cars[swap['originId']];
      result.add(
        GtAutoSwap.fromJson(
          swap,
          carId: 'car${(car['code'] as num).toInt()}',
          donor:
              donor?['modelFull'] as String? ??
              swap['originId'] as String? ??
              'Unknown donor',
        ),
      );
    }
    if (result.isEmpty || cars.isEmpty) {
      throw const FormatException(
        'GTPlus structure changed: no confirmed swap records',
      );
    }
    return GtPlusData(
      specs: {
        for (final car in cars.values)
          'car${(car['code'] as num).toInt()}': GtAutoSpecs.fromJson(car),
      },
      swaps: List.unmodifiable(result),
      source: GtAutoSource(
        name: 'GTPlus',
        url: sourceUrl,
        fetchedAt: fetchedAt,
      ),
    );
  }

  void dispose() => _http.close();
}
