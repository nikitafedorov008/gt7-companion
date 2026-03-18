class UsedCar {
  final int id;
  final Map<String, dynamic>? details;
  final String? manufacturerName;
  final String? name;
  final String? shortName;
  final String? slug;
  final String? updatedAt;

  UsedCar({
    required this.id,
    this.details,
    this.manufacturerName,
    this.name,
    this.shortName,
    this.slug,
    this.updatedAt,
  });

  factory UsedCar.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>?;
    final manufacturer = json['manufacturer'] as Map<String, dynamic>?;

    return UsedCar(
      id: json['id'] ?? 0,
      details: details,
      manufacturerName: manufacturer?['name'],
      name: json['name'],
      shortName: json['short_name'],
      slug: json['slug'],
      updatedAt: json['updated_at'],
    );
  }

  // Helper getters for common properties from details
  String? get carIdFromDetails {
    if (details?['id'] != null) {
      final detailsId = details!['id'].toString();
      if (detailsId.startsWith('#CAR')) {
        return detailsId.substring(4); // Remove "#CAR" prefix to get the numeric ID
      }
    }
    return null;
  }

  String? get state => details?['used_state'];

  int? get price => details?['used_price'] ?? details?['price'];

  String? get imageId => details?['used_car_image_id'] ?? details?['thumbnail_image_id'];

  String? get thumbnailImageId => details?['thumbnail_image_id'];

  String? get maxPower => details?['max_power'];

  String? get maxTorque => details?['max_torque'];

  String? get aspiration => details?['aspiration'];

  String? get drivetrain => details?['drivetrain'];

  int? get displacement => details?['displacement'];

  int? get bhp => details?['bhp'];

  int? get weight => details?['kg'] ?? details?['weight'];

  int? get powerPerWeight => details?['pp'];

  int? get length => details?['length'];

  int? get width => details?['width'];

  int? get height => details?['height'];

  int? get distanceDriven => details?['distance_driven'];

  List<dynamic>? get tags => details?['tags'];

  String? get country => details?['country'];

  String? get manufacturer => details?['manufacturer'];

  bool get inUcd => details?['in_ucd'] == true;

  bool get usedCar => details?['used_car'] == true;

  int? get usedSort => details?['used_sort'];

  bool get brandCentral => details?['brand_central'] == true;
}