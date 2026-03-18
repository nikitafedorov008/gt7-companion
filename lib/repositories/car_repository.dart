import 'package:flutter/foundation.dart';
import '../models/car_dealer/legendary_car.dart';
import '../models/car_dealer/car.dart';
import '../services/gt7info_service.dart';
import '../services/gtdb_service.dart';
import '../models/gt7info/gt7info_data.dart';
import '../models/car_dealer/used_car.dart';

class CarRepository extends ChangeNotifier {
  final GT7InfoService _gt7InfoService;
  final GTDBService _gtdbService;

  List<Car> _allCars = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Car> get allCars => _allCars;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CarRepository(this._gt7InfoService, this._gtdbService);

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
      final combinedCars = <String, Car>{};

      // Add GT7Info cars
      for (final car in gt7InfoCars) {
        final unifiedId = _generateUnifiedCarId(car.id);
        combinedCars[unifiedId] = car;
      }

      // Add GTDB cars
      for (final car in gtdbCars) {
        final unifiedId = _generateUnifiedCarId(car.id);

        // Проверяем, есть ли уже GT7Info car с тем же именем
        Car? matchingCarByname = _findMatchingCarByName(car, gt7InfoCars);

        // Для легендарных автомобилей из GTDB - добавляем только если есть совпадение в GT7Info
        if (car.source?.contains('gtdb_legend') ?? false) {
          if (matchingCarByname != null) {
            // Если нашли совпадение по имени, используем ID от GT7Info для объединения
            final gt7InfoUnifiedId = _generateUnifiedCarId(matchingCarByname.id);
            if (combinedCars.containsKey(gt7InfoUnifiedId)) {
              // Объединяем информацию
              final existingCar = combinedCars[gt7InfoUnifiedId]!;
              combinedCars[gt7InfoUnifiedId] = _mergeCarData(existingCar, car);
            } else {
              combinedCars[gt7InfoUnifiedId] = car;
            }
          }
          // Если нет совпадения в GT7Info, пропускаем этот легендарный автомобиль
        } else {
          // Для used cars используем обычную логику - добавляем если есть в GTDB
          if (matchingCarByname != null) {
            // Если нашли совпадение по имени, используем ID от GT7Info для объединения
            final gt7InfoUnifiedId = _generateUnifiedCarId(matchingCarByname.id);
            if (combinedCars.containsKey(gt7InfoUnifiedId)) {
              // Объединяем информацию
              final existingCar = combinedCars[gt7InfoUnifiedId]!;
              combinedCars[gt7InfoUnifiedId] = _mergeCarData(existingCar, car);
            } else {
              combinedCars[gt7InfoUnifiedId] = car;
            }
          } else if (combinedCars.containsKey(unifiedId)) {
            // If car exists from both sources with same ID, merge information
            final existingCar = combinedCars[unifiedId]!;
            combinedCars[unifiedId] = _mergeCarData(existingCar, car);
          } else {
            combinedCars[unifiedId] = car;
          }
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

  List<Car> _extractGT7InfoCars() {
    final cars = <Car>[];

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

  List<Car> _extractGTDBCars() {
    final cars = <Car>[];

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

  Car _convertGT7InfoCarToUnified(CarData car, String source) {
    return Car(
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

  Car _convertGTDBCarToUnifiedUsedCar(UsedCar car, String source) {
    String? imageUrl;
    if (car.imageId != null) {
      imageUrl = 'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/${car.imageId}/public';
    } else if (car.thumbnailImageId != null) {
      imageUrl = 'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/${car.thumbnailImageId}/public';
    }

    return Car(
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

  Car _convertGTDBCarToUnifiedLegendaryCar(LegendaryCar car, String source) {
    String? imageUrl;
    if (car.frontImage != null) {
      // Для legendary car всегда используем frontImage, как указано в требованиях
      imageUrl = 'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/${car.frontImage}/public';
    }

    return Car(
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

  Car _mergeCarData(Car existing, Car newCar) {
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

    return Car(
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

  /// Finds a matching car from GT7Info cars based on name comparison
  /// Used for legendary cars where IDs might differ but names should match
  Car? _findMatchingCarByName(Car gtdbCar, List<Car> gt7InfoCars) {
    // Проверяем, является ли GTDB автомобиль legendary car
    bool isGTDBLegendary = gtdbCar.source?.contains('gtdb_legend') ?? false;

    if (!isGTDBLegendary) {
      // Для used cars используем обычное сопоставление по ID
      return null;
    }

    // Для legendary cars ищем совпадение по имени
    for (final gt7InfoCar in gt7InfoCars) {
      bool isGT7InfoLegendary = gt7InfoCar.source?.contains('gt7info_legend') ?? false;

      if (isGT7InfoLegendary) {
        // Сравниваем имя из GT7Info (name) с именем из GTDB (shortName или name)
        String gt7InfoName = gt7InfoCar.name.toLowerCase().trim();

        // Используем полное имя из GTDB, но убираем из него название производителя
        String gtdbFullName = gtdbCar.name.toLowerCase().trim();
        String gtdbManufacturer = gtdbCar.manufacturer.toLowerCase().trim();

        // Убираем название производителя из полного имени
        String gtdbNameWithoutManufacturer = gtdbFullName.replaceFirst(RegExp('^${RegExp.escape(gtdbManufacturer)}\\s+'), '').trim();

        // Если после удаления производителя имя пустое, используем shortName
        String gtdbName = gtdbNameWithoutManufacturer.isNotEmpty
            ? gtdbNameWithoutManufacturer
            : (gtdbCar.shortName.isNotEmpty ? gtdbCar.shortName.toLowerCase().trim() : gtdbFullName);

        // Проверяем на точное совпадение или частичное совпадение
        if (gt7InfoName == gtdbName ||
            gt7InfoName.contains(gtdbName) ||
            gtdbName.contains(gt7InfoName)) {
          return gt7InfoCar;
        }
      }
    }

    return null;
  }

  List<Car> getCarsBySource(String source) {
    return _allCars.where((car) => car.source?.contains(source) ?? false).toList();
  }

  List<Car> getUsedCars() {
    return _allCars.where((car) => 
        car.source?.contains('used') ?? false
    ).toList();
  }

  List<Car> getLegendCars() {
    return _allCars.where((car) => 
        car.source?.contains('legend') ?? false
    ).toList();
  }
}