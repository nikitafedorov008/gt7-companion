import 'package:flutter/material.dart';

import '../../models/gt7_sport_race_stats.dart';
import '../../models/gt7_stats.dart';

/// Accent used for section headings and values, matching the periwinkle the
/// GT7 profile page uses for its statistics blocks.
const Color _gt7StatAccent = Color(0xFF8D9FE8);

/// Pink used for the collection-level ring on the site.
const Color _gt7CollectionAccent = Color(0xFFFF3B77);

/// Statistics panel modelled on the layout of the GT7 profile page.
///
/// The site groups its figures into blocks — car life, driving, GT world,
/// game play, social, sport — which are the same groups `/stats/get` returns,
/// so the sections here are the API's own structure rather than a re-grouping
/// of it. Each block is a heading on the left, a rule, and label/value rows.
///
/// Labels are in English to match the rest of the app; the site renders the
/// same fields in the viewer's language.
class Gt7StatsPanel extends StatelessWidget {
  const Gt7StatsPanel({
    required this.stats,
    this.sportRaces = const [],
    super.key,
  });

  final Gt7Stats stats;
  final List<Gt7SportRaceStats> sportRaces;

  /// Below this the two columns stack into one.
  static const double _twoColumnBreakpoint = 760;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = _buildSections();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumn = constraints.maxWidth >= _twoColumnBreakpoint;
          return twoColumn
              ? _buildTwoColumns(sections)
              : _buildSingleColumn(sections);
        },
      ),
    );
  }

  /// Pairs of sections, side by side, exactly as the site arranges them.
  Widget _buildTwoColumns(List<_Section> sections) {
    final rows = <Widget>[];
    for (var i = 0; i < sections.length; i += 2) {
      final left = sections[i];
      final right = i + 1 < sections.length ? sections[i + 1] : null;

      if (rows.isNotEmpty) rows.add(const _SectionDivider());
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _SectionView(section: left)),
              const SizedBox(width: 24),
              const VerticalDivider(width: 1, thickness: 1),
              const SizedBox(width: 24),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _SectionView(section: right),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildSingleColumn(List<_Section> sections) {
    final children = <Widget>[];
    for (final section in sections) {
      if (children.isNotEmpty) children.add(const _SectionDivider());
      children.add(_SectionView(section: section));
    }
    return Column(children: children);
  }

  List<_Section> _buildSections() {
    final carLife = stats.carLife;
    final driving = stats.driving;
    final gamePlay = stats.gamePlay;
    final gtWorld = stats.gtWorld;
    final social = stats.social;
    final sport = stats.sportsMode;
    final medals = stats.medals;

    int sumRaces(int Function(Gt7SportRaceStats) pick) =>
        sportRaces.fold<int>(0, (sum, r) => sum + pick(r));

    return [
      _Section('Car Life', [
        ('Cars purchased', '${carLife.buyCarCount}'),
        ('Spent on cars', gt7Credits(carLife.buyCarCreditAmount)),
        ('Spent on customisation', gt7Credits(carLife.customizeCreditAmount)),
        ('Spent on tuning', gt7Credits(carLife.tuningCreditAmount)),
        ('Car collection', '${carLife.carDictionaryProgress}%'),
      ]),
      _Section('Driving', [
        ('Total distance', gt7Kilometres(driving.totalKm)),
        ('Time driving', gt7Duration(driving.drivingTimeSeconds)),
        ('Fuel used', gt7Litres(driving.totalFuelConsumption)),
        (
          'Average consumption',
          '${gt7Thousandths(driving.averageFuelConsumption)} L/km',
        ),
      ]),
      _Section('GT World', [
        ('Circuit experience', '${gtWorld.circuitExperienceProgress}'),
        ('Drift points', '${gtWorld.driftPoint}'),
      ]),
      _Section('Game Play', [
        ('Credits earned', gt7Credits(gamePlay.creditAmount)),
        ('Days online', '${stats.loginDayCount}'),
        ('Photos taken', '${gamePlay.photoCount}'),
        ('Play time', gt7Duration(gamePlay.playTimeSeconds)),
      ]),
      // The site's "Social" block lists share/like/repost counts per content
      // type. Those nested counters are not parsed yet, so this shows the
      // follow figures from the same block rather than empty rows.
      _Section('Social', [
        ('Followers', '${social.followers}'),
        ('Following', '${social.followings}'),
        ('Friends', '${social.friends}'),
      ]),
      _Section('Sport', [
        ('Clean races', '${sport.cleanRaceCount}'),
        ('Fastest laps', '${sport.fastestLapCount}'),
        ('Pole positions', '${sport.polePositionCount}'),
        // The site prints the sum across race categories here, which differs
        // from both sports_mode.race_count and get_sport_profile.race_count.
        if (sportRaces.isNotEmpty) ...[
          ('Races', '${sumRaces((r) => r.races)}'),
          ('Wins', '${sumRaces((r) => r.wins)}'),
          ('Top 5 finishes', '${sumRaces((r) => r.top5)}'),
        ] else ...[
          ('Races', '${sport.raceCount}'),
          ('Wins', '${sport.winCount}'),
        ],
        ('Gold finishes', '${medals.gold}'),
        ('Silver finishes', '${medals.silver}'),
        ('Bronze finishes', '${medals.bronze}'),
      ]),
    ];
  }
}

class _Section {
  const _Section(this.title, this.rows);
  final String title;
  final List<(String, String)> rows;
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section});
  final _Section section;

  /// Width of the heading gutter. Fixed so headings and rules line up across
  /// sections, the way they do on the site.
  static const double _headingWidth = 132;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _headingWidth,
            child: Text(
              section.title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: _gt7StatAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 2,
            // Matches the row block so the rule reads as a bracket around the
            // values rather than a full-height column separator.
            height: section.rows.length * 32,
            color: _gt7StatAccent.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final (label, value) in section.rows)
                  _StatRow(label: label, value: value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _gt7StatAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1);
}

// ---------------------------------------------------------------------------
// Header ratings
// ---------------------------------------------------------------------------

/// The four figures the site puts directly under the cover image: collection
/// level, licence, driver rating and safety rating.
class Gt7RatingRow extends StatelessWidget {
  const Gt7RatingRow({
    required this.collectionLevel,
    required this.experience,
    required this.license,
    required this.driverRating,
    required this.driverRatingRatio,
    required this.safetyRating,
    super.key,
  });

  final int? collectionLevel;
  final int? experience;
  final String? license;
  final String? driverRating;
  final double? driverRatingRatio;
  final String? safetyRating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tiles = <Widget>[
      _RatingTile(
        label: 'Collection level',
        value: experience == null
            ? '—'
            : '${gt7Grouped(experience! ~/ 1000)} pts',
        emphasis: true,
        leading: _LevelRing(level: collectionLevel),
      ),
      _RatingTile(
        label: 'Licence',
        value: license ?? '—',
        leading: _LicenceBadge(license: license),
      ),
      _RatingTile(
        label: 'Driver rating',
        value: driverRating ?? '—',
        leading: _RatingGauge(
          text: 'DR',
          ratio: driverRatingRatio,
          color: theme.colorScheme.primary,
        ),
        progress: driverRatingRatio,
      ),
      _RatingTile(
        label: 'Safety rating',
        value: safetyRating ?? '—',
        leading: _RatingGauge(
          text: 'SR',
          ratio: null,
          color: const Color(0xFF69F0AE),
        ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Four across is unreadable on a phone; two rows of two is how the
          // site behaves at narrow widths too.
          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                IntrinsicHeight(
                  child: Row(children: [
                    Expanded(child: tiles[0]),
                    const VerticalDivider(width: 1),
                    Expanded(child: tiles[1]),
                  ]),
                ),
                const Divider(height: 24),
                IntrinsicHeight(
                  child: Row(children: [
                    Expanded(child: tiles[2]),
                    const VerticalDivider(width: 1),
                    Expanded(child: tiles[3]),
                  ]),
                ),
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const VerticalDivider(width: 1),
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({
    required this.label,
    required this.value,
    required this.leading,
    this.emphasis = false,
    this.progress,
  });

  final String label;
  final String value;
  final Widget leading;
  final bool emphasis;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: emphasis
                        ? _gt7CollectionAccent
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.12,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Collection level in a pink ring, as on the site.
class _LevelRing extends StatelessWidget {
  const _LevelRing({required this.level});
  final int? level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _gt7CollectionAccent, width: 2),
      ),
      child: Text(
        level?.toString() ?? '—',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: _gt7CollectionAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LicenceBadge extends StatelessWidget {
  const _LicenceBadge({required this.license});
  final String? license;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B5CF6), Color(0xFF5B32C9)],
        ),
      ),
      child: Text(
        license ?? '—',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Ring with the rating abbreviation inside, filled to [ratio] when known.
class _RatingGauge extends StatelessWidget {
  const _RatingGauge({
    required this.text,
    required this.ratio,
    required this.color,
  });

  final String text;
  final double? ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: ratio?.clamp(0.0, 1.0) ?? 1.0,
              strokeWidth: 2,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.12,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

/// `60638522` → `60 638 522`, the grouping the site uses.
String gt7Grouped(int value) {
  final digits = value.abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}

String gt7Credits(int value) => 'Cr. ${gt7Grouped(value)}';

String gt7Kilometres(double km) => '${km.toStringAsFixed(2)} km';

/// Fuel figures arrive in thousandths — `9402860` is 9402.86 litres.
String gt7Thousandths(int value) => (value / 1000).toStringAsFixed(2);

String gt7Litres(int milliLitres) =>
    '${(milliLitres / 1000).toStringAsFixed(1)} L';

/// `532648` → `147:57:28`.
///
/// Hours are not wrapped: the site prints `47:57:28` for this value, losing
/// the leading digit of 147, and reproducing that would just be copying a
/// display bug.
String gt7Duration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
