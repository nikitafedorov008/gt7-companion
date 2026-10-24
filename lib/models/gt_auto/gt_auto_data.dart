// START_MODULE_CONTRACT
// PURPOSE: Source-labelled workshop records and per-car build plans.
// SCOPE: Stock community specifications, swaps and special-part compatibility.
// DEPENDS: none
// LINKS: M-MODEL-GT-AUTO, V-M-MODEL-GT-AUTO
// END_MODULE_CONTRACT
// START_MODULE_MAP
// GtAutoSource - provenance for a fetched dataset
// GtAutoSpecs - community stock specifications, with explicit units
// GtAutoSwap - confirmed target and donor engine relationship
// GtPlusData - parsed cars and swaps
// GtAutoParts - tri-state special-part compatibility
// GtAutoPartsData - records and provenance
// GtAutoBuild - a user's plan, never installed game state
// END_MODULE_MAP

class GtAutoSource {
  const GtAutoSource({
    required this.name,
    required this.url,
    required this.fetchedAt,
  });
  final String name;
  final String url;
  final DateTime fetchedAt;
}

class GtAutoSpecs {
  const GtAutoSpecs({
    required this.carId,
    required this.name,
    this.powerHp,
    this.pp,
    this.weightKg,
    this.torqueKgfm,
    this.displacementCc,
    this.lengthMm,
    this.widthMm,
    this.heightMm,
    this.engine = '',
    this.engineType = '',
    this.country = '',
  });
  final String carId;
  final String name;
  final double? powerHp, pp, weightKg, torqueKgfm, displacementCc;
  final double? lengthMm, widthMm, heightMm;
  final String engine, engineType, country;

  factory GtAutoSpecs.fromJson(Map<String, dynamic> json) => GtAutoSpecs(
    carId: 'car${(json['code'] as num).toInt()}',
    name: json['modelFull'] as String? ?? '',
    powerHp: number(json['power']),
    pp: number(json['pp']),
    weightKg: number(json['weight']),
    torqueKgfm: number(json['torque']),
    displacementCc: number(json['displaceCc']),
    lengthMm: number(json['carlength']),
    widthMm: number(json['width']),
    heightMm: number(json['height']),
    engine: json['engineModel'] as String? ?? '',
    engineType: json['engineType'] as String? ?? '',
    country: json['country'] as String? ?? '',
  );
}

class GtAutoSwap {
  const GtAutoSwap({
    required this.id,
    required this.carId,
    required this.engine,
    required this.donor,
    this.version = '',
    this.price,
    this.powerHp,
    this.pp,
    this.weightKg,
    this.torqueKgfm,
    this.displacementCc,
  });
  final String id, carId, engine, donor, version;
  final double? price, powerHp, pp, weightKg, torqueKgfm, displacementCc;
  factory GtAutoSwap.fromJson(
    Map<String, dynamic> json, {
    required String carId,
    required String donor,
  }) => GtAutoSwap(
    id: json['id'] as String,
    carId: carId,
    engine: json['name'] as String? ?? '',
    donor: donor,
    version: json['update'] as String? ?? '',
    price: number(json['price']),
    powerHp: number(json['power']),
    pp: number(json['pp']),
    weightKg: number(json['weight']),
    torqueKgfm: number(json['torque']),
    displacementCc: number(json['displace']),
  );
}

class GtPlusData {
  const GtPlusData({
    required this.specs,
    required this.swaps,
    required this.source,
  });
  final Map<String, GtAutoSpecs> specs;
  final List<GtAutoSwap> swaps;
  final GtAutoSource source;
}

class GtAutoParts {
  const GtAutoParts({required this.carName, required this.compatibility});
  final String carName;

  /// An empty or unrecognised cell is unknown, not an explicit incompatibility.
  final Map<String, bool?> compatibility;
}

class GtAutoPartsData {
  const GtAutoPartsData({required this.cars, required this.source});
  final List<GtAutoParts> cars;
  final GtAutoSource source;
}

class GtAutoBuild {
  const GtAutoBuild({this.swapId, this.parts = const [], this.notes = ''});
  final String? swapId;
  final List<String> parts;
  final String notes;
  factory GtAutoBuild.fromJson(Map<String, dynamic> json) => GtAutoBuild(
    swapId: json['swapId'] as String?,
    parts: (json['parts'] as List?)?.whereType<String>().toList() ?? const [],
    notes: json['notes'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {
    'swapId': swapId,
    'parts': parts,
    'notes': notes,
  };
}

double? number(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : null;
