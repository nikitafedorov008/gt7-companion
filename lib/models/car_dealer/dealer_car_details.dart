import '../brand_central/brand_central_data.dart';
import 'car.dart';

/// An exact catalogue join. Stock comes from the dealer, specifications and
/// history from the official localized catalogue; mileage is never estimated.
class DealerCarDetails {
  const DealerCarDetails(this.car, this.record, this.brand);
  final Car car;
  final ShowroomCar? record;
  final ShowroomBrand? brand;

  static String canonicalId(String id) {
    final raw = id.replaceFirst(
      RegExp(r'^(?:#?car)+', caseSensitive: false),
      '',
    );
    return RegExp(r'^\d+$').hasMatch(raw) ? 'car$raw' : id;
  }

  String get id => canonicalId(car.id);
  Uri get priceHistoryUri => Uri.https(
    'ddm999.github.io',
    '/gt7info/cars/prices_${id.replaceFirst('car', '')}.png',
  );
  String get name => car.shortName.isNotEmpty ? car.shortName : car.name;
  String get manufacturer => brand?.name ?? car.manufacturer;
  String get history => record?.history ?? '';
  String get pp {
    final points = record?.pp ?? -1;
    return points < 0 ? '—' : points.toStringAsFixed(2);
  }

  String get drive => value(record?.text('driveTrain'));
  String get aspiration => value(record?.text('aspirationShort'));
  String? get logoUrl => brand?.logoUrl;
  String get thumbnailUrl =>
      'https://www.gran-turismo.com/common/dist/gt7/carlist/car_thumbnails/$id.png';
  String get year {
    final name = record?.name ?? car.name;
    final full = RegExp(r'\b(18\d{2}|19\d{2}|20\d{2})\b').firstMatch(name);
    if (full != null) return full[1]!;
    final short = RegExp(r"'(\d{2})$").firstMatch(name.trim());
    if (short == null) return '';
    final year = int.parse(short[1]!);
    return '${year <= DateTime.now().year % 100 ? 2000 + year : 1900 + year}';
  }

  static String value(String? text) =>
      text == null ||
          text.trim().isEmpty ||
          RegExp(r'^[-—]+$').hasMatch(text.trim())
      ? '—'
      : text;
  Map<String, String> get specifications => record?.specifications ?? const {};
  bool get hasPrice => car.credits > 0;
  bool get hasStock => car.state != 'unknown';
}
