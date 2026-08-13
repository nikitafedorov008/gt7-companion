/// Sport-mode profile from `POST web-api…/user/get_sport_profile`.
///
/// Observed response (no request body required):
/// ```json
/// {"result":{"driver_rating":2,"is_star_player":false,"main_area":4772,
///  "manufacturer_id":0,"race_count":171,"secondary_area":6756,
///  "sportsmanship_rating":6,"user_id":"…"}}
/// ```
///
/// Ratings arrive as numeric codes, not letters — see [driverRatingLabel].
class Gt7SportProfile {
  final int driverRating;
  final int sportsmanshipRating;
  final int raceCount;
  final int mainArea;
  final int secondaryArea;
  final int manufacturerId;
  final bool isStarPlayer;
  final String userId;

  const Gt7SportProfile({
    required this.driverRating,
    required this.sportsmanshipRating,
    required this.raceCount,
    required this.mainArea,
    required this.secondaryArea,
    required this.manufacturerId,
    required this.isStarPlayer,
    required this.userId,
  });

  factory Gt7SportProfile.fromJson(Map<String, dynamic> json) {
    final r = json['result'] as Map<String, dynamic>? ?? json;
    return Gt7SportProfile(
      driverRating: (r['driver_rating'] as num?)?.toInt() ?? -1,
      sportsmanshipRating: (r['sportsmanship_rating'] as num?)?.toInt() ?? -1,
      raceCount: (r['race_count'] as num?)?.toInt() ?? 0,
      mainArea: (r['main_area'] as num?)?.toInt() ?? 0,
      secondaryArea: (r['secondary_area'] as num?)?.toInt() ?? 0,
      manufacturerId: (r['manufacturer_id'] as num?)?.toInt() ?? 0,
      isStarPlayer: r['is_star_player'] as bool? ?? false,
      userId: r['user_id'] as String? ?? '',
    );
  }

  /// Numeric rating code → displayed letter.
  ///
  /// The API returns codes and the site renders letters; the mapping is in no
  /// response. Both scales are 1-based, anchored on the reference account
  /// where the site shows **DR D** for `driver_rating: 2` and **SR S** for
  /// `sportsmanship_rating: 6`.
  ///
  /// Only those two points are confirmed against the live page. The rest
  /// follow from the tier order, and an unknown code yields null rather than
  /// a plausible-looking wrong letter.
  static const Map<int, String> driverRatingLabels = {
    1: 'E',
    2: 'D', // confirmed: site shows "D" for code 2
    3: 'C',
    4: 'B',
    5: 'A',
    6: 'A+',
  };

  static const Map<int, String> safetyRatingLabels = {
    1: 'E',
    2: 'D',
    3: 'C',
    4: 'B',
    5: 'A',
    6: 'S', // confirmed: site shows "S" for code 6
  };

  String? get driverRatingLabel => driverRatingLabels[driverRating];
  String? get safetyRatingLabel => safetyRatingLabels[sportsmanshipRating];

  @override
  String toString() =>
      'Gt7SportProfile(DR: $driverRating/$driverRatingLabel, '
      'SR: $sportsmanshipRating/$safetyRatingLabel, races: $raceCount)';
}
