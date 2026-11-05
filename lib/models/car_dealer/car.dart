// car.dart

class Car {
  final String id;
  final String name;
  final String shortName;
  final String manufacturer;
  final String region;
  final int credits;
  final String state;
  final int estimateDays;
  final int maxEstimateDays;
  final bool isNew;
  final String? rewardCar;
  final String? engineSwap;
  final String? lotteryCar;
  final String? trophyCar;
  final String? source; // 'gt7info' or 'gtdb'
  final String? imageId; // from GTDB
  final String? frontImageId; // from GTDB
  final int? sort;

  // NEW: URL for the car image
  final String? imageUrl;

  Car({
    required this.id,
    required this.name,
    required this.shortName,
    required this.manufacturer,
    required this.region,
    required this.credits,
    required this.state,
    required this.estimateDays,
    required this.maxEstimateDays,
    required this.isNew,
    this.rewardCar,
    this.engineSwap,
    this.lotteryCar,
    this.trophyCar,
    this.source,
    this.imageId,
    this.frontImageId,
    this.sort,
    this.imageUrl, // NEW
  });

  /// Preserve inventory and artwork when enriching missing catalogue metadata.
  Car withRegion(String region) => Car(
    id: id,
    name: name,
    shortName: shortName,
    manufacturer: manufacturer,
    credits: credits,
    state: state,
    estimateDays: estimateDays,
    maxEstimateDays: maxEstimateDays,
    isNew: isNew,
    rewardCar: rewardCar,
    engineSwap: engineSwap,
    lotteryCar: lotteryCar,
    trophyCar: trophyCar,
    source: source,
    imageId: imageId,
    frontImageId: frontImageId,
    sort: sort,
    imageUrl: imageUrl,
    region: region,
  );

  String get flagUrl => RegExp(r'^[a-z]{2}$').hasMatch(region) && region != 'xx'
      ? 'https://flagcdn.com/h24/$region.png'
      : '';
  String get thumbnailUrl =>
      'https://www.gran-turismo.com/common/dist/gt7/carlist/car_thumbnails/car${id.replaceFirst(RegExp(r'^(?:car)+'), '')}.png';

  bool get isSoldOut => state == 'soldout';
  bool get isLimitedStock => state == 'limited';

  String get statusText {
    if (isSoldOut) return 'SOLD OUT';
    if (isLimitedStock) {
      return estimateDays <= 1
          ? 'Limited Stock Last Day Available'
          : 'Limited Stock Available For $estimateDays More Day${estimateDays > 1 ? 's' : ''}';
    }
    return 'Available For $estimateDays More Day${estimateDays > 1 ? 's' : ''}';
  }

  bool get hasSpecialAttributes =>
      isNew ||
      rewardCar != null ||
      engineSwap != null ||
      lotteryCar != null ||
      trophyCar != null;

  String get displayPrice => 'Cr. ${_formatCredits(credits)}';

  // NEW: Use imageUrl if available, fallback to GT7 image format
  String get carImageUrl {
    // First priority: use imageUrl if available
    if (imageUrl != null) return imageUrl!;

    // Second priority: for GTDB cars, use frontImageId if available (especially for legendary cars)
    if (source?.contains('gtdb') == true) {
      if (frontImageId != null && frontImageId!.isNotEmpty) {
        // Check if frontImageId is already a full URL or just an ID
        if (frontImageId!.startsWith('http')) {
          return frontImageId!;
        } else {
          return 'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/$frontImageId/public';
        }
      } else if (imageId != null && imageId!.isNotEmpty) {
        // Fallback to imageId if frontImageId is not available
        if (imageId!.startsWith('http')) {
          return imageId!;
        } else {
          return 'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/$imageId/public';
        }
      }
    }

    // Fallback to GT7Info format
    return thumbnailUrl;
  }

  String _formatCredits(int credits) {
    if (credits == 0) return '0';
    return credits.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
