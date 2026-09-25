import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One car from the official GT7 car list.
@immutable
class CarInfo {
  const CarInfo({
    required this.id,
    required this.name,
    required this.shortName,
    required this.manufacturerId,
    required this.carClass,
    required this.power,
    required this.weight,
    this.performancePoints = '',
    this.driveTrain = '',
    this.aspiration = '',
  });

  final String id;
  final String name;
  final String shortName;
  final String manufacturerId;
  final String carClass;
  final String power;
  final String weight;

  /// Performance point as the official catalogue prints it ("454.66"), the
  /// number every GT7 player watches.
  final String performancePoints;

  /// Drivetrain layout: FF, FR, MR, RR or 4WD. "---" for cars that do not
  /// declare one.
  final String driveTrain;

  /// Induction: NA, TC (turbo), SC (supercharged), EV, TC+SC.
  final String aspiration;
}

/// The car the telemetry packet is reporting, resolved from its id.
///
/// GT7's UDP packet carries the car id (offset 0x124) and nothing else about
/// the car, so the name and the photo have to come from a catalogue. This one
/// is generated from the official car list by `tools/fetch_gt7_cars.py` and
/// bundled as two small assets, so lookups cost no network:
///
///  * `assets/cars/cars.json` — id → name, maker, class, power, weight
///  * `assets/cars/car_images.json` — id → first official photo path
///
/// The photo path is a hashed asset on gran-turismo.com, so it is served from
/// there; re-run the script when Polyphony rebuilds the site.
class CarCatalog extends ChangeNotifier {
  static const String _carsAsset = 'assets/cars/cars.json';
  static const String _imagesAsset = 'assets/cars/car_images.json';
  static const String _imageBase = 'https://www.gran-turismo.com';

  Map<String, CarInfo> _cars = const {};
  Map<String, String> _photos = const {};
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  int get carCount => _cars.length;

  /// Loads both assets once; safe to call repeatedly.
  Future<void> load() async {
    if (_isLoading || _isLoaded) return;
    _isLoading = true;

    try {
      final results = await Future.wait([
        rootBundle.loadString(_carsAsset),
        rootBundle.loadString(_imagesAsset),
      ]);

      final carsJson = json.decode(results[0]) as Map<String, dynamic>;
      final photosJson = json.decode(results[1]) as Map<String, dynamic>;

      _cars = carsJson.map(
        (id, value) {
          final car = value as Map<String, dynamic>;
          return MapEntry(
            id,
            CarInfo(
              id: id,
              name: (car['name'] as String?) ?? '',
              shortName: (car['short'] as String?) ?? '',
              manufacturerId: (car['maker'] as String?) ?? '',
              carClass: (car['class'] as String?) ?? '',
              power: (car['power'] as String?) ?? '',
              weight: (car['weight'] as String?) ?? '',
              performancePoints: (car['pp'] as String?) ?? '',
              driveTrain: (car['drive'] as String?) ?? '',
              aspiration: (car['aspiration'] as String?) ?? '',
            ),
          );
        },
      );
      _photos = photosJson.map(
        (id, value) => MapEntry(id, value as String),
      );

      _isLoaded = true;
    } catch (error) {
      debugPrint('CarCatalog: failed to load the car catalogue: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// The packet reports a numeric car id; the catalogue keys are `car<id>`.
  CarInfo? byPacketId(int carId) => _cars['car$carId'];

  /// The official thumbnail of a car (320x180 PNG, ~35 KB).
  ///
  /// Derived from the id alone, so it needs no lookup, and the whole catalogue
  /// is covered by it. This is the same endpoint the car dealer grid uses.
  String thumbnailUrl(int carId) =>
      '$_imageBase/common/dist/gt7/carlist/car_thumbnails/car$carId.png';

  /// The full-bleed official photo (4K JPEG, ~1 MB), or null when the
  /// catalogue has none for the car. Too heavy for a HUD slot, so it is only
  /// used when [thumbnailUrl] fails.
  String? photoUrl(int carId) {
    final path = _photos['car$carId'];
    return path == null ? null : '$_imageBase$path';
  }
}
