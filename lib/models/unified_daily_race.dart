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
  final String? carImage; // optional image url from the card
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
    this.carImage,
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
      carImage: gtsh?.carImage,
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

  /// Returns true when either source indicates the event is not yet running.
  ///
  /// DG‑Edge pages include metadata attributes (`isActive`, `isEnded`) which
  /// are parsed into the [DailyRaceSummary].  A future race will have
  /// `isActive == false && isEnded == false` (status may also be "PENDING").
  /// GTSh cards now expose a `status` string; entries marked `next` represent
  /// upcoming races.  Clients such as the unified display sort using this
  /// property to ensure future events appear before current ones.
  bool get isUpcoming {
    // Prefer DG‑Edge metadata when available. DG‑Edge adds a `status` attribute
    // that may express the future state even if `isActive` is still true
    // (`PENDING`/`future`), so we check it first.
    if (dgEdge != null) {
      final status = dgEdge!.status?.toLowerCase();

      // If the upstream status explicitly says this is currently running or
      // actively ongoing, do not treat it as upcoming.
      if (status != null &&
          (status.contains('running') || status.contains('active'))) {
        return false;
      }

      // Explicit future markers from DG‑Edge (handle 'pending' specially:
      // it's only considered future when the upstream `isActive` flag is
      // false; some pages set `status=PENDING` while still reporting
      // `isActive=true` and we must not treat those as upcoming).
      if (status != null &&
          (status.contains('future') ||
              status.contains('scheduled') ||
              status.contains('upcoming') ||
              status.contains('next'))) {
        return true;
      }

      // Treat 'pending' as upcoming only when DG‑Edge explicitly reports
      // the item as not active.
      if (status != null && status.contains('pending')) {
        if (dgEdge?.isActive == false) return true;
      }

      // If DG‑Edge explicitly says this event is already ended, it's not upcoming.
      if (dgEdge!.isEnded == true) return false;

      // If DG‑Edge is explicitly inactive and not ended, treat as future.
      if (dgEdge!.isActive == false && dgEdge!.isEnded == false) return true;
    }

    // Fall back to GTSh status markers
    if (gtsh != null) {
      final status = gtsh!.status.toLowerCase();
      if (status == 'next' || status == 'future') return true;
    }

    return false;
  }

  /// Returns true when the race is currently running.
  bool get isActive {
    if (dgEdge != null) {
      final status = dgEdge!.status?.toLowerCase();

      // Explicitly running/active states should always be treated as active.
      if (status != null &&
          (status.contains('running') || status.contains('active'))) {
        return true;
      }


      // Explicit future markers should not be treated as active even if
      // isActive is true (except 'pending' — that may be present while the
      // `isActive` flag remains true, see note in isUpcoming).
      if (status != null &&
          (status.contains('future') ||
              status.contains('scheduled') ||
              status.contains('upcoming') ||
              status.contains('next'))) {
        return false;
      }

      // 'pending' only indicates non-active when the upstream flag agrees
      // (i.e. isActive == false). If DG‑Edge reports isActive==true, ignore
      // the 'pending' marker and let the flag take precedence.
      if (status != null && status.contains('pending')) {
        if (dgEdge?.isActive == true) return true;
        return false;
      }

      // Fallback to the upstream isActive flag.
      if (dgEdge!.isActive == true) return true;
    }

    if (gtsh != null && gtsh!.status.toLowerCase() == 'running') return true;
    return false;
  }

  /// Returns true when the race has already ended.
  bool get isPast {
    if (dgEdge != null && dgEdge!.isEnded == true) return true;
    if (gtsh != null && gtsh!.status.toLowerCase() == 'ended') return true;
    return false;
  }

  @override
  String toString() =>
      'UnifiedDailyRace(label: $label, track: $trackName, tyre: $tyreCode, dgEdge: $dgEdge, gtsh: $gtsh)';
}
