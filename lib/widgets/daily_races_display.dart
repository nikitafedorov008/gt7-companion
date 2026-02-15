import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/dg_edge_service.dart';
import '../models/daily_race.dart';

class DailyRacesDisplay extends StatefulWidget {
  const DailyRacesDisplay({super.key});

  @override
  State<DailyRacesDisplay> createState() => _DailyRacesDisplayState();
}

class _DailyRacesDisplayState extends State<DailyRacesDisplay> {
  @override
  void initState() {
    super.initState();
    // Loading is handled by the inner _DailyRacesContent widget (avoids duplicate fetches)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<DgEdgeService>(
      builder: (context, service, _) {
        // Do not block rendering of the content widget when the service reports
        // `isLoading` — the inner `_DailyRacesContent` manages its own loading
        // lifecycle and will call the service when mounted. Only show a service
        // error here if present.
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
                      'Daily races (DG‑Edge)',
                      style: theme.textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () =>
                          service.fetchDailiesPage(1, forceRefresh: true),
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

        // Delegate fetching/rendering to the stateful content widget
        return _DailyRacesContent();
      },
    );
  }
}

class _DailyRacesContent extends StatefulWidget {
  @override
  State<_DailyRacesContent> createState() => _DailyRacesContentState();
}

class _DailyRacesContentState extends State<_DailyRacesContent> {
  List<DailyRaceSummary> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer load to the next frame to avoid provider notifications during parent build
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = context.read<DgEdgeService>();
      final page = await svc.fetchDailiesPage(1);
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
                  'Daily races (DG‑Edge)',
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
              Text('Daily races (DG‑Edge)', style: theme.textTheme.titleMedium),
              Row(
                children: [
                  IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
                  TextButton(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://www.dg-edge.com/events/dailies',
                      );
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    child: const Text('Open website'),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            // Show only the first three cards as requested
            itemCount: _items.length.clamp(0, 3),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              // Only use the first three items from the fetched page
              final it = _items[index];
              return GestureDetector(
                onTap: () async {
                  // Fetch detail and show in a modal instead of opening external site
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (ctx) {
                      return FutureBuilder<DailyRaceDetail>(
                        future: context.read<DgEdgeService>().fetchDailyDetail(
                          it.url,
                        ),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return SizedBox(
                              height: 220,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snap.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        it.title,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Failed to load details: ${snap.error}'),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final detail = snap.data!;

                          String stripHtml(String? html) => (html ?? '')
                              .replaceAll(RegExp(r'<[^>]*>'), '')
                              .trim();

                          return DraggableScrollableSheet(
                            expand: false,
                            initialChildSize: 0.6,
                            minChildSize: 0.3,
                            maxChildSize: 0.95,
                            builder: (context, ctrl) => SingleChildScrollView(
                              controller: ctrl,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          detail.title,
                                          style: theme.textTheme.headlineSmall,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      // Prefer structured detail values, fall back to summary (`it`) when null
                                      if ((detail.className ?? it.className) !=
                                          null)
                                        Chip(
                                          label: Text(
                                            detail.className ?? it.className!,
                                          ),
                                        ),
                                      if ((detail.laps ?? it.laps) != null)
                                        Chip(
                                          label: Text(
                                            '${detail.laps ?? it.laps} laps',
                                          ),
                                        ),
                                      if ((detail.tyreCompound ??
                                              it.tyreCompound) !=
                                          null)
                                        Chip(
                                          label: Text(
                                            detail.tyreCompound ??
                                                it.tyreCompound!,
                                          ),
                                        ),
                                      if ((detail.refuels ?? it.refuels) !=
                                          null)
                                        Chip(
                                          label: Text(
                                            '${detail.refuels ?? it.refuels} refuels',
                                          ),
                                        ),
                                      if ((detail.reward ?? it.reward) != null)
                                        Chip(
                                          label: Text(
                                            detail.reward ?? it.reward!,
                                          ),
                                        ),
                                      if ((detail.metadata['Tyre'] ??
                                              it.tyreCode) !=
                                          null)
                                        Chip(
                                          label: Text(
                                            detail.metadata['Tyre'] ??
                                                it.tyreCode!,
                                          ),
                                        ),
                                      if ((detail.metadata['Tyres'] ??
                                              it.tyresAvailable) !=
                                          null)
                                        Chip(
                                          label: Text(
                                            'Tyres: ${detail.metadata['Tyres'] ?? it.tyresAvailable}',
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if ((detail.descriptionHtml ?? '').isNotEmpty)
                                    Text(
                                      stripHtml(detail.descriptionHtml),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  const SizedBox(height: 12),
                                  if (detail.players.isNotEmpty) ...[
                                    Text(
                                      'Players',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    for (final p in detail.players)
                                      ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.person,
                                          size: 20,
                                        ),
                                        title: Text(
                                          p,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                  ],
                                  const SizedBox(height: 12),
                                  if (detail.metadata.isNotEmpty) ...[
                                    Text(
                                      'Details',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    for (final e in detail.metadata.entries)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6.0,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 140,
                                              child: Text(
                                                '${e.key}:',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme.hintColor,
                                                    ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                e.value,
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                child: Stack(
                  children: [
                    // Background image (subtle)
                    if (it.trackBackgroundImage != null)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.08,
                          child: Image.network(
                            it.trackBackgroundImage!,
                            key: ValueKey('bg-${it.id}'),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    if (it.trackLogotype != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Image.network(it.trackLogotype!),
                        ),
                      ),
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(0.04),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(it.trackBackgroundImage!),
                          colorFilter: ColorFilter.mode(
                            Colors.black38,
                            BlendMode.srcATop,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Track image preferred, otherwise thumbnail
                          if (it.trackImage != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                it.trackImage!,
                                key: ValueKey('track-${it.id}'),
                                width: 64,
                                height: 64,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            )
                          else if (it.trackLogotype != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                it.trackLogotype!,
                                key: ValueKey('thumb-${it.id}'),
                                width: 64,
                                height: 64,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            )
                          else
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.flag),
                            ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  it.eventTime!,
                                  style: theme.textTheme.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  it.shortDescription ?? '',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),

                                // Compact one-line summary (carType · tyre · laps · pits · tyres)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Builder(
                                        builder: (context) {
                                          final parts = <String>[];
                                          if (it.carType != null)
                                            parts.add(it.carType!.code);
                                          if (it.tyre != null)
                                            parts.add(it.tyre!.code);
                                          if (it.laps != null)
                                            parts.add('${it.laps} laps');
                                          if (it.pitStops != null)
                                            parts.add('Pits: x${it.pitStops}');
                                          if (it.tyresAvailable != null)
                                            parts.add(
                                              'Tyres: x${it.tyresAvailable}',
                                            );
                                          final summary = parts.join(' • ');
                                          return Text(
                                            summary,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        },
                                      ),
                                    ),

                                    if (it.status != null)
                                      Container(
                                        key: ValueKey('status-${it.id}'),
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: it.isActive == true
                                              ? Colors.green.withOpacity(0.12)
                                              : Colors.grey.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          it.status!,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                  ],
                                ),

                                // Compact single-line summary (avoids vertical overflow on small cards)
                                Builder(
                                  builder: (context) {
                                    final parts = <String>[];
                                    if (it.pitStops != null)
                                      parts.add('Pits: x${it.pitStops}');
                                    if (it.tyresAvailable != null)
                                      parts.add('Tyres: x${it.tyresAvailable}');
                                    if (it.tyreCode != null)
                                      parts.add(it.tyreCode!);
                                    if (it.className != null)
                                      parts.add(it.className!);
                                    if (it.reward != null)
                                      parts.add(it.reward!);
                                    final summaryLine = parts.join(' • ');
                                    return Text(
                                      summaryLine,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
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
              Text('Daily races (DG‑Edge)', style: theme.textTheme.titleMedium),
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
