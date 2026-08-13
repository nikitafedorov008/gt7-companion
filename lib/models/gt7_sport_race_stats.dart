/// Aggregated Sport-mode race record for one race category.
///
/// From `POST web-api…/stats/get_sport_race` with body
/// `{"user_id":"…","type_list":[1,2]}`. The response is a list with one entry
/// per requested `type`:
/// ```json
/// {"result":[{"average_qualify_rank":9.07,"average_rank":7.75,"lap":818,
///   "lead_lap":9,"pole_position":0,"race":152,"target_id":0,"top5":44,
///   "top_match":0,"type":1,"win":3}, …]}
/// ```
class Gt7SportRaceStats {
  /// Race category. Observed values are 1 and 2; the site requests both.
  final int type;

  final int races;
  final int wins;
  final int polePositions;
  final int top5;
  final int laps;
  final int leadLaps;
  final int targetId;
  final int topMatch;
  final double averageRank;
  final double averageQualifyRank;

  const Gt7SportRaceStats({
    required this.type,
    required this.races,
    required this.wins,
    required this.polePositions,
    required this.top5,
    required this.laps,
    required this.leadLaps,
    required this.targetId,
    required this.topMatch,
    required this.averageRank,
    required this.averageQualifyRank,
  });

  factory Gt7SportRaceStats.fromJson(Map<String, dynamic> json) {
    return Gt7SportRaceStats(
      type: (json['type'] as num?)?.toInt() ?? 0,
      races: (json['race'] as num?)?.toInt() ?? 0,
      wins: (json['win'] as num?)?.toInt() ?? 0,
      polePositions: (json['pole_position'] as num?)?.toInt() ?? 0,
      top5: (json['top5'] as num?)?.toInt() ?? 0,
      laps: (json['lap'] as num?)?.toInt() ?? 0,
      leadLaps: (json['lead_lap'] as num?)?.toInt() ?? 0,
      targetId: (json['target_id'] as num?)?.toInt() ?? 0,
      topMatch: (json['top_match'] as num?)?.toInt() ?? 0,
      averageRank: (json['average_rank'] as num?)?.toDouble() ?? 0,
      averageQualifyRank:
          (json['average_qualify_rank'] as num?)?.toDouble() ?? 0,
    );
  }

  static List<Gt7SportRaceStats> listFromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is! List) return const [];
    return result
        .whereType<Map<String, dynamic>>()
        .map(Gt7SportRaceStats.fromJson)
        .toList();
  }

  @override
  String toString() =>
      'Gt7SportRaceStats(type: $type, races: $races, wins: $wins)';
}
