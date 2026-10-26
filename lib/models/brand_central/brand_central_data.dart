// START_MODULE_CONTRACT
// PURPOSE: Official manufacturer and localized car showroom records.
// SCOPE: Validated catalogue data and display values.
// DEPENDS: none
// LINKS: M-MODEL-BRAND-CENTRAL, V-M-MODEL-BRAND-CENTRAL
// END_MODULE_CONTRACT
// START_MODULE_MAP
// BrandCentralData - joined official catalogue editions and gallery modules.
// ShowroomCar - one car with source-labelled specifications and history.
// ShowroomBrand - manufacturer, country and geographic region.
// END_MODULE_MAP
import 'package:flutter/foundation.dart';

@immutable
class ShowroomBrand {
  const ShowroomBrand({
    required this.id,
    required this.name,
    required this.countryId,
    required this.country,
  });
  final String id;
  final String name;
  final String countryId;
  final String country;
  String get logoUrl =>
      'https://www.gran-turismo.com/common/dist/gt7/carlist/tuner_logos/dark/$id.png';
  // Country IDs and names are supplied by the official catalogue.
  String get region => switch (country) {
    'Japan' || 'South Korea' || 'China' || 'Australia' => 'Asia-Pacific',
    'U.S.' || 'United States' || 'Canada' => 'North America',
    'Other' => 'Other',
    'Italy' ||
    'Germany' ||
    'France' ||
    'United Kingdom' ||
    'Austria' ||
    'Sweden' ||
    'Czech Republic' => 'Europe',
    _ => 'Other',
  };
}

@immutable
class ShowroomCar {
  const ShowroomCar({required this.id, required this.values});
  final String id;
  final Map<String, dynamic> values;
  factory ShowroomCar.fromJson(String id, Map<String, dynamic> json) {
    if (!RegExp(r'^car\d+$').hasMatch(id) || json['id'] != id) {
      throw const FormatException('Invalid official car identifier');
    }
    return ShowroomCar(id: id, values: Map.unmodifiable(json));
  }
  String text(String key) => values[key] as String? ?? '';
  double number(String key) => double.tryParse('${values[key]}') ?? -1;
  String get name => text('nameLong');
  String get brandId => text('manufacturerId');
  String get history => text('desc');
  String get tagline => text('hero');
  String get thumbnail =>
      'https://www.gran-turismo.com/common/dist/gt7/carlist/car_thumbnails/$id.png';
  String sourceUrl(String language) =>
      'https://www.gran-turismo.com/${language == 'ru' ? 'ru' : 'us'}/gt7/carlist/id/$id';
  double get pp =>
      double.tryParse(
        text('performancePoint').replaceAll(RegExp(r'[^0-9.]'), ''),
      ) ??
      -1;
  Map<String, String> get specifications => {
    'Performance points': text('performancePoint'),
    'Category': text('carClass'),
    'Maximum power': text('maxPower'),
    'Maximum torque': text('maxTorque'),
    'Displacement': text('displacement'),
    'Weight': text('weight'),
    'Drivetrain': text('driveTrain'),
    'Aspiration': text('aspirationLong'),
    'Length': text('length'),
    'Width': text('width'),
    'Height': text('height'),
  };
}

@immutable
class BrandCentralData {
  const BrandCentralData({
    required this.editions,
    required this.brands,
    required this.gallery,
  });
  final Map<String, Map<String, ShowroomCar>> editions;
  final Map<String, ShowroomBrand> brands;
  final Map<String, List<String>> gallery;
  factory BrandCentralData.fromJson(Map<String, dynamic> json) {
    final editions = (json['editions'] as Map<String, dynamic>).map(
      (locale, value) => MapEntry(
        locale,
        (value as Map<String, dynamic>).map(
          (id, car) => MapEntry(
            id,
            ShowroomCar.fromJson(id, car as Map<String, dynamic>),
          ),
        ),
      ),
    );
    final countries = json['countries'] as Map<String, dynamic>;
    final brands = (json['brands'] as Map<String, dynamic>).map((id, value) {
      final cars = editions['en']!.values.where((car) => car.brandId == id);
      final countryId = cars.isEmpty
          ? 'carctry0'
          : cars.first.text('countryId');
      return MapEntry(
        id,
        ShowroomBrand(
          id: id,
          name: (value as Map<String, dynamic>)['name'] as String,
          countryId: countryId,
          country:
              (countries[countryId] as Map<String, dynamic>)['name'] as String,
        ),
      );
    });
    for (final edition in editions.values) {
      for (final car in edition.values) {
        if (!brands.containsKey(car.brandId) ||
            !countries.containsKey(car.text('countryId'))) {
          throw const FormatException(
            'Unresolved official catalogue reference',
          );
        }
      }
    }
    return BrandCentralData(
      editions: editions,
      brands: brands,
      gallery: (json['gallery'] as Map<String, dynamic>).map(
        (id, value) => MapEntry(id, List<String>.from(value as List)),
      ),
    );
  }
}
