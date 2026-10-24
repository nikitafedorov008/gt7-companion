import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/gt_auto/gt_auto_data.dart';

// START_MODULE_CONTRACT
// PURPOSE: Fetch HRC Rolls special-part compatibility without inventing negatives.
// SCOPE: Public CSV export, quoted cells, schema validation and tri-state mapping.
// DEPENDS: M-MODEL-GT-AUTO
// LINKS: M-SERVICE-GT-AUTO-PARTS, V-M-SERVICE-GT-AUTO-PARTS
// END_MODULE_CONTRACT
// START_MODULE_MAP
// GtAutoPartsService - fetch and parse the community compatibility sheet
// END_MODULE_MAP

class GtAutoPartsService {
  GtAutoPartsService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();
  final http.Client _http;
  static const sourceUrl =
      'https://docs.google.com/spreadsheets/d/1XI_NeWovuYThKGf9nsqomwpUy_MCiheevohBmErvdHE/edit?gid=0';
  static const csvUrl =
      'https://docs.google.com/spreadsheets/d/1XI_NeWovuYThKGf9nsqomwpUy_MCiheevohBmErvdHE/export?format=csv&gid=0';
  static const partNames = [
    'Ultra-High RPM Turbo',
    'High-RPM S Supercharger',
    'Titanium Connecting Rods and Pistons',
    'Bore Up S',
    'Stroke Up S',
    'High Lift Camshaft S',
    'Carbon Propeller Shaft',
    'Stage 5 Weight Reduction',
  ];
  Future<GtAutoPartsData> fetch() async {
    final response = await _http
        .get(Uri.parse(csvUrl))
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception('Special parts HTTP ${response.statusCode}');
    }
    return parse(utf8.decode(response.bodyBytes), fetchedAt: DateTime.now());
  }

  static GtAutoPartsData parse(String source, {required DateTime fetchedAt}) {
    final rows = _csv(source);
    if (rows.isEmpty) throw const FormatException('Empty special-parts table');
    final header = rows.first.map((s) => s.trim()).toList();
    if (!partNames.every(header.contains)) {
      throw const FormatException('Special-parts columns changed');
    }
    final indices = {for (final name in partNames) name: header.indexOf(name)};
    final cars = <GtAutoParts>[];
    for (final row in rows.skip(1)) {
      if (row.length < header.length || row.first.trim().isEmpty) continue;
      final flags = <String, bool?>{};
      for (final entry in indices.entries) {
        flags[entry.key] = switch (row[entry.value].trim().toLowerCase()) {
          'yes' => true,
          'no' => false,
          _ => null,
        };
      }
      cars.add(GtAutoParts(carName: row.first.trim(), compatibility: flags));
    }
    if (cars.isEmpty) throw const FormatException('No special-parts records');
    return GtAutoPartsData(
      cars: List.unmodifiable(cars),
      source: GtAutoSource(
        name: 'HRC Rolls / hyperspeed980',
        url: sourceUrl,
        fetchedAt: fetchedAt,
      ),
    );
  }

  /// RFC 4180 essentials, including newlines and escaped quotes inside cells.
  static List<List<String>> _csv(String source) {
    final rows = <List<String>>[];
    var row = <String>[];
    var cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < source.length; i++) {
      final c = source[i];
      if (c == '"') {
        if (quoted && i + 1 < source.length && source[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && (c == ',' || c == '\n' || c == '\r')) {
        row.add(cell.toString());
        cell = StringBuffer();
        if (c != ',') {
          rows.add(row);
          row = [];
          if (c == '\r' && i + 1 < source.length && source[i + 1] == '\n') i++;
        }
      } else {
        cell.write(c);
      }
    }
    if (quoted) throw const FormatException('Unterminated CSV cell');
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }

  void dispose() => _http.close();
}
