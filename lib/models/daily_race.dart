// Models for DG-Edge daily races

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:html/dom.dart' as dom;

/// Tyre codes used by DG‑Edge / GT7 (short codes)
///
/// Includes:
/// - Comfort / Sports / Racing (CH/CM/CS, SH/SM/SS, RH/RM/RS)
/// - Wet/weather tyres: Intermediate (IM), Heavy‑wet (W)
/// - Off‑road: Dirt (D)
///
/// Values use short codes that match DG‑Edge output.
enum Tyre { CH, CM, CS, SH, SM, SS, RH, RM, RS, IM, W, D }

extension TyreX on Tyre {
  /// Short code (e.g. "RM")
  String get code {
    switch (this) {
      case Tyre.CH:
        return 'CH';
      case Tyre.CM:
        return 'CM';
      case Tyre.CS:
        return 'CS';
      case Tyre.SH:
        return 'SH';
      case Tyre.SM:
        return 'SM';
      case Tyre.SS:
        return 'SS';
      case Tyre.RH:
        return 'RH';
      case Tyre.RM:
        return 'RM';
      case Tyre.RS:
        return 'RS';
      case Tyre.IM:
        return 'IM';
      case Tyre.W:
        return 'W';
      case Tyre.D:
        return 'D';
    }
  }

  /// Display colour associated with this tyre type.
  ///
  /// - Dirt: beige
  /// - Wet: blue
  /// - Intermediate: green
  /// - Comfort/Sport/Racing compounds: Hard = white, Medium = amber, Soft = red
  Color get color {
    switch (this) {
      // Comfort / Sport / Racing: Hard (H) -> white
      case Tyre.CH:
      case Tyre.SH:
      case Tyre.RH:
        return Colors.white;

      // Comfort / Sport / Racing: Medium (M) -> amber/yellow
      case Tyre.CM:
      case Tyre.SM:
      case Tyre.RM:
        return Colors.amber;

      // Comfort / Sport / Racing: Soft (S) -> red
      case Tyre.CS:
      case Tyre.SS:
      case Tyre.RS:
        return Colors.red;

      // Intermediate (IM) -> green
      case Tyre.IM:
        return Colors.green;

      // Heavy-wet / Wet -> blue
      case Tyre.W:
        return Colors.blue;

      // Dirt -> beige/tan
      case Tyre.D:
        return const Color(0xFFD2B48C);
    }
  }

  /// Best contrasting foreground colour for text/icons when rendered on top
  /// of `color` (white on dark backgrounds, black on light backgrounds).
  Color get contrastColor =>
      color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  /// Parse a free-form string and return the matching enum.
  ///
  /// Accepts short codes (e.g. "RM") or common words/phrases found on DG‑Edge
  /// pages (e.g. "Intermediate", "Heavy-wet", "Dirt").
  static Tyre? parse(String? s) {
    if (s == null) return null;

    // 1) try short code first
    final short = RegExp(
      r"\b(CH|CM|CS|SH|SM|SS|RH|RM|RS|IM|W|D)\b",
      caseSensitive: false,
    ).firstMatch(s);
    if (short != null) {
      final code = short.group(1)!.toUpperCase();
      switch (code) {
        case 'CH':
          return Tyre.CH;
        case 'CM':
          return Tyre.CM;
        case 'CS':
          return Tyre.CS;
        case 'SH':
          return Tyre.SH;
        case 'SM':
          return Tyre.SM;
        case 'SS':
          return Tyre.SS;
        case 'RH':
          return Tyre.RH;
        case 'RM':
          return Tyre.RM;
        case 'RS':
          return Tyre.RS;
        case 'IM':
          return Tyre.IM;
        case 'W':
          return Tyre.W;
        case 'D':
          return Tyre.D;
      }
    }

    // 2) try common words (e.g. "Intermediate", "Heavy-wet", "Dirt")
    final lower = s.toLowerCase();
    if (lower.contains('intermediate')) return Tyre.IM;
    if (lower.contains('heavy') ||
        lower.contains('heavy-wet') ||
        lower.contains('heavy wet'))
      return Tyre.W;
    if (lower.contains('wet') &&
        lower.contains('heavy') == false &&
        lower.contains('intermediate') == false) {
      // if text contains generic "wet" without qualifiers prefer Heavy‑wet
      return Tyre.W;
    }
    if (lower.contains('dirt') ||
        lower.contains('off') && lower.contains('road'))
      return Tyre.D;

    return null;
  }
}

/// Car types / categories used in GT7 and DG‑Edge pages.
///
/// Enum values include category groups (GR.1/GR.2/GR.3/GR.4/GR.B) and common
/// car-type tags (Road Car, Racing Car, Hypercar, VGT, GT500, Le Mans, etc.).
enum CarType {
  GR1,
  GR2,
  GR3,
  GR4,
  GRB,
  ROAD_CAR,
  RACING_CAR,
  PROFESSIONALLY_TUNED,
  HYPERCAR,
  VISION_GRAN_TURISMO,
  CONCEPT_CAR,
  SAFETY_CAR,
  KEI_CAR,
  ELECTRIC_CAR,
  HYBRID,
  GRAN_TURISMO_AWARD,
  GT500,
  LE_MANS,
  NURBURGRING_24H,
  WRC,
  KART,
  PIKES_PEAK,
  MIDSHIP,
  PICKUP_TRUCK,
}

extension CarTypeX on CarType {
  /// Canonical short string used for JSON / UI (keeps previous behaviour like "GR.4").
  String get code {
    switch (this) {
      case CarType.GR1:
        return 'GR.1';
      case CarType.GR2:
        return 'GR.2';
      case CarType.GR3:
        return 'GR.3';
      case CarType.GR4:
        return 'GR.4';
      case CarType.GRB:
        return 'GR.B';
      case CarType.ROAD_CAR:
        return 'Road Car';
      case CarType.RACING_CAR:
        return 'Racing Car';
      case CarType.PROFESSIONALLY_TUNED:
        return 'Professionally-Tuned Car';
      case CarType.HYPERCAR:
        return 'Hypercar';
      case CarType.VISION_GRAN_TURISMO:
        return 'Vision Gran Turismo';
      case CarType.CONCEPT_CAR:
        return 'Concept Car';
      case CarType.SAFETY_CAR:
        return 'Safety Car';
      case CarType.KEI_CAR:
        return 'Kei Car';
      case CarType.ELECTRIC_CAR:
        return 'Electric Car';
      case CarType.HYBRID:
        return 'Hybrid';
      case CarType.GRAN_TURISMO_AWARD:
        return 'Gran Turismo Award';
      case CarType.GT500:
        return 'GT500';
      case CarType.LE_MANS:
        return 'Le Mans';
      case CarType.NURBURGRING_24H:
        return 'Nürburgring 24 Hours';
      case CarType.WRC:
        return 'WRC';
      case CarType.KART:
        return 'Kart';
      case CarType.PIKES_PEAK:
        return 'Pikes Peak';
      case CarType.MIDSHIP:
        return 'Midship';
      case CarType.PICKUP_TRUCK:
        return 'Pickup Truck';
    }
  }

  /// Best-effort parse from free-form scraped text.
  static CarType? parse(String? s) {
    if (s == null) return null;
    final lower = s.toLowerCase();

    // categories
    if (RegExp(r'gr\.?1', caseSensitive: false).hasMatch(s) ||
        lower.contains('group 1'))
      return CarType.GR1;
    if (RegExp(r'gr\.?2', caseSensitive: false).hasMatch(s) ||
        lower.contains('group 2'))
      return CarType.GR2;
    if (RegExp(r'gr\.?3', caseSensitive: false).hasMatch(s) ||
        lower.contains('group 3'))
      return CarType.GR3;
    if (RegExp(r'gr\.?4', caseSensitive: false).hasMatch(s) ||
        lower.contains('group 4'))
      return CarType.GR4;
    if (RegExp(r'gr\.?b', caseSensitive: false).hasMatch(s) ||
        lower.contains('group b'))
      return CarType.GRB;

    // common car types / tags
    if (lower.contains('road')) return CarType.ROAD_CAR;
    if (lower.contains('racing') ||
        lower.contains('race car') ||
        lower.contains('racing car'))
      return CarType.RACING_CAR;
    if (lower.contains('profession') || lower.contains('tuned'))
      return CarType.PROFESSIONALLY_TUNED;
    if (lower.contains('hypercar')) return CarType.HYPERCAR;
    if (lower.contains('vision') || lower.contains('vgt'))
      return CarType.VISION_GRAN_TURISMO;
    if (lower.contains('concept')) return CarType.CONCEPT_CAR;
    if (lower.contains('safety')) return CarType.SAFETY_CAR;
    if (lower.contains('kei')) return CarType.KEI_CAR;
    if (lower.contains('electric')) return CarType.ELECTRIC_CAR;
    if (lower.contains('hybrid')) return CarType.HYBRID;
    if (lower.contains('gran turismo award') || lower.contains('sema'))
      return CarType.GRAN_TURISMO_AWARD;
    if (lower.contains('gt500')) return CarType.GT500;
    if (lower.contains('le mans') || lower.contains('lemans'))
      return CarType.LE_MANS;
    if (lower.contains('nurb') ||
        lower.contains('nürburgring') ||
        lower.contains('nurburgring'))
      return CarType.NURBURGRING_24H;
    if (lower.contains('wrc')) return CarType.WRC;
    if (lower.contains('kart')) return CarType.KART;
    if (lower.contains('pikes') || lower.contains('pike'))
      return CarType.PIKES_PEAK;
    if (lower.contains('midship')) return CarType.MIDSHIP;
    if (lower.contains('pickup')) return CarType.PICKUP_TRUCK;

    return null;
  }
}

@immutable
class DailyRaceSummary {
  final String id; // numeric id or slug from URL (e.g. "505")
  final String title;
  final String? thumbnailUrl; // small thumbnail shown in list
  final String? trackImageUrl; // image of the track (larger)
  final String?
  backgroundImageUrl; // optional background image (card background)
  final String?
  backgroundImageLoaded; // URL of the loaded background image (null when not loaded)
  final String? shortDescription;
  final String? eventName; // explicit '.event-name' when present
  final String?
  eventTime; // explicit '.event-time.mb-0' when present (raw string)
  final String? trackName; // track name (e.g. <h4>Tsukuba Circuit</h4>)
  final DateTime? startDateTime; // best-effort

  // New summary-level fields requested
  final int? pitStops; // e.g. 1, 2, 3
  final int? tyresAvailable; // number of tyre sets available (x1/x2/...)
  final String? tyreCode; // e.g. RM, RS, SO (short code)

  // Optional summary-level fields (may be present on the listing card)
  final String? className;
  final int? laps;
  final int? refuels;
  final String? tyreCompound;
  final String? reward;

  // New fields requested
  final CarType? carType; // parsed car type/category (enum)
  final Tyre? tyre; // tyre enum (e.g. Tyre.RM)

  // Metadata attributes from the event wrapper
  final String? externalId;
  final String? rankingId;
  final String? trackId;
  final String? status;
  final bool? isActive;
  final bool? isEnded;
  final int? totalPages;
  final DateTime? lastUpdate;
  final DateTime? lastUpdateStart;
  final String? metaTitle;
  final String? metaDescription;

  final String url; // full or relative url

  const DailyRaceSummary({
    required this.id,
    required this.title,
    required this.url,
    this.thumbnailUrl,
    this.trackImageUrl,
    this.backgroundImageUrl,
    this.backgroundImageLoaded,
    this.shortDescription,
    this.eventName,
    this.eventTime,
    this.trackName,
    this.startDateTime,
    this.pitStops,
    this.tyresAvailable,
    this.tyreCode,
    this.className,
    this.laps,
    this.refuels,
    this.tyreCompound,
    this.reward,
    this.carType,
    this.tyre,
    this.externalId,
    this.rankingId,
    this.trackId,
    this.status,
    this.isActive,
    this.isEnded,
    this.totalPages,
    this.lastUpdate,
    this.lastUpdateStart,
    this.metaTitle,
    this.metaDescription,
  });

  factory DailyRaceSummary.fromJson(Map<String, dynamic> j) => DailyRaceSummary(
    id: j['id'] as String,
    title: j['title'] as String,
    url: j['url'] as String,
    thumbnailUrl: j['thumbnailUrl'] as String?,
    trackImageUrl: j['trackImageUrl'] as String?,
    backgroundImageUrl: j['backgroundImageUrl'] as String?,
    backgroundImageLoaded: j['backgroundImageLoaded'] as String?,
    shortDescription: j['shortDescription'] as String?,
    eventName: j['eventName'] as String?,
    eventTime: j['eventTime'] as String?,
    trackName: j['trackName'] as String?,
    startDateTime: j['startDateTime'] == null
        ? null
        : DateTime.parse(j['startDateTime'] as String),
    pitStops: j['pitStops'] as int?,
    tyresAvailable: j['tyresAvailable'] as int?,
    tyreCode: j['tyreCode'] as String?,
    className: j['className'] as String?,
    laps: j['laps'] as int?,
    refuels: j['refuels'] as int?,
    tyreCompound: j['tyreCompound'] as String?,
    reward: j['reward'] as String?,
    carType: CarTypeX.parse(j['carType'] as String?),
    tyre: TyreX.parse(j['tyre'] as String?),
    externalId: j['externalId'] as String?,
    rankingId: j['rankingId'] as String?,
    trackId: j['trackId'] as String?,
    status: j['status'] as String?,
    isActive: j['isActive'] as bool?,
    isEnded: j['isEnded'] as bool?,
    totalPages: j['totalPages'] as int?,
    lastUpdate: j['lastUpdate'] == null
        ? null
        : DateTime.parse(j['lastUpdate'] as String),
    lastUpdateStart: j['lastUpdateStart'] == null
        ? null
        : DateTime.parse(j['lastUpdateStart'] as String),
    metaTitle: j['metaTitle'] as String?,
    metaDescription: j['metaDescription'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'trackImageUrl': trackImageUrl,
    'backgroundImageUrl': backgroundImageUrl,
    'backgroundImageLoaded': backgroundImageLoaded,
    'shortDescription': shortDescription,
    'eventName': eventName,
    'eventTime': eventTime,
    'trackName': trackName,
    'startDateTime': startDateTime?.toIso8601String(),
    'pitStops': pitStops,
    'tyresAvailable': tyresAvailable,
    'tyreCode': tyreCode,
    'className': className,
    'laps': laps,
    'refuels': refuels,
    'tyreCompound': tyreCompound,
    'reward': reward,
    'carType': carType?.code,
    'tyre': tyre?.code,
    'externalId': externalId,
    'rankingId': rankingId,
    'trackId': trackId,
    'status': status,
    'isActive': isActive,
    'isEnded': isEnded,
    'totalPages': totalPages,
    'lastUpdate': lastUpdate?.toIso8601String(),
    'lastUpdateStart': lastUpdateStart?.toIso8601String(),
    'metaTitle': metaTitle,
    'metaDescription': metaDescription,
  };

  String? get trackImage => trackId != null
      ? 'https://data.dg-edge.com/images/tracks/$trackId/thumbs/Track$trackId.webp'
      : null;

  String? get trackBackgroundImage => trackId != null
      ? 'https://data.dg-edge.com/images/tracks/$trackId/Back$trackId.webp'
      : null;

  String? get trackLogotype => trackId != null
      ? 'https://data.dg-edge.com/images/tracks/$trackId/thumbs/Logo$trackId.webp'
      : null;

  @override
  String toString() => 'DailyRaceSummary($id, $title)';

  // Conservative, best-effort HTML element parsing from a listing/card element.
  // The selector strategy in the service tries to locate an <a> that links to /events/dailies/{id}
  static DailyRaceSummary? fromListElement(
    dom.Element el, {
    required String baseUrl,
  }) {
    try {
      // Diagnostic: log the element we're attempting to parse (short form)
      debugPrint(
        'DailyRaceSummary.fromListElement: parsing element <${el.localName}> classes=${el.classes}',
      );

      // Find anchor pointing to the detail
      final anchor = el.querySelector('a[href*="/events/dailies/"]') ?? el;
      final href = anchor.attributes['href'] ?? '';
      debugPrint('  anchor href="$href"');
      final uri = href.startsWith('http') ? href : (baseUrl + href);
      final idMatch = RegExp(r'/events/dailies/([\w-]+)').firstMatch(href);
      final id = idMatch?.group(1) ?? uri;

      // Title: try heading tags then alt or text
      final titleEl =
          anchor.querySelector('h3') ??
          anchor.querySelector('h2') ??
          anchor.querySelector('.card-title');
      // Raw title text from the heading or anchor
      var title = (titleEl?.text ?? anchor.text).trim().split(RegExp('\n'))[0];

      // If the title contains a concatenated section token like `dailyc` make it readable
      // e.g. `dailycgr.4` -> `Daily cgr.4` (we'll remove class token below)
      title = title.replaceAllMapped(
        RegExp(r'^daily([a-z])', caseSensitive: false),
        (m) => 'Daily ${m[1]!.toUpperCase()}',
      );

      // Not parsing thumbnail/track/background images here — use computed getters based on `trackId`.

      // Explicit event name (some pages use `.event-name`) and explicit event time
      final eventNameEl =
          anchor.querySelector('.event-name') ??
          el.querySelector('.event-name');
      final eventTimeEl =
          anchor.querySelector('.event-time.mb-0') ??
          el.querySelector('.event-time');
      final trackNameEl = anchor.querySelector('h4') ?? el.querySelector('h4');
      final eventName = eventNameEl?.text.trim();
      final eventTime = eventTimeEl?.text.trim();
      final trackName = trackNameEl?.text.trim();

      // Short description
      String? shortDesc;
      final descEl =
          el.querySelector('.card-text') ??
          el.querySelector('.excerpt') ??
          el.querySelector('p');
      if (descEl != null) shortDesc = descEl.text.trim();

      // Try to extract pit stops / tyre counts / tyre code from small metadata elements or badges
      int? pitStops;
      int? tyresAvailable;
      String? tyreCode;

      // Optional summary-level fields
      String? className;
      int? laps;
      int? refuels;
      String? tyreCompound;
      String? reward;

      // Look for explicit elements
      final infoEls = [
        ...el.querySelectorAll(
          '.info, .specs, .badges, .meta, .event-info, .event-specs',
        ),
        if (el.querySelectorAll('.badge').isNotEmpty)
          ...el.querySelectorAll('.badge'),
      ];
      for (final info in infoEls) {
        final t = info.text;
        // Pits: x1 or Pits x1
        final pitMatch = RegExp(
          r"(?:(?:Pits?|Pit\s*stops?):?)\s*[x×]?\s*(\d+)",
          caseSensitive: false,
        ).firstMatch(t);
        if (pitMatch != null) pitStops ??= int.tryParse(pitMatch.group(1)!);
        // Tyres available: x2
        final tyreCountMatch = RegExp(
          r"Tyres?:?\s*[x×]?\s*(\d+)",
          caseSensitive: false,
        ).firstMatch(t);
        if (tyreCountMatch != null)
          tyresAvailable ??= int.tryParse(tyreCountMatch.group(1)!);
        // Tyre code (RM, RS, SO etc.)
        final tyreCodeMatch = RegExp(r"\b([A-Z]{1,3})\b").firstMatch(t);
        if (tyreCodeMatch != null && tyreCode == null) {
          final candidate = tyreCodeMatch.group(1)!;
          if (candidate.length <= 3 && RegExp(r"[A-Z]").hasMatch(candidate))
            tyreCode = candidate;
        }

        // summary-level extraction
        final classMatch = RegExp(
          r"Class:\s*(.+)",
          caseSensitive: false,
        ).firstMatch(t);
        if (classMatch != null) className ??= classMatch.group(1)?.trim();
        final lapsMatch = RegExp(
          r"Laps?:\s*[x×]?\s*(\d+)",
          caseSensitive: false,
        ).firstMatch(t);
        if (lapsMatch != null) laps ??= int.tryParse(lapsMatch.group(1)!);
        final refuelMatch = RegExp(
          r"Refuels?:?\s*[x×]?\s*(\d+)",
          caseSensitive: false,
        ).firstMatch(t);
        if (refuelMatch != null)
          refuels ??= int.tryParse(refuelMatch.group(1)!);
        final tyreCompoundMatch = RegExp(
          r"(Hard|Medium|Soft)",
          caseSensitive: false,
        ).firstMatch(t);
        if (tyreCompoundMatch != null)
          tyreCompound ??= tyreCompoundMatch.group(1)!.trim();
        final rewardMatch = RegExp(
          r"Reward:\s*([^\n]+)",
          caseSensitive: false,
        ).firstMatch(t);
        if (rewardMatch != null) reward ??= rewardMatch.group(1)!.trim();
      }

      // Fallback: try to find inline annotations like data-* attributes on the anchor
      if (pitStops == null && anchor.attributes['data-pits'] != null)
        pitStops = int.tryParse(anchor.attributes['data-pits']!);
      if (tyresAvailable == null && anchor.attributes['data-tyres'] != null)
        tyresAvailable = int.tryParse(anchor.attributes['data-tyres']!);
      tyreCode ??= anchor.attributes['data-tyre-code'];

      // populate summary-level fallback fields from parsed metadata if present
      className ??= anchor.attributes['data-class'];
      laps ??= int.tryParse(anchor.attributes['data-laps'] ?? '');
      refuels ??= int.tryParse(anchor.attributes['data-refuels'] ?? '');
      tyreCompound ??= anchor.attributes['data-tyre-compound'];
      reward ??= anchor.attributes['data-reward'];

      // Try to find event-level wrapper (div.event) to extract additional attributes and elements
      dom.Element? wrapper;
      dom.Node? cur = el;
      while (cur is dom.Element) {
        final e = cur;
        if (e.attributes.containsKey('externalid') ||
            e.classes.contains('event')) {
          wrapper = e;
          break;
        }
        cur = cur.parent;
      }

      String? carTypeVal;
      String? tyreSpanVal;
      String? externalId;
      String? rankingId;
      String? trackId;
      String? statusAttr;
      bool? isActiveAttr;
      bool? isEndedAttr;
      int? totalPagesAttr;
      DateTime? lastUpdateAttr;
      DateTime? lastUpdateStartAttr;
      String? metaTitleAttr;
      String? metaDescriptionAttr;

      if (wrapper != null) {
        carTypeVal = wrapper.querySelector('.car-type span')?.text.trim();
        tyreSpanVal = wrapper.querySelector('.tire')?.text.trim();

        externalId = wrapper.attributes['externalid'];
        rankingId = wrapper.attributes['rankingid'];
        trackId = wrapper.attributes['trackid'];
        statusAttr = wrapper.attributes['status'];
        isActiveAttr = wrapper.attributes['isactive'] == 'true';
        isEndedAttr = wrapper.attributes['isended'] == 'true';
        totalPagesAttr = int.tryParse(wrapper.attributes['totalpages'] ?? '');
        metaTitleAttr = wrapper.attributes['metatitle'];
        metaDescriptionAttr = wrapper.attributes['metadescription'];
        final lu = wrapper.attributes['lastupdate'];
        final lus = wrapper.attributes['lastupdatestart'];
        if (lu != null && lu.isNotEmpty) lastUpdateAttr = DateTime.tryParse(lu);
        if (lus != null && lus.isNotEmpty)
          lastUpdateStartAttr = DateTime.tryParse(lus);

        // Icon-based extraction (flag/gas/tire svg with adjacent text)
        final flagSvg =
            wrapper.querySelector('svg[data-icon="flag-checkered"]') ??
            wrapper.querySelector('.fa-flag-checkered');
        if (flagSvg != null) {
          final parentText = flagSvg.parent?.text ?? '';
          final m = RegExp(r"(\d+)").firstMatch(parentText);
          if (m != null) laps ??= int.tryParse(m.group(1)!);
        }
        final gasSvg =
            wrapper.querySelector('svg[data-icon="gas-pump"]') ??
            wrapper.querySelector('.fa-gas-pump');
        if (gasSvg != null) {
          final parentText = gasSvg.parent?.text ?? '';
          final m = RegExp(
            r"x\s*(\d+)",
            caseSensitive: false,
          ).firstMatch(parentText);
          if (m != null) refuels ??= int.tryParse(m.group(1)!);
        }
        final tireSvg =
            wrapper.querySelector('svg[data-icon="tire"]') ??
            wrapper.querySelector('.fa-tire');
        if (tireSvg != null) {
          final parentText = tireSvg.parent?.text ?? '';
          final m = RegExp(
            r"x\s*(\d+)",
            caseSensitive: false,
          ).firstMatch(parentText);
          if (m != null) tyresAvailable ??= int.tryParse(m.group(1)!);
        }

        // wrapper background image not parsed here
      }

      // Best-effort date/time parse from text
      DateTime? when;
      final text = el.text;
      final timeMatch = RegExp(r"(\d{1,2}:\d{2})").firstMatch(text);
      if (timeMatch != null) {
        // no timezone or date — leave null or attempt today
      }

      return DailyRaceSummary(
        id: id,
        title: title.isEmpty ? '(no title)' : title,
        url: uri,
        thumbnailUrl: null,
        trackImageUrl: null,
        backgroundImageUrl: null,
        backgroundImageLoaded: null,
        shortDescription: shortDesc,
        eventName: eventName,
        eventTime: eventTime,
        trackName: trackName,
        startDateTime: when,
        pitStops: pitStops,
        tyresAvailable: tyresAvailable,
        tyreCode: tyreCode,
        //className: className,
        laps: laps,
        refuels: refuels,
        tyreCompound: tyreCompound,
        reward: reward,
        carType: CarTypeX.parse(carTypeVal),
        tyre: TyreX.parse(tyreSpanVal),
        externalId: externalId,
        rankingId: rankingId,
        trackId: trackId,
        status: statusAttr,
        isActive: isActiveAttr,
        isEnded: isEndedAttr,
        totalPages: totalPagesAttr,
        lastUpdate: lastUpdateAttr,
        lastUpdateStart: lastUpdateStartAttr,
        metaTitle: metaTitleAttr,
        metaDescription: metaDescriptionAttr,
        className: className,
      );
    } catch (e, st) {
      debugPrint(
        'DailyRaceSummary.fromListElement: parse failed for element — error: $e\n$st',
      );
      return null;
    }
  }
}

@immutable
class DailyRaceDetail {
  final String id;
  final String title;
  final String? descriptionHtml;
  final List<String> players; // player names (best-effort)
  final Map<String, String> metadata; // arbitrary key/value pairs

  // Structured, commonly-present fields (best-effort parsed)
  final String? className; // e.g. "Gr.3"
  final int? laps;
  final int? refuels; // number of pit stops / refuels allowed
  final String? tyreType; // e.g. "Racing"
  final String? tyreCompound; // e.g. "Hard", "Medium"
  final bool? fuelAllowed;
  final String? reward;

  const DailyRaceDetail({
    required this.id,
    required this.title,
    this.descriptionHtml,
    this.players = const [],
    this.metadata = const {},
    this.className,
    this.laps,
    this.refuels,
    this.tyreType,
    this.tyreCompound,
    this.fuelAllowed,
    this.reward,
  });

  factory DailyRaceDetail.fromJson(Map<String, dynamic> j) => DailyRaceDetail(
    id: j['id'] as String,
    title: j['title'] as String,
    descriptionHtml: j['descriptionHtml'] as String?,
    players: (j['players'] as List?)?.cast<String>() ?? const [],
    metadata: (j['metadata'] as Map?)?.cast<String, String>() ?? const {},
    className: j['className'] as String?,
    laps: j['laps'] as int?,
    refuels: j['refuels'] as int?,
    tyreType: j['tyreType'] as String?,
    tyreCompound: j['tyreCompound'] as String?,
    fuelAllowed: j['fuelAllowed'] as bool?,
    reward: j['reward'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'descriptionHtml': descriptionHtml,
    'players': players,
    'metadata': metadata,
    'className': className,
    'laps': laps,
    'refuels': refuels,
    'tyreType': tyreType,
    'tyreCompound': tyreCompound,
    'fuelAllowed': fuelAllowed,
    'reward': reward,
  };

  @override
  String toString() => 'DailyRaceDetail($id, $title)';

  // Best-effort parser for details page element
  static DailyRaceDetail? fromDetailDocument(
    dom.Document doc, {
    required String url,
  }) {
    try {
      final idMatch = RegExp(r'/events/dailies/([\w-]+)').firstMatch(url);
      final id = idMatch?.group(1) ?? url;
      final titleEl =
          doc.querySelector('h1') ??
          doc.querySelector('h2') ??
          doc.querySelector('.entry-title');
      final title = titleEl?.text.trim() ?? '(no title)';
      final descEl =
          doc.querySelector('.entry-content') ??
          doc.querySelector('.content') ??
          doc.querySelector('article');
      final descHtml = descEl?.innerHtml.trim();

      // players: look for table rows or lists under .players or .participants
      final players = <String>[];
      final playersContainers = [
        ...doc.querySelectorAll('.players'),
        ...doc.querySelectorAll('.participants'),
        ...doc.querySelectorAll('table.players'),
      ];
      for (final c in playersContainers) {
        for (final tr in c.querySelectorAll('tr')) {
          final cols = tr.querySelectorAll('td');
          if (cols.isNotEmpty)
            players.add(
              cols
                  .map((e) => e.text.trim())
                  .whereNot((s) => s.isEmpty)
                  .join(' — '),
            );
        }
        for (final li in c.querySelectorAll('li')) {
          final t = li.text.trim();
          if (t.isNotEmpty) players.add(t);
        }
      }

      // metadata (best-effort) — look for key: value pairs in paragraphs or lists
      final metadata = <String, String>{};
      for (final p in doc.querySelectorAll(
        '.meta, .event-meta, .event-info, .entry-meta, .info, .specs, .details',
      )) {
        // normalize <br> into newlines so key:value pairs split correctly
        final raw = p.innerHtml.replaceAll(
          RegExp(r'<br\s*/?>', caseSensitive: false),
          '\n',
        );
        final text = raw.replaceAll(RegExp(r'<[^>]+>'), '');
        for (final m in RegExp(
          r"([A-Za-zА-Яа-я0-9 \-]+):\s*([^\n]+)",
        ).allMatches(text)) {
          metadata[m.group(1)!.trim()] = m.group(2)!.trim();
        }
      }

      // Pre-fill common structured fields from metadata when available
      bool? fuelAllowed;
      if (metadata.containsKey('Fuel')) {
        final v = metadata['Fuel']!.toLowerCase();
        fuelAllowed = v.contains('allow') || v.contains('yes');
      }

      // Try to extract well-known keys into structured fields
      String? className;
      int? laps;
      int? refuels;
      String? tyreType;
      String? tyreCompound;
      String? reward;

      String _cap(String s) =>
          s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1).toLowerCase());

      void extractFromText(String source) {
        for (final m in RegExp(
          r"([A-Za-zА-Яа-я0-9 \-]+):\s*([^\n]+)",
        ).allMatches(source)) {
          final k = m.group(1)!.trim();
          final v = m.group(2)!.trim();
          metadata.putIfAbsent(k, () => v);

          final lk = k.toLowerCase();
          if (lk.contains('class') && className == null) className = v;
          if ((lk.contains('lap') ||
                  lk.contains('laps') ||
                  lk.contains('round')) &&
              laps == null) {
            final n = int.tryParse(
              RegExp(r"(\d+)").firstMatch(v)?.group(1) ?? '',
            );
            if (n != null) laps = n;
          }
          if ((lk.contains('refu') || lk.contains('pit')) && refuels == null) {
            final n = int.tryParse(
              RegExp(r"(\d+)").firstMatch(v)?.group(1) ?? '',
            );
            if (n != null) refuels = n;
          }
          if ((lk.contains('tyre') || lk.contains('tire')) &&
              (tyreType == null || tyreCompound == null)) {
            final parts = v.split(RegExp(r"\s*[/:,\-]\s*"));
            if (parts.length == 1) {
              final compMatch = RegExp(
                r"(hard|medium|soft)",
                caseSensitive: false,
              ).firstMatch(v);
              if (compMatch != null) {
                tyreCompound = _cap(compMatch.group(1)!);
              } else {
                tyreType = v;
              }
            } else {
              tyreType = parts.first;
              tyreCompound = _cap(parts.last);
            }
          }
          if (lk.contains('fuel') && fuelAllowed == null) {
            final result =
                v.toLowerCase().contains('allow') ||
                v.toLowerCase().contains('yes');
            fuelAllowed = result;
          }
          if (lk.contains('reward') && reward == null) reward = v;
        }
      }

      // run extraction only on elements that look like key:value containers
      for (final p in doc.querySelectorAll('p, li, div')) {
        final raw = p.innerHtml.replaceAll(
          RegExp(r'<br\s*/?>', caseSensitive: false),
          '\n',
        );
        if (!raw.contains(':'))
          continue; // skip ordinary paragraphs (avoids matching times like 1:34.567)
        final text = raw.replaceAll(RegExp(r'<[^>]+>'), '');
        extractFromText(text);
      }

      return DailyRaceDetail(
        id: id,
        title: title,
        descriptionHtml: descHtml,
        players: players,
        metadata: metadata,
        className: className,
        laps: laps,
        refuels: refuels,
        tyreType: tyreType,
        tyreCompound: tyreCompound,
        fuelAllowed: fuelAllowed,
        reward: reward,
      );
    } catch (_) {
      return null;
    }
  }
}
