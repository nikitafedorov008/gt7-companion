// START_MODULE_CONTRACT
// PURPOSE: Preserve showroom navigation, filters, language and gallery state.
// SCOPE: Composition of official metadata and lazily resolved gallery frames.
// DEPENDS: M-MODEL-BRAND-CENTRAL, M-SERVICE-BRAND-CENTRAL
// LINKS: M-REPO-BRAND-CENTRAL, V-M-REPO-BRAND-CENTRAL
// END_MODULE_CONTRACT
// START_MODULE_MAP
// BrandCentralRepository - catalogue presentation and asynchronous selection safety.
// END_MODULE_MAP
import 'package:flutter/foundation.dart';
import '../models/brand_central/brand_central_data.dart';
import '../services/brand_central_service.dart';
import '../services/app_settings_service.dart';

enum ShowroomSort { name, performance, power }

class BrandCentralRepository extends ChangeNotifier {
  BrandCentralRepository(this._service, {AppSettingsService? appSettings})
    : _appSettings = appSettings {
    _appSettings?.addListener(_localeChanged);
  }
  final AppSettingsService? _appSettings;
  void _localeChanged() {
    if (!_disposed) notifyListeners();
  }

  final BrandCentralService _service;
  BrandCentralData? data;
  bool isLoading = false;
  String? error;
  String languageChoice = 'system';
  String _systemLanguage = 'en';
  String get language =>
      _appSettings?.effectiveLocale.languageCode ??
      (languageChoice == 'system' ? _systemLanguage : languageChoice);
  String region = 'All regions';
  bool regionChosen = false;
  String query = '';
  ShowroomSort sort = ShowroomSort.name;
  String? brandId;
  bool allCars = false;
  String? carId;
  List<String> photos = const [];
  String? galleryError;
  bool galleryLoading = false;
  int _request = 0;
  bool _disposed = false;
  Future<void> load() async {
    if (data != null || isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      data = await _service.load();
    } catch (e) {
      error = 'Catalogue unavailable. Please retry.';
      debugPrint('BrandCentralRepository: $e');
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void setSystemLanguage(String locale) {
    final value = locale == 'ru' ? 'ru' : 'en';
    if (_systemLanguage == value) return;
    _systemLanguage = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    languageChoice = value;
    notifyListeners();
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  void setRegion(String value) {
    region = value;
    notifyListeners();
  }

  void chooseRegion(String value) {
    region = value;
    regionChosen = true;
    query = '';
    notifyListeners();
  }

  void setSort(ShowroomSort value) {
    sort = value;
    notifyListeners();
  }

  void openBrand(String? id) {
    brandId = id;
    allCars = id == null;
    notifyListeners();
  }

  bool back() {
    if (carId != null) {
      carId = null;
      photos = const [];
      galleryError = null;
      galleryLoading = false;
      _request++;
    } else if (brandId != null || allCars) {
      brandId = null;
      allCars = false;
    } else if (regionChosen) {
      regionChosen = false;
      region = 'All regions';
    } else {
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<void> selectCar(String id) async {
    if (!(data?.editions[language]?.containsKey(id) ?? false)) return;
    carId = id;
    photos = const [];
    await retryGallery();
  }

  Future<void> retryGallery() async {
    final id = carId;
    if (id == null) return;
    final request = ++_request;
    galleryLoading = true;
    galleryError = null;
    notifyListeners();
    try {
      final loaded = await _service.gallery(data!.gallery[id] ?? const []);
      if (!_disposed && request == _request) photos = loaded;
    } catch (e) {
      if (!_disposed && request == _request) {
        galleryError =
            'Gallery unavailable. Your catalogue and history are still available.';
      }
      debugPrint('BrandCentralRepository: gallery $e');
    } finally {
      if (!_disposed && request == _request) {
        galleryLoading = false;
        notifyListeners();
      }
    }
  }

  ShowroomCar? get selectedCar => data?.editions[language]?[carId];
  ShowroomBrand? get selectedBrand => data?.brands[brandId];
  List<ShowroomBrand> get brands {
    final result = (data?.brands.values ?? <ShowroomBrand>[]).where((brand) {
      if (region != 'All regions' && brand.region != region) return false;
      final needle = query.toLowerCase().trim();
      return brand.name.toLowerCase().contains(needle) ||
          (data?.editions[language]?.values.any(
                (car) =>
                    car.brandId == brand.id &&
                    car.name.toLowerCase().contains(needle),
              ) ??
              false);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  int count(String id) =>
      data?.editions[language]?.values.where((c) => c.brandId == id).length ??
      0;
  List<ShowroomCar> get cars {
    final result = (data?.editions[language]?.values ?? <ShowroomCar>[]).where((
      car,
    ) {
      if (brandId != null && car.brandId != brandId) return false;
      final brand = data!.brands[car.brandId]!;
      if (region != 'All regions' && brand.region != region) return false;
      final needle = query.toLowerCase().trim();
      return '${car.name} ${brand.name}'.toLowerCase().contains(needle);
    }).toList();
    result.sort((a, b) {
      final order = switch (sort) {
        ShowroomSort.name => a.name.compareTo(b.name),
        ShowroomSort.performance => b.pp.compareTo(a.pp),
        ShowroomSort.power =>
          b.number('power_v').compareTo(a.number('power_v')),
      };
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return result;
  }

  @override
  void dispose() {
    _appSettings?.removeListener(_localeChanged);
    _disposed = true;
    _request++;
    super.dispose();
  }
}
