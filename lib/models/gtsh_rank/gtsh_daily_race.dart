import 'package:html/dom.dart' as dom;

/// One race card from gtsh-rank.com/daily.
///
/// The site was redesigned: the card is now `<article class="daily-race-card">`
/// (previously `.race-card`) and every inner selector changed with it. The
/// race parameters survived the redesign in a simpler shape — `.daily-specs`
/// is a flat list of `<span>key</span><strong>value</strong>` pairs — and the
/// card gained the world leader's identity.
class GtshDailyRace {
  static const String host = 'https://gtsh-rank.com';

  final String label; // A, B, C, etc.
  final String trackName;
  final String tyreCode;

  /// 'running' or 'ended'. The site prints "Running" / "Archived"; the two
  /// legacy values are kept because [DailyRace] switches on them.
  final String status;

  /// Ranking board id, e.g. `p_rt_1014514_001`. This is the game's own
  /// identifier and matches DG-Edge's `rankingid`, which is what lets the two
  /// sources be paired reliably.
  final String? rankingId;

  /// Car class ("Gr.3") or "Specified Car" for one-make races.
  final String? category;

  final String? trackImage;

  /// Start of the race week, from the card's date link.
  final DateTime? weekStart;
  final String? weekUrl;
  final String? leaderboardUrl;

  /// Clock label the card prints next to the leader button — the site's own
  /// "updated at" time, not a lap time. Confirmed by comparison: this reads
  /// `15:39` for Special Stage Route X while the actual leader lap there is
  /// 4:25.614. The real lap time comes from DG-Edge's `leadtime`.
  final String? updatedAtLabel;

  // World leader, new in the redesign.
  final String? leaderName;
  final String? leaderCarName;
  final String? leaderAvatar;
  final String? leaderCountryFlag;

  /// Image of the leader's car. For a one-make race that is the race car; in
  /// a class race it is only whatever the fastest driver chose.
  final String? carImage;

  // Race parameters from `.daily-specs`.
  final int? fuelMultiplier;
  final int? tyrewearMultiplier;
  final String pitStops;
  final bool bop;
  final String damage;
  final String startType;
  final bool carSettings;

  /// New in the redesign — "Custom", "Real", "Off".
  final String? slipstream;

  /// No longer published by the site; kept so existing consumers still build.
  final String? wideFender;

  const GtshDailyRace({
    required this.label,
    required this.trackName,
    required this.tyreCode,
    required this.status,
    this.rankingId,
    this.category,
    this.trackImage,
    this.weekStart,
    this.weekUrl,
    this.leaderboardUrl,
    this.updatedAtLabel,
    this.leaderName,
    this.leaderCarName,
    this.leaderAvatar,
    this.leaderCountryFlag,
    this.carImage,
    this.fuelMultiplier,
    this.tyrewearMultiplier,
    required this.pitStops,
    required this.bop,
    required this.damage,
    required this.startType,
    required this.carSettings,
    this.slipstream,
    this.wideFender,
  });

  /// Parse one `article.daily-race-card`.
  factory GtshDailyRace.fromElement(dom.Element el) {
    String? text(String selector) {
      final t = el.querySelector(selector)?.text.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    String? absolute(String? src) {
      if (src == null || src.isEmpty) return null;
      return src.startsWith('/') ? '$host$src' : src;
    }

    String? imageSrc(String selector) =>
        absolute(el.querySelector(selector)?.attributes['src']);

    // `.daily-specs` is a flat list of key/value divs.
    final specs = <String, String>{};
    for (final row in el.querySelectorAll('.daily-specs > div')) {
      final key = row.querySelector('span')?.text.trim().toLowerCase();
      final value = row.querySelector('strong')?.text.trim();
      if (key != null && key.isNotEmpty && value != null) specs[key] = value;
    }

    int? multiplier(String? raw) {
      if (raw == null) return null;
      final m = RegExp(r'(\d+)').firstMatch(raw);
      return m == null ? null : int.tryParse(m.group(1)!);
    }

    // The status badge replaced the old `.status.running/.next/.ended` classes.
    final badge = el.querySelector('.status-badge');
    final expired =
        el.classes.contains('is-expired') ||
        (badge?.classes.contains('expired') ?? false);
    final status = expired ? 'ended' : 'running';

    // Leader details live on the info button as data-* attributes, with the
    // visible markup as a fallback.
    final leaderButton = el.querySelector('.daily-lap-info');
    String? data(String name) {
      final v = leaderButton?.attributes['data-$name'];
      return (v == null || v.isEmpty) ? null : v;
    }

    final startHref = el.querySelector('.daily-start-date')?.attributes['href'];
    final weekMatch = RegExp(
      r'(\d{4}-\d{2}-\d{2})',
    ).firstMatch(startHref ?? '');

    return GtshDailyRace(
      // "Daily Race A" -> "A"; the corner badge carries the same letter.
      label:
          text('.daily-letter') ??
          RegExp(r'Daily\s+Race\s+([A-Z])', caseSensitive: false)
                  .firstMatch(text('.daily-title-meta span') ?? '')
                  ?.group(1) ??
          '',
      trackName:
          el.querySelector('.daily-title-copy h2')?.attributes['title']?.trim() ??
          text('.daily-title-copy h2') ??
          '',
      tyreCode: text('.daily-tires .tire-ring') ?? '',
      status: status,
      rankingId: data('board'),
      category: text('.daily-category'),
      trackImage: imageSrc('.daily-course'),
      weekStart: weekMatch == null ? null : DateTime.tryParse(weekMatch.group(1)!),
      weekUrl: absolute(startHref),
      leaderboardUrl: absolute(
        el.querySelector('.daily-card-link')?.attributes['href'],
      ),
      updatedAtLabel: text('.daily-time'),
      leaderName: data('driver-name') ?? text('.daily-leader-name'),
      leaderCarName: data('car-name'),
      leaderAvatar: absolute(data('avatar')) ?? imageSrc('.leader-avatar'),
      leaderCountryFlag:
          absolute(data('country-flag')) ?? imageSrc('.leader-flag'),
      carImage: absolute(data('car-image')) ?? imageSrc('.daily-title-car'),
      fuelMultiplier: multiplier(specs['fuel']),
      tyrewearMultiplier: multiplier(specs['tyres']),
      // "-" means no mandatory stop; keep the site's own wording.
      pitStops: specs['pit'] ?? '',
      bop: (specs['bop'] ?? '').toLowerCase() == 'on',
      damage: specs['damage'] ?? '',
      startType: specs['start'] ?? '',
      carSettings: (specs['setup'] ?? '').toLowerCase() == 'allowed',
      slipstream: specs['slipstream'],
      wideFender: specs['wide fender'],
    );
  }

  @override
  String toString() =>
      'GtshDailyRace($label, $trackName, $tyreCode, $status, '
      'rankingId: $rankingId)';
}
