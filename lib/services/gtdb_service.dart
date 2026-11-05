import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import '../models/car_dealer/legendary_car.dart';
import '../models/car_dealer/used_car.dart';

/// Public GTDB sources, with a bundled snapshot available before network work.
/// The obsolete api.playstationdb.com host no longer has a valid certificate.
class GTDBService extends ChangeNotifier {
  GTDBService({http.Client? httpClient, AssetBundle? bundle})
    : _http = httpClient ?? http.Client(),
      _bundle = bundle ?? rootBundle;
  final http.Client _http;
  final AssetBundle _bundle;
  static const usedUrl = 'https://gtdb.io/gt7/used-cars/';
  static const legendUrl =
      'https://gtdb.io/api/graphql_middleware/query/LegendCarsDealer';
  static const _timeout = Duration(seconds: 12);
  static const _headers = {'User-Agent': 'GT7Companion-CardPhotoAudit/1.0'};
  List<UsedCar> _usedCars = [];
  List<LegendaryCar> _legendaryCars = [];
  Map<String, dynamic> _links = {};
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;
  Future<void>? _bundled;

  List<UsedCar> get usedCars => _usedCars;
  List<LegendaryCar> get legendaryCars => _legendaryCars;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> loadBundled() => _bundled ??= _loadBundled();
  Future<void> _loadBundled() async {
    final data =
        jsonDecode(await _bundle.loadString('assets/cars/dealer_snapshot.json'))
            as Map<String, dynamic>;
    _links =
        jsonDecode(
              await _bundle.loadString('assets/cars/dealer_car_links.json'),
            )
            as Map<String, dynamic>;
    _usedCars = (data['gtdb_used'] as List)
        .map((r) => UsedCar.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
    _legendaryCars = (data['gtdb_legendary'] as List)
        .map((r) => LegendaryCar.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
    notifyListeners();
  }

  /// Accept only single-car grid cells with a real price. Promotional links and
  /// gallery images cannot become inventory rows. Unknown IDs are not guessed.
  static List<UsedCar> parseUsed(String body, Map<String, dynamic> links) {
    final document = html.parse(body);
    final cars = <String, UsedCar>{};
    for (final cell in document.querySelectorAll('div.grid.grid-cols-2')) {
      final anchors = cell.querySelectorAll('a[href^="/gt7/car/"]');
      final price = RegExp(r'Cr\.\s*([\d,]+)').firstMatch(cell.text);
      if (anchors.length != 1 || price == null) continue;
      final slug = Uri.parse(
        anchors.single.attributes['href']!,
      ).pathSegments.where((s) => s.isNotEmpty).last;
      final match =
          (links[slug] ??
                  links['name:${anchors.single.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}'])
              as Map<String, dynamic>?;
      if (match == null) continue;
      final id = (match['id'] as String).replaceFirst('car', '');
      final image = cell
          .querySelector('img[src*="imagedelivery.net"]')
          ?.attributes['src'];
      final imageId = image == null
          ? null
          : Uri.parse(image).pathSegments.reversed.skip(1).first;
      final text = cell.text;
      cars[id] = UsedCar.fromJson({
        'id': int.parse(id),
        'name': anchors.single.text.trim(),
        'short_name': anchors.single.text.trim(),
        'slug': slug,
        'manufacturer': {'name': match['manufacturer']},
        'details': {
          'id': '#CAR$id',
          'in_ucd': true,
          'used_price': int.parse(price.group(1)!.replaceAll(',', '')),
          'used_state': text.contains('SOLD OUT')
              ? 'soldout'
              : text.contains('Limited Stock')
              ? 'limited'
              : text.contains('NEW')
              ? 'new'
              : 'normal',
          if (imageId != null) 'used_car_image_id': imageId,
        },
      });
    }
    if (cars.isEmpty) {
      throw const FormatException(
        'GTDB used dealer markup changed or contains no mapped cars',
      );
    }
    return cars.values.toList();
  }

  Future<void> fetchGTDBData({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final errors = <String>[];
    try {
      if (_links.isEmpty) await loadBundled();
      await Future.wait([
        () async {
          try {
            final response = await _http
                .get(Uri.parse(usedUrl), headers: _headers)
                .timeout(_timeout);
            if (response.statusCode != 200) {
              throw StateError('Used HTTP ${response.statusCode}');
            }
            _usedCars = parseUsed(response.body, _links);
          } catch (error) {
            errors.add('Used: $error');
          }
        }(),
        () async {
          try {
            final response = await _http
                .get(Uri.parse(legendUrl), headers: _headers)
                .timeout(_timeout);
            if (response.statusCode != 200) {
              throw StateError('Legendary HTTP ${response.statusCode}');
            }
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final rows =
                (data['data'] as Map<String, dynamic>?)?['gt_car'] as List?;
            if (rows == null || rows.isEmpty) {
              throw const FormatException('GTDB legendary data missing');
            }
            _legendaryCars = rows
                .map(
                  (r) => LegendaryCar.fromJson(
                    Map<String, dynamic>.from(r as Map),
                  ),
                )
                .toList();
          } catch (error) {
            errors.add('Legendary: $error');
          }
        }(),
      ]);
      if (errors.length < 2) _lastUpdated = DateTime.now();
      _errorMessage = errors.isEmpty ? null : errors.join('; ');
    } catch (error) {
      _errorMessage = 'GTDB: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _http.close();
    super.dispose();
  }
}
