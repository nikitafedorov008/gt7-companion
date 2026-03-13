import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../repositories/sport_repository.dart';
import '../models/unified_daily_race.dart';
import '../models/daily_race.dart';

/// Widget that combines results from both DG‑Edge and GTSh‑rank by relying on
/// [SportRepository].  The visual layout is essentially a straight copy of
/// [DailyRacesDisplay], which previously only showed DG‑Edge data.
class UnifiedDailyRacesDisplay extends StatefulWidget {
  const UnifiedDailyRacesDisplay({super.key});

  @override
  State<UnifiedDailyRacesDisplay> createState() =>
      _UnifiedDailyRacesDisplayState();
}

class _UnifiedDailyRacesDisplayState extends State<UnifiedDailyRacesDisplay> {
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
              color: theme.colorScheme.surface.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily races (combined)',
                      style: theme.textTheme.titleMedium,
                    ),
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

        return _UnifiedDailyRacesContent();
      },
    );
  }
}

class _UnifiedDailyRacesContent extends StatefulWidget {
  @override
  State<_UnifiedDailyRacesContent> createState() =>
      _UnifiedDailyRacesContentState();
}

class _UnifiedDailyRacesContentState extends State<_UnifiedDailyRacesContent> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = context.read<SportRepository>();
      await svc.fetchDailyRaces();
      // the consumer in build will react when the repo updates
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<SportRepository>();
    final items = repo.dailyRaces
        .where((r) => r.trackName != null && r.trackName!.isNotEmpty)
        .toList();

    if (_loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _buildError(context, _error!);
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.02),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Daily races', style: theme.textTheme.titleMedium),
                  IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MaterialButton(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://www.dg-edge.com/events/dailies',
                      );
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8.0,
                      children: [
                        Text('powered by', style: theme.textTheme.titleMedium),
                        Image.asset(
                          'assets/images/dg-edge-color-logotype.png',
                          width: 80,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            // Show only the first three cards as requested
            itemCount: items.length.clamp(0, 3),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final it = items[index];
              return UnifiedDailyRaceCard(race: it);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily races (combined)',
                style: theme.textTheme.titleMedium,
              ),
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

class UnifiedDailyRaceCard extends StatelessWidget {
  final UnifiedDailyRace race;
  const UnifiedDailyRaceCard({super.key, required this.race});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final it = race; // UnifiedDailyRace

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.0),
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    image: it.trackBackgroundImage != null
                        ? DecorationImage(
                            image: NetworkImage(it.trackBackgroundImage!),
                            colorFilter: ColorFilter.mode(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// reuse CarCategory and TyreCategory widgets from daily_races_display.dart
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
      return SizedBox.shrink();
    }
  }
}
