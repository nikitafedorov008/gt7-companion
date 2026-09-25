// Everything about a daily race that does not belong on the card.
//
// The card is a copy of the in-game panel and deliberately shows only what GT7
// shows. The two scrapers publish a great deal more — full regulations, the
// record holder, how the field breaks down by rating and by country — and this
// is where that lands.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/daily_races/daily_race.dart';
import '../../models/dg_edge/dg_edge_daily_race.dart';
import 'race_field_histogram.dart';

class DailyRaceDetailsSheet extends StatelessWidget {
  const DailyRaceDetailsSheet({
    super.key,
    required this.race,
    this.scrollController,
  });

  final DailyRace race;

  /// Supplied by [DraggableScrollableSheet] so the list drives the sheet's
  /// drag; null in the dialog, where the list scrolls on its own.
  final ScrollController? scrollController;

  /// Opens the details for [race] — a bottom sheet on a phone, a centred
  /// dialog once there is desktop-sized room for one.
  static Future<void> show(BuildContext context, DailyRace race) {
    final wide = MediaQuery.sizeOf(context).width >= 700;

    if (wide) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: DailyRaceDetailsSheet(race: race),
          ),
        ),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) =>
            DailyRaceDetailsSheet(race: race, scrollController: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dg = race.dgEdge;

    final regulations = <String, String?>{
      'BoP': _yesNo(race.bop),
      'Car setup': _allowed(race.carSettings),
      'Damage': race.damage,
      'Start type': race.startType,
      'Fuel use': _multiplier(race.fuelMultiplier),
      'Tyre wear': _multiplier(race.tyrewearMultiplier),
      'Slipstream': race.slipstream,
      'Pit stops': race.pitDescription,
      'Wide body': race.wideFender,
      'Tyre sets': race.tyresAvailable?.toString(),
      'Refuelling': race.refuels?.toString(),
      'Tyre compound': race.tyreCompound ?? race.tyre?.code,
    };

    final field = <String, String?>{
      'Entrants': dg?.playersCount?.toString(),
      'Approval': race.votesPercent == null ? null : '${race.votesPercent}%',
      'Wheel': dg?.wheelCount?.toString(),
      'Controller': dg?.padCount?.toString(),
      'VR': dg?.vrCount?.toString(),
      'Trackmouse': dg?.tmCount?.toString(),
    };

    final times = <String, String?>{
      'Leader': race.leadTime,
      'Top 100': dg?.top100Time,
      'Top 1000': dg?.top1000Time,
    };

    return ListView(
      controller: scrollController,
      // The home page floats its navigation bar over everything, this sheet
      // included, so the last rows need room to clear it.
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        _Header(race: race),
        const SizedBox(height: 20),

        if (race.leaderName != null) ...[
          _LeaderPanel(race: race),
          const SizedBox(height: 20),
        ],

        _Section(title: 'Regulations', values: regulations),
        _Section(title: 'Reference times', values: times),
        _Section(title: 'Field', values: field),

        if (race.ratingsMatrix.isNotEmpty) ...[
          const SizedBox(height: 4),
          RaceFieldHistogram(
            title: 'Entrants by rating',
            values: race.ratingsMatrix,
            labelBuilder: _ratingLabel,
          ),
        ],
        if (race.countriesMatrix.isNotEmpty) ...[
          const SizedBox(height: 4),
          RaceFieldHistogram(
            title: 'Entrants by country',
            values: race.countriesMatrix,
          ),
        ],

        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (race.url != null)
              _SourceLink(
                label: 'DG-Edge',
                url: race.url!.startsWith('http')
                    ? race.url!
                    : 'https://www.dg-edge.com${race.url}',
              ),
            if (race.gtsh?.leaderboardUrl != null)
              _SourceLink(
                label: 'GTSh leaderboard',
                url: race.gtsh!.leaderboardUrl!,
              ),
          ],
        ),

        if (dg?.lastUpdate != null) ...[
          const SizedBox(height: 16),
          Text(
            'Updated ${dg!.lastUpdate!.toLocal()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ],
    );
  }

  static String? _yesNo(bool? value) => switch (value) {
    true => 'Applied',
    false => 'Off',
    null => null,
  };

  static String? _allowed(bool? value) => switch (value) {
    true => 'Allowed',
    false => 'Fixed',
    null => null,
  };

  static String? _multiplier(int? value) => value == null ? null : '×$value';

  /// `D_S` is a bucket of drivers rated DR D and SR S.
  static String _ratingLabel(String key) {
    final parts = key.split('_');
    if (parts.length != 2) return key;
    return 'DR ${parts[0]} · SR ${parts[1]}';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.race});

  final DailyRace race;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = race.carType?.display;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (race.trackBackgroundImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    race.trackBackgroundImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.white10),
                  ),
                  if (race.trackImage != null)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.network(
                          race.trackImage!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (race.label != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  'RACE ${race.label}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            if (race.weekLabel != null)
              Text(
                race.weekLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          race.trackName ?? '—',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (category != null && category.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white70),
                ),
                child: Text(
                  category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The record holder, as published by GTSh-rank.
class _LeaderPanel extends StatelessWidget {
  const _LeaderPanel({required this.race});

  final DailyRace race;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (race.leaderAvatar != null)
            ClipOval(
              child: Image.network(
                race.leaderAvatar!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (race.leaderCountryFlag != null) ...[
                      Image.network(
                        race.leaderCountryFlag!,
                        width: 20,
                        height: 14,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        race.leaderName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (race.leaderCarName != null)
                  Text(
                    race.leaderCarName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (race.leadTime != null)
            Text(
              race.leadTime!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

/// A titled block of label/value rows. Entries with no value are dropped, so a
/// race that only one source covers does not show a column of dashes.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.values});

  final String title;
  final Map<String, String?> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final present = values.entries
        .where((e) => e.value != null && e.value!.isNotEmpty)
        .toList();

    if (present.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        ...present.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  e.value!,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(label),
    );
  }
}
