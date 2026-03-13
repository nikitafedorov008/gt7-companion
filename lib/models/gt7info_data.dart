class GT7InfoData {
  final String updateTimestamp;
  final UsedCarData used;
  final LegendCarData legend;

  GT7InfoData({
    required this.updateTimestamp,
    required this.used,
    required this.legend,
  });

  factory GT7InfoData.fromJson(Map<String, dynamic> json) {
    return GT7InfoData(
      updateTimestamp: json['updatetimestamp'] ?? '',
      used: UsedCarData.fromJson(json['used'] ?? {}),
      legend: LegendCarData.fromJson(json['legend'] ?? {}),
    );
  }
}

class UsedCarData {
  final String date;
  final List<CarData> cars;

  UsedCarData({required this.date, required this.cars});

  factory UsedCarData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> carsJson = json['cars'] ?? [];
    final cars = carsJson.map((car) => CarData.fromJson(car)).toList();

    return UsedCarData(date: json['date'] ?? '', cars: cars);
  }
}

class LegendCarData {
  final String date;
  final List<CarData> cars;

  LegendCarData({required this.date, required this.cars});

  factory LegendCarData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> carsJson = json['cars'] ?? [];
    final cars = carsJson.map((car) => CarData.fromJson(car)).toList();

    return LegendCarData(date: json['date'] ?? '', cars: cars);
  }
}

class CarData {
  final String carId;
  final String manufacturer;
  final String region;
  final String name;
  final int credits;
  final String state;
  final int estimateDays;
  final int maxEstimateDays;
  final bool isNew;
  final RewardCarData? rewardCar;
  final EngineSwapData? engineSwap;
  final String? lotteryCar;
  final String? trophyCar;

  CarData({
    required this.carId,
    required this.manufacturer,
    required this.region,
    required this.name,
    required this.credits,
    required this.state,
    required this.estimateDays,
    required this.maxEstimateDays,
    required this.isNew,
    this.rewardCar,
    this.engineSwap,
    this.lotteryCar,
    this.trophyCar,
  });

  factory CarData.fromJson(Map<String, dynamic> json) {
    return CarData(
      carId: json['carid'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      region: json['region'] ?? '',
      name: json['name'] ?? '',
      credits: json['credits'] ?? 0,
      state: json['state'] ?? '',
      estimateDays: json['estimatedays'] ?? 0,
      maxEstimateDays: json['maxestimatedays'] ?? 0,
      isNew: json['new'] ?? false,
      rewardCar: json['rewardcar'] != null
          ? RewardCarData.fromJson(json['rewardcar'])
          : null,
      engineSwap: json['engineswap'] != null
          ? EngineSwapData.fromJson(json['engineswap'])
          : null,
      lotteryCar: json['lotterycar'],
      trophyCar: json['trophycar'],
    );
  }

  String get flagUrl => 'https://flagcdn.com/h24/$region.png';

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
}

class RewardCarData {
  final String type;
  final String name;
  final String? requirement;

  RewardCarData({required this.type, required this.name, this.requirement});

  factory RewardCarData.fromJson(Map<String, dynamic> json) {
    return RewardCarData(
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      requirement: json['requirement'],
    );
  }

  String get rewardText {
    if (type == 'menubook') {
      return 'Reward from Menu Book $name';
    } else if (type == 'mission') {
      final req = requirement != null ? ' All $requirement' : '';
      return 'Reward from Mission Set: $name$req';
    } else if (type == 'license') {
      final req = requirement != null ? ' All $requirement' : '';
      return 'Reward from License: $name$req';
    }
    return 'Reward';
  }
}

class EngineSwapData {
  final String carId;
  final String manufacturer;
  final String region;
  final String name;
  final String engineName;

  EngineSwapData({
    required this.carId,
    required this.manufacturer,
    required this.region,
    required this.name,
    required this.engineName,
  });

  factory EngineSwapData.fromJson(Map<String, dynamic> json) {
    return EngineSwapData(
      carId: json['carid'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      region: json['region'] ?? '',
      name: json['name'] ?? '',
      engineName: json['enginename'] ?? '',
    );
  }

  String get swapInfoText {
    return 'Supports engine swap: $engineName from $name';
  }
}
