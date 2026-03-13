import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../repositories/sport_repository.dart';
import '../models/unified_daily_race.dart';
import 'unified_daily_races_display.dart';

/// Widget that displays upcoming daily races, if any, as reported by the
/// upstream sources.
class UpcomingDailyRacesDisplay extends StatefulWidget {
  const UpcomingDailyRacesDisplay({super.key});

  @override
  State<UpcomingDailyRacesDisplay> createState() =>
      _UpcomingDailyRacesDisplayState();
}

class _UpcomingDailyRacesDisplayState extends State<UpcomingDailyRacesDisplay> {
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
        .where((r) => !r.isActive)
        .toList();

    // Only show this widget if there is content to display
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
      return const SizedBox.shrink();
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
                  Text(
                    'Upcoming daily races',
                    style: theme.textTheme.titleMedium,
                  ),
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
                        Text('&', style: theme.textTheme.titleMedium),
                        Image.asset(
                          'assets/images/gtsh-rank.png',
                          width: 40,
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
              Text('Upcoming daily races', style: theme.textTheme.titleMedium),
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
