/// Per-day history for one calendar month.
///
/// From `POST web-api…/stats/get_history` with body
/// `{"user_id":"…","year":2026,"month":8}`. Every list holds one entry per day
/// of the month, so index 0 is the 1st:
/// ```json
/// {"result":{"driver_rating":[2,2,0,…],"driving_distance":[0,110824,0,…],
///   "driving_marathon_count":[0,1,0,…],"sportsmanship_rating":[6,6,0,…]}}
/// ```
///
/// Days that have not happened yet — or on which the player did not race —
/// come back as `0`, not as a gap.
class Gt7StatsHistory {
  final int year;
  final int month;

  /// Driver rating code per day (see `Gt7SportProfile.driverRatingLabels`).
  final List<int> driverRating;

  /// Sportsmanship rating code per day.
  final List<int> sportsmanshipRating;

  /// Distance driven per day, in metres.
  final List<int> drivingDistanceMeters;

  final List<int> drivingMarathonCount;

  const Gt7StatsHistory({
    required this.year,
    required this.month,
    required this.driverRating,
    required this.sportsmanshipRating,
    required this.drivingDistanceMeters,
    required this.drivingMarathonCount,
  });

  factory Gt7StatsHistory.fromJson(
    Map<String, dynamic> json, {
    required int year,
    required int month,
  }) {
    final r = json['result'] as Map<String, dynamic>? ?? json;
    List<int> ints(String key) =>
        (r[key] as List?)?.whereType<num>().map((n) => n.toInt()).toList() ??
        const [];

    return Gt7StatsHistory(
      year: year,
      month: month,
      driverRating: ints('driver_rating'),
      sportsmanshipRating: ints('sportsmanship_rating'),
      drivingDistanceMeters: ints('driving_distance'),
      drivingMarathonCount: ints('driving_marathon_count'),
    );
  }

  /// Total distance driven this month, in kilometres.
  double get totalKm =>
      drivingDistanceMeters.fold<int>(0, (a, b) => a + b) / 1000;

  /// Number of days with any distance recorded.
  int get activeDays => drivingDistanceMeters.where((d) => d > 0).length;

  /// Most recent non-zero driver rating, or null if the month is empty.
  int? get latestDriverRating =>
      driverRating.where((v) => v > 0).isEmpty ? null : driverRating.lastWhere((v) => v > 0);

  @override
  String toString() =>
      'Gt7StatsHistory($year-$month, ${totalKm.toStringAsFixed(1)} km '
      'over $activeDays days)';
}
