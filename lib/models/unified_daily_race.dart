import 'package:flutter/foundation.dart';

import 'daily_race.dart';
import 'gtsh_race.dart';

/// A single "unified" representation of a daily race, combining the two
/// upstream data sources (DG‑Edge summary page and GTSh‑rank cards) into a
/// flat object.  Fields are populated from whichever provider supplied them
/// (DG‑Edge takes precedence when both exist) so consumers do not need to
/// look at two separate models.
@immutable
class UnifiedDailyRace {
  // optional references to the original objects for debugging / future use
  final DailyRaceSummary? dgEdge;
  final GtshRace? gtsh;

  // common identifiers
  final String? id;
  final String? title;
  final String? url;
  final String? trackName;
  final String? label; // A, B, C etc.

  // tyre / category info
  final String? tyreCode;
  final Tyre? tyre;
  final CarTypeInfo? carType;

  // DG‑Edge summary details
  final int? pitStops;
  final int? tyresAvailable;
  final String? className;
  final int? laps;
  final int? refuels;
  final String? tyreCompound;
  final String? reward;

  // GTSh‑rank details
  final int? fuelMultiplier;
  final int? tyrewearMultiplier;
  final String? pitDescription;
  final bool? bop;
  final String? damage;
  final String? startType;
  final bool? carSettings;
  final String? wideFender;

  const UnifiedDailyRace({
    this.dgEdge,
    this.gtsh,
    this.id,
    this.title,
    this.url,
    required this.trackName,
    this.label,
    this.tyreCode,
    this.tyre,
    this.carType,
    this.pitStops,
    this.tyresAvailable,
    this.className,
    this.laps,
    this.refuels,
    this.tyreCompound,
    this.reward,
    this.fuelMultiplier,
    this.tyrewearMultiplier,
    this.pitDescription,
    this.bop,
    this.damage,
    this.startType,
    this.carSettings,
    this.wideFender,
  });

  /// Helper constructor that builds a unified item from the two source models.
  factory UnifiedDailyRace.fromPair(DailyRaceSummary? dg, GtshRace? gtsh) {
    String? parseLabelFromTitle(String? title) {
      if (title == null) return null;
      final m = RegExp(
        r"Daily\s+([A-Z])",
        caseSensitive: false,
      ).firstMatch(title);
      return m?.group(1)?.toUpperCase();
    }

    final track = dg?.trackName ?? gtsh?.trackName;
    final label = gtsh?.label ?? parseLabelFromTitle(dg?.title);
    final tyreCode = dg?.tyreCode ?? gtsh?.tyreCode;
    // tyre enum will be determined when building the object (DG value
    // preferred, fallback to parsed GTSh code).

    return UnifiedDailyRace(
      dgEdge: dg,
      gtsh: gtsh,
      id: dg?.id,
      title: dg?.title,
      url: dg?.url,
      trackName: track,
      label: label,
      tyreCode: tyreCode,
      tyre: dg?.tyre ?? TyreX.parse(gtsh?.tyreCode),
      carType: dg?.carType,
      pitStops: dg?.pitStops,
      tyresAvailable: dg?.tyresAvailable,
      className: dg?.className,
      laps: dg?.laps,
      refuels: dg?.refuels,
      tyreCompound: dg?.tyreCompound,
      reward: dg?.reward,
      fuelMultiplier: gtsh?.fuelMultiplier,
      tyrewearMultiplier: gtsh?.tyrewearMultiplier,
      pitDescription: gtsh?.pitStops,
      bop: gtsh?.bop,
      damage: gtsh?.damage,
      startType: gtsh?.startType,
      carSettings: gtsh?.carSettings,
      wideFender: gtsh?.wideFender,
    );
  }

  /// convenience getters that mirror the old `CombinedDailyRace` API and
  /// allow widgets to keep using the same property names without needing to
  /// inspect the two backing objects.

  String? get trackLogotype => dgEdge?.trackLogotype;
  String? get trackImage => dgEdge?.trackImage;
  String? get trackBackgroundImage => dgEdge?.trackBackgroundImage;

  // GTSh specific properties are preserved via fields directly

  @override
  String toString() =>
      'UnifiedDailyRace(label: $label, track: $trackName, tyre: $tyreCode, dgEdge: $dgEdge, gtsh: $gtsh)';
}
