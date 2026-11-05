// START_MODULE_CONTRACT
// PURPOSE: Join dealer rows to the exact official localized vehicle record.
// SCOPE: Bundled catalogue composition and unknown-preserving presentation.
// DEPENDS: M-SERVICE-BRAND-CENTRAL, M-MODEL-CAR
// LINKS: M-DEALER-CATALOG, V-M-DEALER-CATALOG
// END_MODULE_CONTRACT
// START_MODULE_MAP
// DealerCatalogRepository - official dealer presentation lookup.
// END_MODULE_MAP
import 'package:flutter/foundation.dart';
import '../models/brand_central/brand_central_data.dart';
import '../models/car_dealer/car.dart';
import '../models/car_dealer/dealer_car_details.dart';
import '../services/brand_central_service.dart';

class DealerCatalogRepository extends ChangeNotifier {
  DealerCatalogRepository(this._source);
  final BrandCentralService _source;
  BrandCentralData? _data;
  Future<void>? _loading;
  bool _disposed = false;
  String? error;
  bool get isLoaded => _data != null;

  Future<void> load({bool force = false}) {
    if (force && _data == null) _loading = null;
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      _data = await _source.load();
      error = null;
    } catch (e) {
      error = 'Official catalogue unavailable';
      debugPrint('DealerCatalogRepository: $e');
    }
    if (!_disposed) notifyListeners();
  }

  DealerCarDetails details(Car car, String language) {
    final id = DealerCarDetails.canonicalId(car.id);
    final record =
        _data?.editions[language.startsWith('ru') ? 'ru' : 'en']?[id];
    return DealerCarDetails(car, record, _data?.brands[record?.brandId]);
  }

  /// Country belongs to the exact car record, never a manufacturer-name guess.
  /// IDs and country labels are defined in assets/cars/brand_central.json.
  String countryCodeFor(String id) {
    final record = _data?.editions['en']?[DealerCarDetails.canonicalId(id)];
    return switch (record?.text('countryId')) {
      'carctry2' => 'jp',
      'carctry3' => 'us',
      'carctry4' => 'gb',
      'carctry5' => 'de',
      'carctry6' => 'fr',
      'carctry7' => 'it',
      'carctry9' => 'kr',
      'carctry12' => 'se',
      'carctry15' => 'at',
      'carctry19' => 'cz',
      'carctry20' => 'cn',
      _ => '',
    };
  }

  /// A rotated-out saved vehicle still has a name, local thumbnail and specs.
  /// Its old sale price and stock are deliberately not presented as current.
  Car? savedCar(String id, Iterable<Car> inventory) {
    for (final car in inventory) {
      if (DealerCarDetails.canonicalId(car.id) == id) return car;
    }
    final record = _data?.editions['en']?[id];
    if (record == null) return null;
    return Car(
      id: id,
      name: record.name,
      shortName: record.name,
      manufacturer: _data?.brands[record.brandId]?.name ?? '',
      region: countryCodeFor(id),
      credits: 0,
      state: 'unknown',
      estimateDays: 0,
      maxEstimateDays: 0,
      isNew: false,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
