import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

import '../../models/gt_auto/gt_auto_catalog.dart';
import 'gt_auto_counter_view.dart';

/// GT Auto, shaped after the shop in the game: a forecourt with three
/// counters, and each counter's contents behind it.
///
/// The counters are switched in place rather than pushed as routes — GT Auto
/// is one place you move around in, and keeping it to a single route avoids
/// dragging auto_route codegen into a screen with no data of its own.
@RoutePage()
class GTAutoDisplay extends StatefulWidget {
  const GTAutoDisplay({super.key});

  @override
  State<GTAutoDisplay> createState() => _GTAutoDisplayState();
}

class _GTAutoDisplayState extends State<GTAutoDisplay> {
  GtAutoCounter? _counter;

  @override
  Widget build(BuildContext context) {
    final counter = _counter;

    return PopScope(
      // At a counter, back steps out to the forecourt before it leaves the
      // screen — the same way the game's back button behaves.
      canPop: counter == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && counter != null) setState(() => _counter = null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(counter?.name ?? 'GT Auto'),
          leading: counter == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _counter = null),
                  tooltip: 'Back to GT Auto',
                ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _GtAutoSign(),
              ),
              Expanded(
                child: counter == null
                    ? _Forecourt(
                        onSelect: (c) => setState(() => _counter = c),
                      )
                    : GtAutoCounterView(counter: counter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The yellow GT AUTO plate the game puts above every screen in the shop.
class _GtAutoSign extends StatelessWidget {
  const _GtAutoSign();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'GT AUTO',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Maintenance and custom parts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

/// The three counters, as the large tiles the game floats in front of the
/// building.
class _Forecourt extends StatelessWidget {
  const _Forecourt({required this.onSelect});

  final ValueChanged<GtAutoCounter> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 700;

        final tiles = [
          for (final counter in kGtAutoCounters)
            _CounterTile(counter: counter, onTap: () => onSelect(counter)),
        ];

        return SingleChildScrollView(
          // Clears the navigation bar the home shell floats over the page.
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final tile in tiles)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: tile,
                        ),
                      ),
                  ],
                )
              : Column(
                  children: [
                    for (final tile in tiles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: tile,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({required this.counter, required this.onTap});

  final GtAutoCounter counter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  counter.icon,
                  size: 28,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                counter.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                counter.tagline,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${counter.allOptions.length} options',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
