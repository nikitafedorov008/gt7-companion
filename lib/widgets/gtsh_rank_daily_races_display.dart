import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/gtsh_rank_service.dart';
import '../models/gtsh_race.dart';

/// Widget that mirrors [DailyRacesDisplay] but works with the
/// [GtshRankService]/[GtshRace] API instead of DG‑Edge.  The code is largely a
/// straight copy of the original file with the necessary types and text
/// adjusted.
class GtshRankDailyRacesDisplay extends StatefulWidget {
  const GtshRankDailyRacesDisplay({super.key});

  @override
  State<GtshRankDailyRacesDisplay> createState() =>
      _GtshRankDailyRacesDisplayState();
}

class _GtshRankDailyRacesDisplayState
    extends State<GtshRankDailyRacesDisplay> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<GtshRankService>(
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
                      'Daily races (GTSh‑rank)',
                      style: theme.textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () =>
                          service.fetchRunningCards(forceRefresh: true),
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

        return _GtshRankDailyRacesContent();
      },
    );
  }
}

class _GtshRankDailyRacesContent extends StatefulWidget {
  @override
  State<_GtshRankDailyRacesContent> createState() =>
      _GtshRankDailyRacesContentState();
}

class _GtshRankDailyRacesContentState
    extends State<_GtshRankDailyRacesContent> {
  List<GtshRace> _items = [];
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
      final svc = context.read<GtshRankService>();
      final page = await svc.fetchRunningCards();
      if (!mounted) return;
      setState(() {
        _items = page;
      });
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

    if (_items.isEmpty) {
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
                  'Daily races (GTSh‑rank)',
                  style: theme.textTheme.titleMedium,
                ),
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
                      final url = Uri.parse('https://gtsh-rank.com/daily/');
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    child: const Text('GTSh‑rank'),
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
            itemCount: _items.length.clamp(0, 3),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final it = _items[index];
              return GtshRaceCard(race: it);
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
              Text('Daily races (GTSh‑rank)', style: theme.textTheme.titleMedium),
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

class GtshRaceCard extends StatelessWidget {
  final GtshRace race;
  const GtshRaceCard({super.key, required this.race});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (race.label.isNotEmpty)
            Text('Card ${race.label}', style: theme.textTheme.titleSmall),
          Text(race.trackName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Tyre: ${race.tyreCode}', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
