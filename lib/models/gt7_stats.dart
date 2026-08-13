/// Full player statistics from `POST web-api…/stats/get`.
///
/// Request body is `{"user_id":"…","year":<y>,"month":<m>}`, but the response
/// is lifetime data — the date only selects the history window used elsewhere.
///
/// Captured shape:
/// ```json
/// {"result":{
///   "car_life":{"buy_car_count":229,"buy_car_credit_amount":60638522,
///               "car_dictionary_progress":54,"customize_credit_amount":2611670,
///               "tuning_credit_amount":11413700},
///   "driving":{"average_fuel_consumption":4690,"driving_distance":44102177,
///              "driving_time":532648,"total_fuel_consumption":9402860},
///   "game_play":{"credit_amount":80011383,"photo_count":9,"play_time":1977296},
///   "gt_world":{"circuit_experience_progress":8,"drift_point":1049050,
///               "episode_progress":0},
///   "login_day_count":313,
///   "medal":{"bronze":19,"gold":1,"silver":1},
///   "profile":{"badge":5,"driver_level":66,"exp":99138170,"license":5},
///   "social":{"followers":29,"followings":25,"friends":0, …},
///   "sports_mode":{"clean_race_count":32,"fastest_lap_count":7,
///                  "pole_position_count":1,"race_count":174,"win_count":6},
///   "user":{…,"driver_rating":2,"sportsmanship_rating":6,"dr_point_ratio":0.4865}
/// }}
/// ```
class Gt7Stats {
  final Gt7CarLifeStats carLife;
  final Gt7DrivingStats driving;
  final Gt7GamePlayStats gamePlay;
  final Gt7GtWorldStats gtWorld;
  final Gt7MedalStats medals;
  final Gt7ProfileStats profile;
  final Gt7SocialStats social;
  final Gt7SportsModeStats sportsMode;

  /// Days the player has logged in.
  final int loginDayCount;

  /// Progress through the current driver-rating tier, 0.0 - 1.0.
  ///
  /// This is what the site renders as the DR bar width — 0.4865 showed up as
  /// `width: 48.65%` in the page HTML.
  final double driverRatingRatio;

  final int driverRating;
  final int sportsmanshipRating;

  const Gt7Stats({
    required this.carLife,
    required this.driving,
    required this.gamePlay,
    required this.gtWorld,
    required this.medals,
    required this.profile,
    required this.social,
    required this.sportsMode,
    required this.loginDayCount,
    required this.driverRatingRatio,
    required this.driverRating,
    required this.sportsmanshipRating,
  });

  factory Gt7Stats.fromJson(Map<String, dynamic> json) {
    final r = json['result'] as Map<String, dynamic>? ?? json;
    Map<String, dynamic> sub(String key) =>
        r[key] as Map<String, dynamic>? ?? const {};
    final user = sub('user');

    return Gt7Stats(
      carLife: Gt7CarLifeStats._(sub('car_life')),
      driving: Gt7DrivingStats._(sub('driving')),
      gamePlay: Gt7GamePlayStats._(sub('game_play')),
      gtWorld: Gt7GtWorldStats._(sub('gt_world')),
      medals: Gt7MedalStats._(sub('medal')),
      profile: Gt7ProfileStats._(sub('profile')),
      social: Gt7SocialStats._(sub('social')),
      sportsMode: Gt7SportsModeStats._(sub('sports_mode')),
      loginDayCount: _int(r['login_day_count']),
      driverRatingRatio: (user['dr_point_ratio'] as num?)?.toDouble() ?? 0,
      driverRating: _int(user['driver_rating'], fallback: -1),
      sportsmanshipRating: _int(user['sportsmanship_rating'], fallback: -1),
    );
  }

  static int _int(Object? v, {int fallback = 0}) =>
      (v as num?)?.toInt() ?? fallback;

  @override
  String toString() =>
      'Gt7Stats(cars: ${carLife.buyCarCount}, '
      '${driving.totalKm.toStringAsFixed(0)} km, '
      'races: ${sportsMode.raceCount}, wins: ${sportsMode.winCount})';
}

class Gt7CarLifeStats {
  /// Cars bought — the figure the profile page shows as "cars purchased".
  final int buyCarCount;
  final int buyCarCreditAmount;
  final int customizeCreditAmount;
  final int tuningCreditAmount;

  /// Car-dictionary completion. Units unconfirmed — likely a percentage.
  final int carDictionaryProgress;

  Gt7CarLifeStats._(Map<String, dynamic> j)
    : buyCarCount = Gt7Stats._int(j['buy_car_count']),
      buyCarCreditAmount = Gt7Stats._int(j['buy_car_credit_amount']),
      customizeCreditAmount = Gt7Stats._int(j['customize_credit_amount']),
      tuningCreditAmount = Gt7Stats._int(j['tuning_credit_amount']),
      carDictionaryProgress = Gt7Stats._int(j['car_dictionary_progress']);
}

class Gt7DrivingStats {
  /// Lifetime distance driven, in metres.
  final int drivingDistanceMeters;

  /// Lifetime driving time, in seconds.
  final int drivingTimeSeconds;

  final int averageFuelConsumption;
  final int totalFuelConsumption;

  Gt7DrivingStats._(Map<String, dynamic> j)
    : drivingDistanceMeters = Gt7Stats._int(j['driving_distance']),
      drivingTimeSeconds = Gt7Stats._int(j['driving_time']),
      averageFuelConsumption = Gt7Stats._int(j['average_fuel_consumption']),
      totalFuelConsumption = Gt7Stats._int(j['total_fuel_consumption']);

  double get totalKm => drivingDistanceMeters / 1000;
  Duration get drivingTime => Duration(seconds: drivingTimeSeconds);
}

class Gt7GamePlayStats {
  final int creditAmount;
  final int photoCount;

  /// Total play time, in seconds.
  final int playTimeSeconds;

  Gt7GamePlayStats._(Map<String, dynamic> j)
    : creditAmount = Gt7Stats._int(j['credit_amount']),
      photoCount = Gt7Stats._int(j['photo_count']),
      playTimeSeconds = Gt7Stats._int(j['play_time']);

  Duration get playTime => Duration(seconds: playTimeSeconds);
}

class Gt7GtWorldStats {
  final int circuitExperienceProgress;
  final int episodeProgress;
  final int driftPoint;

  Gt7GtWorldStats._(Map<String, dynamic> j)
    : circuitExperienceProgress = Gt7Stats._int(
        j['circuit_experience_progress'],
      ),
      episodeProgress = Gt7Stats._int(j['episode_progress']),
      driftPoint = Gt7Stats._int(j['drift_point']);
}

class Gt7MedalStats {
  final int gold;
  final int silver;
  final int bronze;

  Gt7MedalStats._(Map<String, dynamic> j)
    : gold = Gt7Stats._int(j['gold']),
      silver = Gt7Stats._int(j['silver']),
      bronze = Gt7Stats._int(j['bronze']);

  int get total => gold + silver + bronze;
}

class Gt7ProfileStats {
  final int driverLevel;
  final int exp;
  final int badge;

  /// Licence tier as a numeric code — see [licenseLabel].
  final int license;

  Gt7ProfileStats._(Map<String, dynamic> j)
    : driverLevel = Gt7Stats._int(j['driver_level']),
      exp = Gt7Stats._int(j['exp']),
      badge = Gt7Stats._int(j['badge']),
      license = Gt7Stats._int(j['license'], fallback: -1);

  /// Licence code → the letter the site prints on the badge.
  ///
  /// GT7 has five licences (National B/A, International B/A, Super). Only
  /// code 5 → "S" is confirmed against the live page; the rest follow the
  /// tier order, and an unknown code yields null.
  static const Map<int, String> licenseLabels = {
    1: 'N-B',
    2: 'N-A',
    3: 'I-B',
    4: 'I-A',
    5: 'S', // confirmed: site shows "S" for code 5
  };

  String? get licenseLabel => licenseLabels[license];
}

class Gt7SocialStats {
  final int followers;
  final int followings;
  final int friends;

  Gt7SocialStats._(Map<String, dynamic> j)
    : followers = Gt7Stats._int(j['followers']),
      followings = Gt7Stats._int(j['followings']),
      friends = Gt7Stats._int(j['friends']);
}

class Gt7SportsModeStats {
  final int raceCount;
  final int winCount;
  final int polePositionCount;
  final int cleanRaceCount;
  final int fastestLapCount;

  Gt7SportsModeStats._(Map<String, dynamic> j)
    : raceCount = Gt7Stats._int(j['race_count']),
      winCount = Gt7Stats._int(j['win_count']),
      polePositionCount = Gt7Stats._int(j['pole_position_count']),
      cleanRaceCount = Gt7Stats._int(j['clean_race_count']),
      fastestLapCount = Gt7Stats._int(j['fastest_lap_count']);
}
