// Models for DG-Edge daily races

import 'dart:convert';

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
        lower.contains('heavy wet')) {
      return Tyre.W;
    }
    if (lower.contains('wet') &&
        lower.contains('heavy') == false &&
        lower.contains('intermediate') == false) {
      // if text contains generic "wet" without qualifiers prefer Heavy‑wet
      return Tyre.W;
    }
    if (lower.contains('dirt') ||
        lower.contains('off') && lower.contains('road')) {
      return Tyre.D;
    }

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
        lower.contains('group 1')) {
      return CarType.GR1;
    }
    if (RegExp(r'gr\.?2', caseSensitive: false).hasMatch(s) ||
        lower.contains('group 2')) {
      return CarType.GR2;
    }
    if (RegExp(r'gr\.?3', caseSensitive: false).hasMatch(s) ||
        lower.contains('group 3')) {
      return CarType.GR3;
    }
    if (RegExp(r'gr\.?4', caseSensitive: false).hasMatch(s) ||
        lower.contains('group 4')) {
      return CarType.GR4;
    }
    if (RegExp(r'gr\.?b', caseSensitive: false).hasMatch(s) ||
        lower.contains('group b')) {
      return CarType.GRB;
    }

    // common car types / tags
    if (lower.contains('road')) return CarType.ROAD_CAR;
    if (lower.contains('racing') ||
        lower.contains('race car') ||
        lower.contains('racing car')) {
      return CarType.RACING_CAR;
    }
    if (lower.contains('profession') || lower.contains('tuned')) {
      return CarType.PROFESSIONALLY_TUNED;
    }
    if (lower.contains('hypercar')) return CarType.HYPERCAR;
    if (lower.contains('vision') || lower.contains('vgt')) {
      return CarType.VISION_GRAN_TURISMO;
    }
    if (lower.contains('concept')) return CarType.CONCEPT_CAR;
    if (lower.contains('safety')) return CarType.SAFETY_CAR;
    if (lower.contains('kei')) return CarType.KEI_CAR;
    if (lower.contains('electric')) return CarType.ELECTRIC_CAR;
    if (lower.contains('hybrid')) return CarType.HYBRID;
    if (lower.contains('gran turismo award') || lower.contains('sema')) {
      return CarType.GRAN_TURISMO_AWARD;
    }
    if (lower.contains('gt500')) return CarType.GT500;
    if (lower.contains('le mans') || lower.contains('lemans')) {
      return CarType.LE_MANS;
    }
    if (lower.contains('nurb') ||
        lower.contains('nürburgring') ||
        lower.contains('nurburgring')) {
      return CarType.NURBURGRING_24H;
    }
    if (lower.contains('wrc')) return CarType.WRC;
    if (lower.contains('kart')) return CarType.KART;
    if (lower.contains('pikes') || lower.contains('pike')) {
      return CarType.PIKES_PEAK;
    }
    if (lower.contains('midship')) return CarType.MIDSHIP;
    if (lower.contains('pickup')) return CarType.PICKUP_TRUCK;

    return null;
  }
}

/// Combination of a parsed [CarType] and an optional free-form model name.
///
/// When the scraper encounters a string that doesn't map cleanly to one of the
/// enumerated values, we still want to retain the original text so the UI can
/// display the actual car name.  `type` will be non-null when parsing succeeded,
/// otherwise `model` holds the raw string.
@immutable
class CarTypeInfo {
  final CarType? type;
  final String? model;

  const CarTypeInfo({this.type, this.model});

  String? get display => type?.code ?? model;

  factory CarTypeInfo.fromJson(Map<String, dynamic> j) => CarTypeInfo(
    type: CarTypeX.parse(j['type'] as String?),
    model: j['model'] as String?,
  );

  Map<String, dynamic> toJson() => {'type': type?.code, 'model': model};
}

@immutable
class DgEdgeDailyRace {
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
  /// Parsed car type and optional free-form model name when parsing failed.
  final CarTypeInfo? carType;
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

  /// Race letter — "A", "B", "C". From the `.event-type` badge or [metaTitle].
  final String? raceLetter;

  /// Week the race belongs to, as printed on the card ("Week 33/2026").
  final String? weekLabel;

  /// Human date range for the week ("10 August 2026 - 17 August 2026").
  final String? dateRange;

  // Participation figures, straight off the card's attributes.
  final int? playersCount;
  final int? wheelCount;
  final int? padCount;
  final int? vrCount;
  final int? tmCount;

  /// Reference lap times in milliseconds — overall leader, and the cut-offs
  /// for the top 100 and top 1000.
  final int? leadTimeMs;
  final int? top100TimeMs;
  final int? top1000TimeMs;

  /// Histogram of `DR_SR` pairs across everyone who has set a time, e.g.
  /// `{"D_S": 3323, "B_S": 2638, …}`. Empty when the card omits it.
  final Map<String, int> ratingsMatrix;

  /// Players per ISO country code, e.g. `{"US": 3259, "GB": 2221, …}`.
  final Map<String, int> countriesMatrix;

  /// Share of positive votes as printed on the cover badge, e.g. 68.
  final int? votesPercent;

  final String url; // full or relative url

  /// Map of special trackId substitutions for image URLs.
  /// Key: original trackId, Value: display trackId to use in URLs.
  /// Extend this map when new trackId image mappings are discovered.
  static const Map<String, String> _trackIdImageMappings = {
    '391': '280',
    '367': '360',
    '366': '358',
  };

  /// Get the display trackId for image URLs (handles special cases).
  String _getDisplayTrackId(String trackId) =>
      _trackIdImageMappings[trackId] ?? trackId;

  const DgEdgeDailyRace({
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
    this.raceLetter,
    this.weekLabel,
    this.dateRange,
    this.playersCount,
    this.wheelCount,
    this.padCount,
    this.vrCount,
    this.tmCount,
    this.leadTimeMs,
    this.top100TimeMs,
    this.top1000TimeMs,
    this.ratingsMatrix = const {},
    this.countriesMatrix = const {},
    this.votesPercent,
  });

  /// Lap time formatted the way the site prints it — `4:25.614`.
  static String? formatLapTime(int? milliseconds) {
    if (milliseconds == null || milliseconds <= 0) return null;
    final m = milliseconds ~/ 60000;
    final s = (milliseconds % 60000) ~/ 1000;
    final ms = milliseconds % 1000;
    final secs = s.toString().padLeft(2, '0');
    final millis = ms.toString().padLeft(3, '0');
    return m > 0 ? '$m:$secs.$millis' : '$s.$millis';
  }

  String? get leadTime => formatLapTime(leadTimeMs);
  String? get top100Time => formatLapTime(top100TimeMs);
  String? get top1000Time => formatLapTime(top1000TimeMs);

  /// Total entries counted in [ratingsMatrix], useful as a sanity check
  /// against [playersCount].
  int get ratedPlayersCount =>
      ratingsMatrix.values.fold<int>(0, (sum, v) => sum + v);

  factory DgEdgeDailyRace.fromJson(Map<String, dynamic> j) => DgEdgeDailyRace(
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
    carType: j['carType'] != null || j['carTypeRaw'] != null
        ? CarTypeInfo.fromJson({'type': j['carType'], 'model': j['carTypeRaw']})
        : null,
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
    raceLetter: j['raceLetter'] as String?,
    weekLabel: j['weekLabel'] as String?,
    dateRange: j['dateRange'] as String?,
    playersCount: j['playersCount'] as int?,
    wheelCount: j['wheelCount'] as int?,
    padCount: j['padCount'] as int?,
    vrCount: j['vrCount'] as int?,
    tmCount: j['tmCount'] as int?,
    leadTimeMs: j['leadTimeMs'] as int?,
    top100TimeMs: j['top100TimeMs'] as int?,
    top1000TimeMs: j['top1000TimeMs'] as int?,
    ratingsMatrix: _intMapFromJson(j['ratingsMatrix']),
    countriesMatrix: _intMapFromJson(j['countriesMatrix']),
    votesPercent: j['votesPercent'] as int?,
  );

  static Map<String, int> _intMapFromJson(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, int>{};
    raw.forEach((k, v) {
      final n = v is num ? v.toInt() : int.tryParse('$v');
      if (n != null) out['$k'] = n;
    });
    return out;
  }

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
    'carType': carType?.type?.code,
    'carTypeRaw': carType?.model,
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
    'raceLetter': raceLetter,
    'weekLabel': weekLabel,
    'dateRange': dateRange,
    'playersCount': playersCount,
    'wheelCount': wheelCount,
    'padCount': padCount,
    'vrCount': vrCount,
    'tmCount': tmCount,
    'leadTimeMs': leadTimeMs,
    'top100TimeMs': top100TimeMs,
    'top1000TimeMs': top1000TimeMs,
    if (ratingsMatrix.isNotEmpty) 'ratingsMatrix': ratingsMatrix,
    if (countriesMatrix.isNotEmpty) 'countriesMatrix': countriesMatrix,
    'votesPercent': votesPercent,
  };

  String? get trackImage => trackId != null
      ? 'https://data.dg-edge.com/images/tracks/$trackId/thumbs/Track${_getDisplayTrackId(trackId!)}.webp'
      : null;

  String? get trackBackgroundImage => trackId != null
      ? 'https://data.dg-edge.com/images/tracks/$trackId/Back${_getDisplayTrackId(trackId!)}.webp'
      : null;

  String? get trackLogotype => trackId != null
      ? 'https://data.dg-edge.com/images/tracks/$trackId/thumbs/Logo${_getDisplayTrackId(trackId!)}.webp'
      : null;

  @override
  String toString() => 'DgEdgeDailyRace($id, $title)';

  // Conservative, best-effort HTML element parsing from a listing/card element.
  // The selector strategy in the service tries to locate an <a> that links to /events/dailies/{id}
  /// Build a race from one listing card.
  ///
  /// The card is an `<a class="event card daily">` that carries its data in
  /// HTML attributes — `trackid`, `metatitle`, `playerscount`, `ratingsmatrix`
  /// and friends. Those are read first because they are already normalised;
  /// the visible markup is only consulted for the handful of figures that have
  /// no attribute (laps, refuels, tyre sets, tyre code, car class).
  static DgEdgeDailyRace? fromListElement(
    dom.Element el, {
    required String baseUrl,
  }) {
    try {
      // The card itself carries the metadata, but tolerate being handed a
      // wrapper by walking up to the nearest element that has the attributes.
      dom.Element card = el;
      dom.Node? cur = el;
      while (cur is dom.Element) {
        if (cur.attributes.containsKey('externalid') ||
            cur.classes.contains('event')) {
          card = cur;
          break;
        }
        cur = cur.parent;
      }

      final anchor = card.attributes.containsKey('href')
          ? card
          : (card.querySelector('a[href*="/events/dailies/"]') ?? card);
      final href = anchor.attributes['href'] ?? '';

      String? attr(String name) {
        final v = card.attributes[name];
        return (v == null || v.isEmpty) ? null : v;
      }

      int? intAttr(String name) => int.tryParse(attr(name) ?? '');

      // Ids: the URL is authoritative, `externalid` covers unlinked cards.
      final id =
          RegExp(r'/events/dailies/([\w-]+)').firstMatch(href)?.group(1) ??
          attr('externalid') ??
          baseUrl;

      final uri = href.startsWith('http')
          ? href
          : (href.isNotEmpty ? baseUrl + href : '$baseUrl/events/dailies/$id');

      final metaTitle = attr('metatitle');
      final metaDescription = attr('metadescription');

      // metatitle: "Week 33-2026 Daily A - Gran Turismo 7"
      // metadescription: "Special Stage Route X - GT7 Daily Race A - Week 33/2026 - …"
      final raceLetter =
          RegExp(
            r'Daily\s+Race\s+([A-Z])\b',
            caseSensitive: false,
          ).firstMatch(metaDescription ?? '')?.group(1) ??
          RegExp(
            r'Daily\s+([A-Z])\b',
            caseSensitive: false,
          ).firstMatch(metaTitle ?? '')?.group(1) ??
          card.querySelector('.event-type .badge')?.text.trim().replaceFirst(
            RegExp(r'^Daily\s*', caseSensitive: false),
            '',
          );

      // Visible week block: two spans, "Week 33/2026" then the date range.
      final timeSpans =
          card.querySelectorAll('.event-time span').map((e) => e.text.trim())
              .where((t) => t.isNotEmpty).toList();
      final weekLabel = timeSpans.isNotEmpty
          ? timeSpans.first
          : RegExp(
              r'Week\s+\d+[-/]\d{4}',
            ).firstMatch(metaTitle ?? '')?.group(0);
      final dateRange = timeSpans.length > 1 ? timeSpans[1] : null;

      // The track name moved into `.event-name`; the leading segment of
      // metadescription says the same thing and survives markup changes.
      final trackName =
          card.querySelector('.event-name')?.text.trim() ??
          metaDescription?.split(' - ').first.trim();

      final title = [
        if (raceLetter != null) 'Daily $raceLetter',
        if (trackName != null && trackName.isNotEmpty) trackName,
      ].join(' — ');

      // Car class or, for one-make races, the car model.
      final carTypeVal = card
          .querySelector('.event-car-type, .car-type span')
          ?.text
          .trim();
      final parsedCarType = CarTypeX.parse(carTypeVal);

      final tyreCode = card.querySelector('.tires .tire, .tire')?.text.trim();

      // Icon rows: flag = laps, gas pump = refuels, tyre = tyre sets.
      int? iconValue(String icon, {required bool expectMultiplier}) {
        final svg =
            card.querySelector('svg[data-icon="$icon"]') ??
            card.querySelector('.fa-$icon');
        if (svg == null) return null;
        final text = svg.parent?.text ?? '';
        final m = expectMultiplier
            ? RegExp(r'[x×]\s*(\d+)', caseSensitive: false).firstMatch(text)
            : RegExp(r'(\d+)').firstMatch(text);
        return m == null ? null : int.tryParse(m.group(1)!);
      }

      final votesText = card.querySelector('.event-votes')?.text ?? '';
      final votesPercent = int.tryParse(
        RegExp(r'(\d+)\s*%').firstMatch(votesText)?.group(1) ?? '',
      );

      return DgEdgeDailyRace(
        id: id,
        title: title.isEmpty ? (metaTitle ?? '(no title)') : title,
        url: uri,
        eventName: card.querySelector('.event-name')?.text.trim(),
        eventTime: card.querySelector('.event-time')?.text.trim(),
        trackName: trackName,
        laps: iconValue('flag-checkered', expectMultiplier: false),
        refuels: iconValue('gas-pump', expectMultiplier: true),
        tyresAvailable: iconValue('tire', expectMultiplier: true),
        tyreCode: tyreCode,
        tyre: TyreX.parse(tyreCode),
        carType: parsedCarType != null
            ? CarTypeInfo(type: parsedCarType)
            : (carTypeVal != null && carTypeVal.isNotEmpty
                  ? CarTypeInfo(model: carTypeVal)
                  : null),
        className: carTypeVal,
        externalId: attr('externalid'),
        rankingId: attr('rankingid'),
        trackId: attr('trackid'),
        status: attr('status'),
        // `is-active` on the card is the reliable live marker; the `isactive`
        // attribute is not always present.
        isActive: card.classes.contains('is-active'),
        isEnded: attr('isended') == 'true',
        totalPages: intAttr('totalpages'),
        lastUpdate: DateTime.tryParse(attr('lastupdate') ?? ''),
        lastUpdateStart: DateTime.tryParse(attr('lastupdatestart') ?? ''),
        metaTitle: metaTitle,
        metaDescription: metaDescription,
        raceLetter: raceLetter,
        weekLabel: weekLabel,
        dateRange: dateRange,
        playersCount: intAttr('playerscount'),
        wheelCount: intAttr('wheelcount'),
        padCount: intAttr('padcount'),
        vrCount: intAttr('vrcount'),
        tmCount: intAttr('tmcount'),
        leadTimeMs: intAttr('leadtime'),
        top100TimeMs: intAttr('top100time'),
        top1000TimeMs: intAttr('top1000time'),
        ratingsMatrix: _matrixAttribute(card, 'ratingsmatrix'),
        countriesMatrix: _matrixAttribute(card, 'countriesmatrix'),
        votesPercent: votesPercent,
      );
    } catch (e, st) {
      debugPrint(
        'DgEdgeDailyRace.fromListElement: parse failed for element — error: $e\n$st',
      );
      return null;
    }
  }

  /// Decode one of the JSON histogram attributes.
  ///
  /// `package:html` already resolves the `&quot;` entities the server emits,
  /// so the value can go straight to [jsonDecode]. Anything unparseable yields
  /// an empty map rather than failing the whole card.
  static Map<String, int> _matrixAttribute(dom.Element card, String name) {
    final raw = card.attributes[name];
    if (raw == null || raw.isEmpty) return const {};
    try {
      return _intMapFromJson(jsonDecode(raw));
    } catch (e) {
      debugPrint('DgEdgeDailyRace: could not decode $name — $e');
      return const {};
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
          if (cols.isNotEmpty) {
            players.add(
              cols
                  .map((e) => e.text.trim())
                  .whereNot((s) => s.isEmpty)
                  .join(' — '),
            );
          }
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

      String cap(String s) =>
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
                tyreCompound = cap(compMatch.group(1)!);
              } else {
                tyreType = v;
              }
            } else {
              tyreType = parts.first;
              tyreCompound = cap(parts.last);
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
        if (!raw.contains(':')) {
          continue; // skip ordinary paragraphs (avoids matching times like 1:34.567)
        }
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
