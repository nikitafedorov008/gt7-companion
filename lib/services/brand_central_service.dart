// START_MODULE_CONTRACT
// PURPOSE: Read official catalogue snapshots and safely resolve photo modules.
// SCOPE: Asset decoding and HTTP for gran-turismo.com only.
// DEPENDS: M-MODEL-BRAND-CENTRAL
// LINKS: M-SERVICE-BRAND-CENTRAL, V-M-SERVICE-BRAND-CENTRAL
// END_MODULE_CONTRACT
// START_MODULE_MAP
// BrandCentralService - official asset catalogue and gallery source.
// END_MODULE_MAP
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/brand_central/brand_central_data.dart';

class BrandCentralService {
  BrandCentralService({http.Client? httpClient, AssetBundle? bundle})
    : _http = httpClient ?? http.Client(),
      _bundle = bundle ?? rootBundle;
  final http.Client _http;
  final AssetBundle _bundle;
  static const _base = 'https://www.gran-turismo.com';
  static const _timeout = Duration(seconds: 12);
  final Map<String, String> _photos = {};
  Future<BrandCentralData> load() async => BrandCentralData.fromJson(
    jsonDecode(await _bundle.loadString('assets/cars/brand_central.json'))
        as Map<String, dynamic>,
  );

  Future<List<String>> gallery(List<String> modules) async {
    // At most six frames per selected car, never thousands of photo requests.
    return Future.wait(
      modules.map((module) async {
        if (!RegExp(r'^car\d+_\d+_\d+-[A-Za-z0-9_-]+\.js$').hasMatch(module)) {
          throw const FormatException('Invalid gallery module');
        }
        if (_photos.containsKey(module)) return _photos[module]!;
        final response = await _http
            .get(Uri.parse('$_base/common/dist/gt7/carlist/assets/$module'))
            .timeout(_timeout);
        if (response.statusCode != 200) {
          throw StateError('Official gallery HTTP ${response.statusCode}');
        }
        return _photos[module] = photoUrl(response.body);
      }),
    );
  }

  static String photoUrl(String module) {
    final path = RegExp(
      r'[`"\x27](/common/dist/gt7/carlist/assets/[A-Za-z0-9_/-]+\.jpg)[`"\x27]',
    ).firstMatch(module)?.group(1);
    if (path == null) {
      throw const FormatException('Official gallery format changed');
    }
    return '$_base$path';
  }

  void dispose() => _http.close();
}
