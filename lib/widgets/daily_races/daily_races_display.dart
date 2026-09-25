import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/daily_races/daily_race.dart';
import '../../repositories/sport_repository.dart';
import 'daily_race_card.dart';

/// Combined widget that displays daily races from all categories (upcoming, current, past)
/// with configurable visibility for each section.
class DailyRacesDisplay extends StatefulWidget {
  /// Show upcoming (not yet started) races
  final bool showUpcoming;

  /// Show current (active) races
  final bool showCurrent;

  /// Show past (ended) races
  final bool showPast;

  /// If true and upcoming races exist, hides current and past races
  /// This flag overrides showCurrent and showPast settings
  final bool ifFutureExistsNotShowPast;

  const DailyRacesDisplay({
    super.key,
    this.showUpcoming = true,
    this.showCurrent = true,
    this.showPast = true,
    this.ifFutureExistsNotShowPast = false,
  });

  @override
  State<DailyRacesDisplay> createState() => _DailyRacesDisplayState();
}

class _DailyRacesDisplayState extends State<DailyRacesDisplay> {
  String? _error;

  @override
  void initState() {
    super.initState();
    // Delay data-fetch until the first frame to avoid rebuild-during-build errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (!mounted) return;

    // Ignore local loading state and rely on the repository's `isLoading`.
    // This ensures the skeleton UI is shown while the repository fetches data.
    setState(() {
      _error = null;
    });

    try {
      final svc = context.read<SportRepository>();
      await svc.fetchDailyRaces();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SportRepository>(
      builder: (context, service, _) {
        if (service.error != null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Daily races', style: theme.textTheme.titleMedium),
                    IconButton(
                      onPressed: () =>
                          service.fetchDailyRaces(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  service.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ),
          );
        }

        if (service.isLoading) {
          final fakeItems = List<DailyRace>.generate(
            6,
            (_) => const DailyRace(trackName: 'Loading'),
          );

          return Skeletonizer(
            enabled: true,
            child: _buildRaceSections(context, fakeItems),
          );
        }

        if (_error != null) {
          return _buildError(context, _error!);
        }

        return _buildRaceSections(context, service.dailyRaces);
      },
    );
  }

  Widget _buildRaceSections(BuildContext context, List<DailyRace> allItems) {
    final theme = Theme.of(context);

    // Only include items that have a track name set (this filters out any
    // placeholder or incomplete items).
    final items = allItems
        .where((r) => r.trackName != null && r.trackName!.isNotEmpty)
        .toList();

    final upcomingItems = items.where((r) => !r.isActive && !r.isPast).toList();
    final currentItems = items.where((r) => r.isActive).toList();
    final pastItems = items.where((r) => r.isPast).toList();

    var showUpcoming = widget.showUpcoming;
    var showCurrent = widget.showCurrent;
    var showPast = widget.showPast;

    if (widget.ifFutureExistsNotShowPast && upcomingItems.isNotEmpty) {
      showUpcoming = true;
      showCurrent = true;
      showPast = false;
    }

    final hasUpcoming = showUpcoming && upcomingItems.isNotEmpty;
    final hasCurrent = showCurrent && currentItems.isNotEmpty;
    final hasPast = showPast && pastItems.isNotEmpty;

    if (!hasUpcoming && !hasCurrent && !hasPast) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily races', style: theme.textTheme.titleMedium),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 8),
            Text('No daily races found.', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _RacesHeader(onRefresh: _load),
        const SizedBox(height: 16),

        // Upcoming section
        if (hasUpcoming) _UpcomingRacesSection(items: upcomingItems),

        // Current section
        if (hasCurrent) _CurrentRacesSection(items: currentItems),

        // Past section
        if (hasPast) _PastRacesSection(items: pastItems),

        // Powered by footer
        const SizedBox(height: 16),
        _PoweredByFooter(),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily races', style: theme.textTheme.titleMedium),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
    );
  }
}

// ============================================================================
// PRIVATE SECTION WIDGETS
// ============================================================================

class _RacesHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _RacesHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 1.0),
                ],
              ).createShader(bounds),
              child: Divider(color: Colors.white24, thickness: 1.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Skeleton.keep(
              child: Text('DAILY RACES', style: theme.textTheme.titleMedium),
            ),
          ),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 1.0),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ).createShader(bounds),
              child: Divider(color: Colors.white24, thickness: 1.0),
            ),
          ),
        ],
      ),
    );
  }
}

/// A week's races, laid out to fit the width rather than scrolling sideways.
///
/// Same shape as the Services grid on the home page: [LayoutBuilder] picks a
/// column count from the width and [GridView.count] sizes the tiles, with
/// scrolling left to the page. Column count is capped at three because a week
/// is three races — a fourth column would only add an empty slot.
class _RaceGrid extends StatelessWidget {
  const _RaceGrid({required this.items, required this.raceType});

  final List<DailyRace> items;
  final RaceType raceType;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(3).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // GT7 gives each card about 30% of the screen, which is what puts the
        // week in one row of three. Three columns start as soon as that still
        // leaves a readable card — below that the card would be narrower than
        // the game ever draws it, so drop to two and then to one.
        int crossAxisCount = 1;
        if (width > 500) crossAxisCount = 2;
        if (width > 700) crossAxisCount = 3;
        crossAxisCount = crossAxisCount.clamp(1, shown.length);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: kDailyRaceCardAspectRatio,
          children: [
            for (final race in shown)
              DailyRaceCard(race: race, raceType: raceType),
          ],
        );
      },
    );
  }
}

class _UpcomingRacesSection extends StatelessWidget {
  final List<DailyRace> items;

  const _UpcomingRacesSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RaceGrid(items: items, raceType: RaceType.upcoming),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CurrentRacesSection extends StatelessWidget {
  final List<DailyRace> items;

  const _CurrentRacesSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RaceGrid(items: items, raceType: RaceType.current),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PastRacesSection extends StatelessWidget {
  final List<DailyRace> items;

  const _PastRacesSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return _RaceGrid(items: items, raceType: RaceType.past);
  }
}

class _PoweredByFooter extends StatelessWidget {
  const _PoweredByFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Skeleton.keep(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8.0,
          children: [
            Text(
              'powered by',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8.0,
              children: [
                IconButton(
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://www.dg-edge.com/events/dailies',
                    );
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                  icon: Image.asset(
                    'assets/images/dg-edge-color-logotype-2.png',
                    width: 80,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final url = Uri.parse('https://gtsh-rank.com/daily/');
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                  icon: Image.asset('assets/images/gtsh-rank.png', width: 80),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
