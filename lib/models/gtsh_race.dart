import 'package:html/dom.dart' as dom;

/// Representation of a single race card scraped from gtsh-rank.com/daily.
///
/// Only cards with a `.status.running` indicator are considered; other
/// entries such as "next week" or "ended" are ignored by
/// `GtshRace.fromElement`.
class GtshRace {
  final String label; // A, B, C, etc.
  final String trackName;
  final String tyreCode;

  // parameters section 1 (multipliers)
  final int? fuelMultiplier;
  final int? tyrewearMultiplier;
  final String pitStops;

  // parameters section 2
  final bool bop;
  final String damage;
  final String startType;

  // parameters section 3
  final bool carSettings;
  final String wideFender;

  GtshRace({
    required this.label,
    required this.trackName,
    required this.tyreCode,
    this.fuelMultiplier,
    this.tyrewearMultiplier,
    required this.pitStops,
    required this.bop,
    required this.damage,
    required this.startType,
    required this.carSettings,
    required this.wideFender,
  });

  /// Parses an individual `.race-card` element. Callers should ensure
  /// the element represents a running event (i.e. it contains
  /// `.status.running`); the constructor no longer performs this check.
  factory GtshRace.fromElement(dom.Element el) {
    String _text(dom.Element? e) => e?.text.trim() ?? '';

    final label = _text(el.querySelector('.daily-label'));
    final trackName = _text(el.querySelector('.track-name'));
    final tyreCode = _text(el.querySelector('.tire-container .tire'));

    int? parseMultiplier(String? txt) {
      if (txt == null) return null;
      final m = RegExp(r"(\d+)").firstMatch(txt);
      return m != null ? int.tryParse(m.group(1)!) : null;
    }

    final sections = el.querySelectorAll('.params-section .section');
    int? fuel;
    int? tyreWear;
    String pit = '';
    bool bop = false;
    String damage = '';
    String startType = '';
    bool carSettings = false;
    String wideFender = '';

    if (sections.isNotEmpty) {
      final rows = sections[0].querySelectorAll('.row');
      if (rows.isNotEmpty)
        fuel = parseMultiplier(_text(rows[0].querySelector('span:last-child')));
      if (rows.length > 1)
        tyreWear = parseMultiplier(
          _text(rows[1].querySelector('span:last-child')),
        );
      if (rows.length > 2)
        pit = _text(rows[2].querySelector('span:last-child'));
    }
    if (sections.length > 1) {
      final rows = sections[1].querySelectorAll('.row');
      for (final row in rows) {
        final key = _text(row.querySelector('.icon-text span')).toLowerCase();
        // `package:html` doesn't support :last-child, so pick last span manually
        String val;
        final spans = row.querySelectorAll('span');
        val = spans.isNotEmpty ? _text(spans.last) : '';
        if (key.contains('bop')) bop = val.toLowerCase() == 'yes';
        if (key.contains('damage')) damage = val;
        if (key.contains('start type')) startType = val;
      }
    }
    if (sections.length > 2) {
      final rows = sections[2].querySelectorAll('.row');
      for (final row in rows) {
        final key = _text(row.querySelector('.icon-text span')).toLowerCase();
        String val;
        final spans = row.querySelectorAll('span');
        val = spans.isNotEmpty ? _text(spans.last) : '';
        if (key.contains('car settings'))
          carSettings = val.toLowerCase() == 'yes';
        if (key.contains('wide fender')) wideFender = val;
      }
    }

    return GtshRace(
      label: label,
      trackName: trackName,
      tyreCode: tyreCode,
      fuelMultiplier: fuel,
      tyrewearMultiplier: tyreWear,
      pitStops: pit,
      bop: bop,
      damage: damage,
      startType: startType,
      carSettings: carSettings,
      wideFender: wideFender,
    );
  }
}
