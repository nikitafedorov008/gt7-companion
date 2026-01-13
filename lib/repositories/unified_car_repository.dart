import 'package:flutter/foundation.dart';
import '../models/unified_car_data.dart';
import '../services/gt7info_service.dart';
import '../services/gtdb_service.dart';
import '../models/gt7info_data.dart';
import '../models/used_car.dart';
import '../models/legendary_car.dart';

class UnifiedCarRepository extends ChangeNotifier {
  final GT7InfoService _gt7InfoService;
  final GTDBService _gtdbService;

  List<UnifiedCarData> _allCars = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UnifiedCarData> get allCars => _allCars;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UnifiedCarRepository(this._gt7InfoService, this._gtdbService);

  Future<void> fetchAllCars({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch data from both services
      await _gt7InfoService.fetchGT7InfoData(forceRefresh: forceRefresh);
      await _gtdbService.fetchGTDBData(forceRefresh: forceRefresh);

      // Combine data from both sources
      final gt7InfoCars = _extractGT7InfoCars();
      final gtdbCars = _extractGTDBCars();

      // Combine and deduplicate cars
      final combinedCars = <String, UnifiedCarData>{};

      // Add GT7Info cars
      for (final car in gt7InfoCars) {
        final unifiedId = _generateUnifiedCarId(car.id);
        combinedCars[unifiedId] = car;
      }

      // Add GTDB cars, potentially updating existing entries with more information
      for (final car in gtdbCars) {
        final unifiedId = _generateUnifiedCarId(car.id);

        if (combinedCars.containsKey(unifiedId)) {
          // If car exists from both sources, merge information
          final existingCar = combinedCars[unifiedId]!;
          combinedCars[unifiedId] = _mergeCarData(existingCar, car);
        } else {
          combinedCars[unifiedId] = car;
        }
      }

      _allCars = combinedCars.values.toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error loading unified car data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<UnifiedCarData> _extractGT7InfoCars() {
    final cars = <UnifiedCarData>[];

    if (_gt7InfoService.data != null) {
      final gt7Data = _gt7InfoService.data!;

      // Add used cars
      for (final car in gt7Data.used.cars) {
        cars.add(_convertGT7InfoCarToUnified(car, 'gt7info_used'));
      }

      // Add legend cars
      for (final car in gt7Data.legend.cars) {
        cars.add(_convertGT7InfoCarToUnified(car, 'gt7info_legend'));
      }
    }

    return cars;
  }

  List<UnifiedCarData> _extractGTDBCars() {
    final cars = <UnifiedCarData>[];

    // Add used cars
    for (final car in _gtdbService.usedCars) {
      cars.add(_convertGTDBCarToUnifiedUsedCar(car, 'gtdb_used'));
    }

    // Add legend cars
    for (final car in _gtdbService.legendaryCars) {
      cars.add(_convertGTDBCarToUnifiedLegendaryCar(car, 'gtdb_legend'));
    }

    return cars;
  }

  UnifiedCarData _convertGT7InfoCarToUnified(CarData car, String source) {
    return UnifiedCarData(
      id: car.carId,
      name: car.name,
      shortName: car.name,
      manufacturer: car.manufacturer,
      region: car.region,
      credits: car.credits,
      state: car.state,
      estimateDays: car.estimateDays,
      maxEstimateDays: car.maxEstimateDays,
      isNew: car.isNew,
      rewardCar: car.rewardCar?.name,
      engineSwap: car.engineSwap?.engineName,
      lotteryCar: car.lotteryCar,
      trophyCar: car.trophyCar,
      source: source,
      imageId: null,
      frontImageId: null,
      sort: null,
      imageUrl: null, // GT7Info не предоставляет imageUrl
    );
  }

  UnifiedCarData _convertGTDBCarToUnifiedUsedCar(UsedCar car, String source) {
    String? imageUrl;
    if (car.imageId != null) {
      imageUrl = 'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/${car.imageId}/public';
    } else if (car.thumbnailImageId != null) {
      imageUrl = 'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/${car.thumbnailImageId}/public';
    }

    return UnifiedCarData(
      id: 'car${car.carIdFromDetails ?? car.id}', // Используем формат ID как в старой модели
      name: car.name ?? 'Unknown Car',
      shortName: car.shortName ?? car.name ?? 'Unknown',
      manufacturer: car.manufacturerName ?? 'Unknown',
      region: 'xx',
      credits: car.price ?? 0,
      state: car.state ?? 'normal',
      estimateDays: 0,
      maxEstimateDays: 0,
      isNew: car.state == 'new',
      rewardCar: null,
      engineSwap: null,
      lotteryCar: null,
      trophyCar: null,
      source: source,
      imageId: car.imageId,
      frontImageId: car.thumbnailImageId,
      sort: car.usedSort,
      imageUrl: imageUrl,
    );
  }

  UnifiedCarData _convertGTDBCarToUnifiedLegendaryCar(LegendaryCar car, String source) {
    String? imageUrl;
    if (car.frontImage != null) {
      imageUrl = 'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/${car.frontImage}/public';
    } else if (car.image != null) {
      imageUrl = 'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/${car.image}/public';
    }

    return UnifiedCarData(
      id: 'car${car.id}', // Используем формат ID как в старой модели
      name: car.name ?? 'Unknown Car',
      shortName: car.shortName ?? car.name ?? 'Unknown',
      manufacturer: car.manufacturerName ?? 'Unknown',
      region: 'xx',
      credits: car.price ?? 0,
      state: car.state ?? 'normal',
      estimateDays: 0,
      maxEstimateDays: 0,
      isNew: car.state == 'new',
      rewardCar: null,
      engineSwap: null,
      lotteryCar: null,
      trophyCar: null,
      source: source,
      imageId: car.image,
      frontImageId: car.frontImage,
      sort: car.sort,
      imageUrl: imageUrl,
    );
  }

  /// Generates a unified car ID that can be used to match cars from different sources
  /// The ID is normalized to remove prefixes like 'car' or '#CAR' to enable proper matching
  String _generateUnifiedCarId(String id) {
    // Remove 'car' prefix if present
    var normalizedId = id.toLowerCase();
    if (normalizedId.startsWith('car')) {
      normalizedId = normalizedId.substring(3);
    }

    // Remove '#CAR' prefix if present
    if (normalizedId.startsWith('#car')) {
      normalizedId = normalizedId.substring(4);
    }

    return normalizedId;
  }

  UnifiedCarData _mergeCarData(UnifiedCarData existing, UnifiedCarData newCar) {
    // При объединении данных мы будем использовать приоритеты:
    // 1. Если у одного из источников более полное имя - используем его
    // 2. Для цены и состояния - используем данные GTDB, если они доступны
    // 3. Для специальных атрибутов - объединяем информацию


    // Определяем приоритеты для объединения
    String name = existing.name;
    String shortName = existing.shortName;
    String manufacturer = existing.manufacturer;
    String state = existing.state;
    int credits = existing.credits;
    int estimateDays = existing.estimateDays;
    int maxEstimateDays = existing.maxEstimateDays;
    bool isNew = existing.isNew;
    String? rewardCar = existing.rewardCar;
    String? engineSwap = existing.engineSwap;
    String? lotteryCar = existing.lotteryCar;
    String? trophyCar = existing.trophyCar;
    String? imageId = existing.imageId;
    String? frontImageId = existing.frontImageId;
    int? sort = existing.sort;
    String? imageUrl = existing.imageUrl;

    // Если у нового источника есть более полезные данные, используем их
    if (newCar.name.isNotEmpty && (existing.name.isEmpty || _isMoreCompleteName(newCar.name, existing.name))) {
      name = newCar.name;
    }
    if (newCar.shortName.isNotEmpty && (existing.shortName.isEmpty || _isMoreCompleteName(newCar.shortName, existing.shortName))) {
      shortName = newCar.shortName;
    }
    if (newCar.manufacturer.isNotEmpty && existing.manufacturer.isEmpty) {
      manufacturer = newCar.manufacturer;
    }

    // Данные из GTDB обычно более точные для цены и состояния
    if (newCar.source?.contains('gtdb') ?? false) {
      if (newCar.credits != 0) credits = newCar.credits;
      if (newCar.state.isNotEmpty) state = newCar.state;
      if (newCar.estimateDays != 0) estimateDays = newCar.estimateDays;
      if (newCar.maxEstimateDays != 0) maxEstimateDays = newCar.maxEstimateDays;
      if (newCar.imageId != null) imageId = newCar.imageId;
      if (newCar.frontImageId != null) frontImageId = newCar.frontImageId;
      if (newCar.sort != null) sort = newCar.sort;
      if (newCar.imageUrl != null) imageUrl = newCar.imageUrl;
    }

    // Объединяем специальные атрибуты
    isNew = existing.isNew || newCar.isNew;
    rewardCar = existing.rewardCar ?? newCar.rewardCar;
    engineSwap = existing.engineSwap ?? newCar.engineSwap;
    lotteryCar = existing.lotteryCar ?? newCar.lotteryCar;
    trophyCar = existing.trophyCar ?? newCar.trophyCar;

    return UnifiedCarData(
      id: existing.id,
      name: name,
      shortName: shortName,
      manufacturer: manufacturer,
      region: existing.region != 'xx' ? existing.region : newCar.region,
      credits: credits,
      state: state,
      estimateDays: estimateDays,
      maxEstimateDays: maxEstimateDays,
      isNew: isNew,
      rewardCar: rewardCar,
      engineSwap: engineSwap,
      lotteryCar: lotteryCar,
      trophyCar: trophyCar,
      source: '${existing.source},${newCar.source}',
      imageId: imageId,
      frontImageId: frontImageId,
      sort: sort,
      imageUrl: imageUrl,
    );
  }

  /// Determines if the new name is more complete than the existing one
  bool _isMoreCompleteName(String newName, String existingName) {
    // Простая эвристика: если новое имя длиннее и содержит существующее, то оно более полное
    return newName.length > existingName.length && newName.toLowerCase().contains(existingName.toLowerCase());
  }

  List<UnifiedCarData> getCarsBySource(String source) {
    return _allCars.where((car) => car.source?.contains(source) ?? false).toList();
  }

  List<UnifiedCarData> getUsedCars() {
    return _allCars.where((car) => 
        car.source?.contains('used') ?? false
    ).toList();
  }

  List<UnifiedCarData> getLegendCars() {
    return _allCars.where((car) => 
        car.source?.contains('legend') ?? false
    ).toList();
  }
}