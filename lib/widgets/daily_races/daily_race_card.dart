// Reused card component
import 'package:flutter/material.dart';

import '../../models/dg_edge/dg_edge_daily_race.dart';
import '../../models/daily_races/daily_race.dart';
import 'race_field_histogram.dart';

enum RaceType { upcoming, current, past }

class DailyRaceCard extends StatelessWidget {
  final DailyRace race;

  /// Type of race (controls styling & banner).
  final RaceType raceType;

  const DailyRaceCard({
    super.key,
    required this.race,
    this.raceType = RaceType.current,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final it = race;

    // Determine colors and banner text based on race type
    final (borderColor, bannerColor, bannerText) = switch (raceType) {
      RaceType.upcoming => (Colors.amber, Colors.amber, 'FUTURE'),
      RaceType.past => (Colors.grey, Colors.grey, 'PAST'),
      RaceType.current => (Colors.white24, Colors.transparent, ''),
    };

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.04),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    image: it.trackBackgroundImage != null
                        ? DecorationImage(
                            image: NetworkImage(it.trackBackgroundImage!),
                            colorFilter: const ColorFilter.mode(
                              Colors.black38,
                              BlendMode.srcATop,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (it.trackLogotype != null)
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  it.trackLogotype!,
                                  key: ValueKey('thumb-${it.trackName ?? ''}'),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          if (it.trackImage != null)
                            Align(
                              alignment: Alignment.center,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  it.trackImage!,
                                  key: ValueKey('track-${it.trackName ?? ''}'),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.flag),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Banner for upcoming/past races
                if (bannerText.isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bannerColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        bannerText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Flexible(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Column(
                    spacing: 8.0,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (it.trackName != null)
                        Text(
                          it.trackName!,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      CarCategory(info: it.carType),
                      if (it.weekLabel != null)
                        Text(
                          it.weekLabel!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(
                  color: Colors.white24,
                  thickness: 1.0,
                  height: 1.0,
                  indent: 0,
                  endIndent: 0.0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: IntrinsicHeight(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 4.0,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (it.laps != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'laps',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    it.laps!.toString(),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          if (it.tyresAvailable != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'tyre intake',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    it.tyresAvailable!.toString(),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          if (it.pitStops != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'pit-stops',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    it.pitStops!.toString(),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          if (it.refuels != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'fuel intake',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    it.refuels!.toString(),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          if (it.playersCount != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'entrants',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    it.playersCount!.toString(),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          if (it.leadTime != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'leader',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    it.leadTime!,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 6),
                          VerticalDivider(
                            color: Colors.white24,
                            thickness: 1.0,
                            width: 16.0,
                            indent: 0.0,
                            endIndent: 0.0,
                          ),
                          const SizedBox(width: 6),
                          TyreCategory(tyre: it.tyre),
                        ],
                      ),
                    ),
                  ),
                ),
                if (it.leaderName != null) _RaceLeader(race: it),
                if (it.ratingsMatrix.isNotEmpty ||
                    it.countriesMatrix.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                    child: Column(
                      children: [
                        RaceFieldHistogram(
                          title: 'Field by rating',
                          values: it.ratingsMatrix,
                          labelBuilder: formatRatingBucket,
                        ),
                        RaceFieldHistogram(
                          title: 'Field by country',
                          values: it.countriesMatrix,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The current world-record holder, as published by GTSh-rank.
class _RaceLeader extends StatelessWidget {
  const _RaceLeader({required this.race});

  final DailyRace race;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          if (race.leaderAvatar != null)
            ClipOval(
              child: Image.network(
                race.leaderAvatar!,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (race.leaderCountryFlag != null) ...[
            const SizedBox(width: 6),
            Image.network(
              race.leaderCountryFlag!,
              width: 18,
              height: 12,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  race.leaderName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
    if (display != null && display.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          display,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
