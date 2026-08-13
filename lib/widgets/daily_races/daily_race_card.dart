// Race card shaped after the in-game Daily Races panel.
//
// GT7 shows four things and nothing else: the race letter with its BoP badge,
// a photo of the circuit with the layout drawn over it, the track name with a
// category chip, and a strip of label/value cells along the bottom. Everything
// else the two scrapers publish — regulations, the field breakdown, the record
// holder — lives in [DailyRaceDetailsSheet], one tap away.
import 'package:flutter/material.dart';

import '../../models/dg_edge/dg_edge_daily_race.dart';
import '../../models/daily_races/daily_race.dart';
import 'daily_race_details_sheet.dart';

enum RaceType { upcoming, current, past }

/// Size of a card. [DailyRacesDisplay] sizes its strip from these so the two
/// cannot drift apart — a fixed strip with a taller card is what overflowed
/// here before.
const double kDailyRaceCardWidth = 280;
const double kDailyRaceCardHeight = 300;

const double _kHeroHeight = 148;
const double _kFooterHeight = 62;

class DailyRaceCard extends StatelessWidget {
  final DailyRace race;

  /// Type of race (controls the badge in the header slot).
  final RaceType raceType;

  const DailyRaceCard({
    super.key,
    required this.race,
    this.raceType = RaceType.current,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: kDailyRaceCardWidth,
      height: kDailyRaceCardHeight,
      child: Material(
        color: surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => DailyRaceDetailsSheet.show(context, race),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
                _Hero(race: race, raceType: raceType),
                Expanded(child: _Title(race: race)),
                _StatsFooter(race: race),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circuit photo with the layout outline over it, plus the header strip.
class _Hero extends StatelessWidget {
  const _Hero({required this.race, required this.raceType});

  final DailyRace race;
  final RaceType raceType;

  @override
  Widget build(BuildContext context) {
    final background = race.trackBackgroundImage;

    return SizedBox(
      height: _kHeroHeight,
      child: Stack(
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

          if (race.trackImage != null)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 14, 12),
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
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
              child: Row(
                children: [
                  const _GridGlyph(),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      race.label != null
                          ? 'RACE ${race.label}'
                          : (race.className ?? '').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black87),
                        ],
                      ),
                    ),
                  ),
                  _HeaderBadge(race: race, raceType: raceType),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The slot GT7 uses for "BoP Applied". Race status wins it when the race is
/// not the running one, because that is the more useful fact then; BoP is
/// always spelled out in the details sheet.
class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.race, required this.raceType});

  final DailyRace race;
  final RaceType raceType;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (raceType) {
      RaceType.past => ('PAST', Colors.white70, Colors.black87),
      RaceType.upcoming => ('NEXT WEEK', Colors.amber, Colors.black87),
      RaceType.current => race.bop == true
          ? ('BoP Applied', const Color(0xFFF5E34F), Colors.black87)
          : (null, Colors.transparent, Colors.transparent),
    };

    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The little checkered square GT7 prints before the race letter.
class _GridGlyph extends StatelessWidget {
  const _GridGlyph();

  @override
  Widget build(BuildContext context) {
    Widget cell(bool filled) => Container(
      width: 5,
      height: 5,
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
  const _Title({required this.race});

  final DailyRace race;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = race.carType?.display;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              race.trackName ?? '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
          const Spacer(),
          if (category != null && category.isNotEmpty)
            CarCategory(info: race.carType),
        ],
      ),
    );
  }
}

/// The bottom strip: three cells, then the record time set apart the way the
/// game sets "Next Race" apart.
class _StatsFooter extends StatelessWidget {
  const _StatsFooter({required this.race});

  final DailyRace race;

  static String _compact(int value) {
    if (value < 10000) return value.toString();
    return '${(value / 1000).toStringAsFixed(1)}K';
  }

  @override
  Widget build(BuildContext context) {
    final tyre = race.tyre;

    return Container(
      height: _kFooterHeight,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'No. of Laps',
                    value: race.laps?.toString(),
                    valueColor: const Color(0xFF7FB2E5),
                  ),
                ),
                const _CellDivider(),
                Expanded(
                  child: _StatCell(
                    label: 'Tyres',
                    value: tyre?.code,
                    valueColor: tyre?.color,
                  ),
                ),
                const _CellDivider(),
                Expanded(
                  child: _StatCell(
                    label: 'Entrants',
                    value: race.playersCount == null
                        ? null
                        : _compact(race.playersCount!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white10,
                border: Border(left: BorderSide(color: Colors.white24)),
              ),
              child: _StatCell(label: 'Best Lap', value: race.leadTime),
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
    indent: 10,
    endIndent: 10,
  );
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, this.value, this.valueColor});

  final String label;
  final String? value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value ?? '—',
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: valueColor,
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
  const CarCategory({super.key, this.info});

  final CarTypeInfo? info;

  @override
  Widget build(BuildContext context) {
    final display = info?.display;
    if (display == null || display.isEmpty) return const SizedBox.shrink();

    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 13,
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
        style: style,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white70),
      ),
      child: Text(display, maxLines: 1, style: style),
    );
  }
}
