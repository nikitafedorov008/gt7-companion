import 'daily_race.dart';
import 'gtsh_race.dart';

/// Combined representation of a single daily race with data from both sources.
/// Either [dgEdge] or [gtsh] (or both) may be non-null.
class CombinedDailyRace {
  final DailyRaceSummary? dgEdge;
  final GtshRace? gtsh;

  CombinedDailyRace({this.dgEdge, this.gtsh});

  String? get trackName => dgEdge?.trackName ?? gtsh?.trackName;

  // expose shared summary fields, preferring DG‑Edge values when available
  String? get title => dgEdge?.title ?? 'Daily ${gtsh?.label ?? ''}';
  String? get url => dgEdge?.url;
  String? get trackLogotype => dgEdge?.trackLogotype;
  String? get trackImage => dgEdge?.trackImage;
  String? get trackBackgroundImage => dgEdge?.trackBackgroundImage;
  int? get pitStops => dgEdge?.pitStops;
  int? get tyresAvailable => dgEdge?.tyresAvailable;
  String? get tyreCode => dgEdge?.tyreCode ?? gtsh?.tyreCode;
  String? get className => dgEdge?.className;
  int? get laps => dgEdge?.laps;
  int? get refuels => dgEdge?.refuels;
  String? get tyreCompound => dgEdge?.tyreCompound;
  String? get reward => dgEdge?.reward;
  CarTypeInfo? get carType => dgEdge?.carType;
  Tyre? get tyre => dgEdge?.tyre;

  // GTSh specific properties
  int? get fuelMultiplier => gtsh?.fuelMultiplier;
  int? get tyreWearMultiplier => gtsh?.tyrewearMultiplier;
  String get pitDescription => gtsh?.pitStops ?? '';
  bool? get bop => gtsh?.bop;
  String? get damage => gtsh?.damage;
  String? get startType => gtsh?.startType;
  bool? get carSettings => gtsh?.carSettings;
  String? get wideFender => gtsh?.wideFender;

  String? get label {
    // try dg-edge title first
    if (dgEdge != null) {
      final m = RegExp(
        r'Daily\s+([A-Z])',
        caseSensitive: false,
      ).firstMatch(dgEdge!.title);
      if (m != null) return m.group(1)?.toUpperCase();
    }
    return gtsh?.label;
  }

  @override
  String toString() =>
      'CombinedDailyRace(label: $label, track: $trackName, dgEdge: $dgEdge, gtsh: $gtsh)';
}
