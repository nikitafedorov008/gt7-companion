import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gt_auto/gt_auto_data.dart';
import '../services/gt_auto_parts_service.dart';
import '../services/gtplus_service.dart';
import 'car_catalog.dart';

// START_MODULE_CONTRACT
// PURPOSE: Compose workshop data and persist independent per-car build plans.
// SCOPE: Exact joins, partial network failures, session cache, selection and plans.
// DEPENDS: M-SERVICE-GTPLUS, M-SERVICE-GT-AUTO-PARTS, M-MODEL-GT-AUTO
// LINKS: M-REPO-GT-AUTO, V-M-REPO-GT-AUTO
// END_MODULE_CONTRACT
// START_MODULE_MAP
// GtAutoRepository - workshop state, data composition and local persistence
// END_MODULE_MAP

class GtAutoRepository extends ChangeNotifier {
  GtAutoRepository(this.catalog, this._gtplus, this._partsService);
  final CarCatalog catalog;
  final GtPlusService _gtplus;
  final GtAutoPartsService _partsService;
  GtPlusData? _plus;
  GtAutoPartsData? _parts;
  final Map<String, GtAutoBuild> _builds = {};
  final Map<String, GtAutoParts> _partsByCar = {};
  final Map<String, String> _errors = {};
  bool _isLoading = false, _loaded = false, _disposed = false;
  String _selectedCarId = 'car1448';
  String? _storageError;
  SharedPreferences? _preferences;
  Future<void> _writeQueue = Future.value();

  bool get isLoading => _isLoading;
  Map<String, String> get errors => Map.unmodifiable(_errors);
  String? get storageError => _storageError;
  List<CarInfo> get cars => catalog.cars;
  CarInfo? get selectedCar => catalog.byId(_selectedCarId);
  GtAutoSpecs? get specs => _plus?.specs[_selectedCarId];
  GtAutoParts? get parts => _partsByCar[_selectedCarId];
  List<GtAutoSwap> get swaps =>
      _plus?.swaps.where((s) => s.carId == _selectedCarId).toList() ?? [];
  GtAutoBuild get build => _builds[_selectedCarId] ?? const GtAutoBuild();
  GtAutoSource? get swapSource => _plus?.source;
  GtAutoSource? get partsSource => _parts?.source;
  int get swapCount => _plus?.swaps.length ?? 0;

  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading || (_loaded && !forceRefresh)) return;
    _isLoading = true;
    _notify();
    if (!catalog.isLoaded) await catalog.load();
    if (!_loaded) {
      await _restore();
    }
    // Independent requests: an unavailable sheet must not discard good swaps.
    await Future.wait([
      () async {
        try {
          _plus = await _gtplus.fetch();
          _errors.remove('GTPlus');
        } catch (e) {
          _errors['GTPlus'] = 'Could not update specifications and swaps.';
          debugPrint('GtAutoRepository: GTPlus $e');
        }
      }(),
      () async {
        try {
          _parts = await _partsService.fetch();
          _errors.remove('Special parts');
        } catch (e) {
          _errors['Special parts'] =
              'Could not update special-parts compatibility.';
          debugPrint('GtAutoRepository: parts $e');
        }
      }(),
    ]);
    _joinParts();
    _loaded = true;
    _isLoading = false;
    _notify();
  }

  void selectCar(String id) {
    if (catalog.byId(id) == null || id == _selectedCarId) return;
    _selectedCarId = id;
    _notify();
    _persist();
  }

  void selectSwap(String? id) {
    if (id != null && !swaps.any((s) => s.id == id)) return;
    _builds[_selectedCarId] = GtAutoBuild(
      swapId: id,
      parts: build.parts,
      notes: build.notes,
    );
    _notify();
    _persist();
  }

  void setPart(String part, bool selected) {
    if (selected && parts?.compatibility[part] != true) return;
    final next = {...build.parts};
    if (selected) {
      next.add(part);
    } else {
      next.remove(part);
    }
    _builds[_selectedCarId] = GtAutoBuild(
      swapId: build.swapId,
      parts: next.toList(),
      notes: build.notes,
    );
    _notify();
    _persist();
  }

  void setNotes(String notes) {
    _builds[_selectedCarId] = GtAutoBuild(
      swapId: build.swapId,
      parts: build.parts,
      notes: notes,
    );
    _notify();
    _persist();
  }

  Future<void> flush() => _writeQueue;

  Future<void> _restore() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      final id = _preferences!.getString('gt_auto_car');
      if (id != null && catalog.byId(id) != null) _selectedCarId = id;
      final raw = _preferences!.getString('gt_auto_builds');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in map.entries) {
          if (entry.value is Map<String, dynamic>) {
            _builds[entry.key] = GtAutoBuild.fromJson(
              entry.value as Map<String, dynamic>,
            );
          }
        }
      }
    } catch (e) {
      _storageError = 'Could not restore saved workshop plans.';
      debugPrint('GtAutoRepository: restore $e');
    }
  }

  void _persist() {
    final car = _selectedCarId;
    final data = jsonEncode(
      _builds.map((id, build) => MapEntry(id, build.toJson())),
    );
    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = _preferences ??= await SharedPreferences.getInstance();
        if (!await prefs.setString('gt_auto_car', car) ||
            !await prefs.setString('gt_auto_builds', data)) {
          throw StateError('Preferences write failed');
        }
        _storageError = null;
      } catch (e) {
        _storageError = 'Plan changes could not be saved. Try again.';
        debugPrint('GtAutoRepository: save $e');
      }
      _notify();
    });
  }

  /// Case, whitespace and typographic apostrophes are the only normalisations.
  /// Do not strip punctuation/model suffixes: that would merge distinct cars.
  static String normalizeName(String name) => name
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('ʼ', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();

  void _joinParts() {
    _partsByCar.clear();
    final catalogNames = <String, List<CarInfo>>{};
    for (final car in cars) {
      (catalogNames[normalizeName(car.name)] ??= []).add(car);
    }
    final sourceNames = <String, List<GtAutoParts>>{};
    for (final part in _parts?.cars ?? <GtAutoParts>[]) {
      (sourceNames[normalizeName(part.carName)] ??= []).add(part);
    }
    for (final entry in sourceNames.entries) {
      final matches = catalogNames[entry.key];
      if (entry.value.length == 1 && matches?.length == 1) {
        _partsByCar[matches!.single.id] = entry.value.single;
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
