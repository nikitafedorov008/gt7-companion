import 'gt7_sport_profile.dart';
import 'gt7_sport_race_stats.dart';
import 'gt7_stats.dart';

/// Display-level GT7 statistics shown on the profile page.
///
/// Assembled from the official web API — see [Gt7UserStats.fromApi]. Fields
/// the API has not been observed to expose yet stay null rather than being
/// guessed at.
class Gt7UserStats {
  final int? collectionLevel;
  final String? license;
  final String? driverRating;
  final String? safetyRating;
  final int? races;
  final int? wins;
  final double? totalKm;
  final int? carsPurchased;
  final int? followers;

  /// Progress through the current DR tier, straight from the API when
  /// available (`dr_point_ratio`). Falls back to a per-letter estimate.
  final double? driverRatingRatio;

  const Gt7UserStats({
    this.collectionLevel,
    this.license,
    this.driverRating,
    this.safetyRating,
    this.races,
    this.wins,
    this.totalKm,
    this.carsPurchased,
    this.followers,
    this.driverRatingRatio,
  });

  /// Build from the API responses.
  ///
  /// [Gt7Stats] is the richer source and wins where the two overlap: it is
  /// the only one carrying lifetime mileage, cars bought, followers and the
  /// exact DR bar ratio.
  ///
  /// The licence tier arrives as a number (`profile.license`) and the site
  /// renders a letter; that mapping is in no response, so the number is
  /// shown as-is rather than guessed at.
  factory Gt7UserStats.fromApi({
    Gt7SportProfile? sportProfile,
    List<Gt7SportRaceStats> sportRaces = const [],
    Gt7Stats? stats,
  }) {
    return Gt7UserStats(
      driverRating: sportProfile?.driverRatingLabel,
      safetyRating: sportProfile?.safetyRatingLabel,
      driverRatingRatio: stats?.driverRatingRatio,
      // Three endpoints report a race count and all three disagree: 171 from
      // get_sport_profile, 174 from sports_mode, 188 from summing
      // get_sport_race. The site prints 188 — so the sum is what "Гонки"
      // means, and the other two are something else.
      races: sportRaces.isEmpty
          ? (stats?.sportsMode.raceCount ?? sportProfile?.raceCount)
          : sportRaces.fold<int>(0, (sum, r) => sum + r.races),
      wins: sportRaces.isEmpty
          ? stats?.sportsMode.winCount
          : sportRaces.fold<int>(0, (sum, r) => sum + r.wins),
      totalKm: stats?.driving.totalKm,
      carsPurchased: stats?.carLife.buyCarCount,
      followers: stats?.social.followers,
      collectionLevel: stats?.profile.driverLevel,
      license: stats?.profile.licenseLabel,
    );
  }

  Gt7UserStats copyWith({
    int? collectionLevel,
    String? license,
    String? driverRating,
    String? safetyRating,
    int? races,
    int? wins,
    double? totalKm,
    int? carsPurchased,
    int? followers,
    double? driverRatingRatio,
  }) {
    return Gt7UserStats(
      driverRatingRatio: driverRatingRatio ?? this.driverRatingRatio,
      collectionLevel: collectionLevel ?? this.collectionLevel,
      license: license ?? this.license,
      driverRating: driverRating ?? this.driverRating,
      safetyRating: safetyRating ?? this.safetyRating,
      races: races ?? this.races,
      wins: wins ?? this.wins,
      totalKm: totalKm ?? this.totalKm,
      carsPurchased: carsPurchased ?? this.carsPurchased,
      followers: followers ?? this.followers,
    );
  }

  /// Progress bar fill for the driver rating (0.0 - 1.0).
  ///
  /// Uses the exact ratio from `/stats/get` when present; the per-letter
  /// table below is only a fallback for when that call failed.
  double get driverRatingProgress =>
      driverRatingRatio ?? _driverRatingProgressEstimate;

  double get _driverRatingProgressEstimate => switch (driverRating) {
    'E' => 0.1,
    'D' => 0.3,
    'C' => 0.5,
    'B' => 0.7,
    'A' => 0.85,
    'A+' => 0.95,
    'S' => 1.0,
    _ => 0.0,
  };

  @override
  String toString() =>
      'Gt7UserStats(DR: $driverRating, SR: $safetyRating, '
      'races: $races, wins: $wins)';
}
