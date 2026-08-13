// Race card shaped after the in-game Daily Races panel.
//
// GT7 shows four things and nothing else: the race letter with its BoP badge,
// a photo of the circuit with the layout drawn over it, the track name with a
// category chip, and a strip of label/value cells along the bottom. Everything
// else the two scrapers publish — regulations, the field breakdown, the record
// holder — lives in [DailyRaceDetailsSheet], one tap away.
//
// The card carries no fixed size. It fills whatever box the grid hands it and
// scales its type from its own width, so one widget covers a phone column and
// a desktop row of three without a second layout.
import 'package:flutter/material.dart';

import '../../models/dg_edge/dg_edge_daily_race.dart';
import '../../models/daily_races/daily_race.dart';
import 'daily_race_details_sheet.dart';

enum RaceType { upcoming, current, past }

/// Width over height of the in-game card, measured off a 1080p capture
/// (578 × 645). The grid in [DailyRacesDisplay] shapes its tiles with it.
const double kDailyRaceCardAspectRatio = 578 / 645;

// Section heights as fractions of the card, off the same capture.
const int _kHeroFlex = 519;
const int _kBodyFlex = 287;
const int _kFooterFlex = 194;

class DailyRaceCard extends StatelessWidget {
  final DailyRace race;

  /// Type of race (controls the badge in the header slot).
  final RaceType raceType;

  const DailyRaceCard({
    super.key,
    required this.race,
    this.raceType = RaceType.current,
  });

  /// The card body in GT7 is a cool blue-grey, appreciably lighter than this
  /// app's near-black surface. Lifting the theme colour toward that tone keeps
  /// the card recognisable without hard-coding a palette beside the theme.
  static Color _panelColor(ThemeData theme) => Color.alphaBlend(
    const Color(0xFF4A6FA5).withValues(alpha: 0.10),
    theme.colorScheme.surface,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _CardMetrics(constraints.maxWidth);

        return Material(
          color: _panelColor(theme),
          borderRadius: BorderRadius.circular(metrics.radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => DailyRaceDetailsSheet.show(context, race),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(metrics.radius),
                border: Border.all(
                  color: raceType == RaceType.past
                      ? Colors.white12
                      : Colors.white24,
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: _kHeroFlex,
                    child: _Hero(
                      race: race,
                      raceType: raceType,
                      metrics: metrics,
                    ),
                  ),
                  Expanded(
                    flex: _kBodyFlex,
                    child: _Title(race: race, metrics: metrics),
                  ),
                  Expanded(
                    flex: _kFooterFlex,
                    child: _StatsFooter(race: race, metrics: metrics),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Type and spacing for one card width, in the proportions GT7 uses.
///
/// Each size is a fraction of the card width with a floor under it — below
/// roughly 220pt the true proportions stop being legible, and a card that
/// cannot be read is a worse copy than one a point or two off.
class _CardMetrics {
  _CardMetrics(this.width);

  final double width;

  double _scaled(double ratio, double min) =>
      (width * ratio).clamp(min, double.infinity);

  double get radius => _scaled(0.021, 8);
  double get pad => _scaled(0.024, 8);

  double get raceLetter => _scaled(0.038, 11);
  double get badge => _scaled(0.026, 9);
  double get trackName => _scaled(0.036, 12);
  double get category => _scaled(0.052, 13);
  double get statLabel => _scaled(0.0225, 8);
  double get statValue => _scaled(0.059, 15);
  double get featuredValue => _scaled(0.066, 16);

  double get glyph => _scaled(0.011, 4);
}

/// Circuit photo with the layout outline over it, plus the header strip.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.race,
    required this.raceType,
    required this.metrics,
  });

  final DailyRace race;
  final RaceType raceType;
  final _CardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final background = race.trackBackgroundImage;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (background != null)
          Image.network(
            background,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          )
        else
          Container(color: Colors.white10),

        // The game darkens the top of the photo so the header reads on any
        // circuit.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
              stops: [0.0, 0.45],
            ),
          ),
        ),

        // GT7 draws the layout large and off to the right, clear of the
        // header, not tucked into a corner.
        if (race.trackImage != null)
          Align(
            alignment: const Alignment(0.55, 0.25),
            child: FractionallySizedBox(
              widthFactor: 0.55,
              heightFactor: 0.72,
              child: Image.network(
                race.trackImage!,
                key: ValueKey('track-${race.trackName ?? ''}'),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              metrics.pad,
              metrics.pad * 0.7,
              metrics.pad * 0.6,
              0,
            ),
            child: Row(
              children: [
                _GridGlyph(size: metrics.glyph),
                SizedBox(width: metrics.pad * 0.5),
                Expanded(
                  child: Text(
                    race.label != null
                        ? 'RACE ${race.label}'
                        : (race.className ?? '').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: metrics.raceLetter,
                      fontWeight: FontWeight.w700,
                      letterSpacing: metrics.raceLetter * 0.09,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
                _HeaderBadge(
                  race: race,
                  raceType: raceType,
                  metrics: metrics,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The slot GT7 uses for "BoP Applied". Race status wins it when the race is
/// not the running one, because that is the more useful fact then; BoP is
/// always spelled out in the details sheet.
class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.race,
    required this.raceType,
    required this.metrics,
  });

  final DailyRace race;
  final RaceType raceType;
  final _CardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final (label, icon, background, foreground) = switch (raceType) {
      RaceType.past => ('PAST', null, Colors.white70, Colors.black87),
      RaceType.upcoming => ('NEXT WEEK', null, Colors.amber, Colors.black87),
      RaceType.current => race.bop == true
          ? (
              'BoP Applied',
              Icons.balance,
              const Color(0xFFF5E34F),
              Colors.black87,
            )
          : (null, null, Colors.transparent, Colors.transparent),
    };

    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.badge * 0.6,
        vertical: metrics.badge * 0.25,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(metrics.badge * 0.35),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: metrics.badge, color: foreground),
            SizedBox(width: metrics.badge * 0.25),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: metrics.badge,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The little checkered square GT7 prints before the race letter.
class _GridGlyph extends StatelessWidget {
  const _GridGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget cell(bool filled) => Container(
      width: size,
      height: size,
      color: filled ? Colors.white : Colors.transparent,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [cell(true), cell(false)],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [cell(false), cell(true)],
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.race, required this.metrics});

  final DailyRace race;
  final _CardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final category = race.carType?.display;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.pad,
        metrics.pad * 0.8,
        metrics.pad,
        metrics.pad * 0.6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              race.trackName ?? '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: metrics.trackName,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          const Spacer(),
          if (category != null && category.isNotEmpty)
            CarCategory(info: race.carType, fontSize: metrics.category),
        ],
      ),
    );
  }
}

/// The bottom strip: three cells, then the record time set apart the way the
/// game sets "Next Race" apart.
class _StatsFooter extends StatelessWidget {
  const _StatsFooter({required this.race, required this.metrics});

  final DailyRace race;
  final _CardMetrics metrics;

  static String _compact(int value) {
    if (value < 10000) return value.toString();
    return '${(value / 1000).toStringAsFixed(1)}K';
  }

  @override
  Widget build(BuildContext context) {
    final tyre = race.tyre;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Two thirds for the three plain cells, one third for the one set
          // apart on the right — the split GT7 uses.
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'No. of Laps',
                    value: race.laps?.toString(),
                    valueColor: const Color(0xFF7FB2E5),
                    metrics: metrics,
                  ),
                ),
                const _CellDivider(),
                Expanded(
                  child: _StatCell(
                    label: 'Tyres',
                    value: tyre?.code,
                    valueColor: tyre?.color,
                    metrics: metrics,
                  ),
                ),
                const _CellDivider(),
                Expanded(
                  child: _StatCell(
                    label: 'Entrants',
                    value: race.playersCount == null
                        ? null
                        : _compact(race.playersCount!),
                    metrics: metrics,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: metrics.pad * 0.4),
          Expanded(
            flex: 1,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white10,
                border: Border(left: BorderSide(color: Colors.white24)),
              ),
              child: _StatCell(
                label: 'Best Lap',
                value: race.leadTime,
                metrics: metrics,
                featured: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) => const VerticalDivider(
    color: Colors.white24,
    thickness: 1,
    width: 1,
    indent: 8,
    endIndent: 8,
  );
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.metrics,
    this.value,
    this.valueColor,
    this.featured = false,
  });

  final String label;
  final String? value;
  final Color? valueColor;
  final _CardMetrics metrics;

  /// The cell GT7 sets apart on the right, printed a shade larger.
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.pad * 0.35,
        vertical: metrics.pad * 0.5,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: metrics.statLabel,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          SizedBox(height: metrics.pad * 0.15),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value ?? '—',
                maxLines: 1,
                style: TextStyle(
                  fontSize: featured
                      ? metrics.featuredValue
                      : metrics.statValue,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TyreCategory extends StatelessWidget {
  const TyreCategory({super.key, this.tyre});

  final Tyre? tyre;

  @override
  Widget build(BuildContext context) {
    if ((tyre?.code) != null) {
      return Center(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: tyre!.color, width: 1.0),
          ),
          padding: const EdgeInsets.all(6.0),
          child: Text(
            tyre!.code,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: tyre!.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class CarCategory extends StatelessWidget {
  const CarCategory({super.key, this.info, this.fontSize});

  final CarTypeInfo? info;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final display = info?.display;
    if (display == null || display.isEmpty) return const SizedBox.shrink();

    final size = fontSize ?? 13;
    final style = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    // A category code ("Gr.4") gets the boxed treatment GT7 gives it. A
    // one-make race carries a car model instead, which is far too long for a
    // chip — the game prints those as plain text, and so do we.
    if (info?.type == null) {
      return Text(
        display,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(fontSize: size * 0.72),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.55,
        vertical: size * 0.22,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.35),
        border: Border.all(color: Colors.white70, width: 1.4),
      ),
      child: Text(_gameCase(display), maxLines: 1, style: style),
    );
  }

  /// `CarType.code` is the canonical, all-caps form that also goes into JSON.
  /// The game prints "Gr.3", so the card does too — without touching the code
  /// itself, which other things compare against.
  static String _gameCase(String code) =>
      code.startsWith('GR.') ? 'Gr.${code.substring(3)}' : code;
}
