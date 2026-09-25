import 'package:flutter/material.dart';

import '../../models/gt_auto/gt_auto_catalog.dart';

/// The contents of one GT Auto counter, drawn the way the game draws it: the
/// service counter as rows carrying a price, the other two as square icon
/// tiles.
class GtAutoCounterView extends StatelessWidget {
  const GtAutoCounterView({super.key, required this.counter});

  final GtAutoCounter counter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      // The home shell floats its navigation bar over the page, so the last
      // rows need room to clear it.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Text(
          counter.tagline,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        for (final group in counter.groups) ...[
          if (group.title != null) _GroupHeader(title: group.title!),
          if (counter.layout == GtAutoLayout.list)
            for (final option in group.options) _OptionRow(option: option)
          else
            _OptionTiles(options: group.options),
          const SizedBox(height: 20),
        ],
        if (counter.id == 'maintenance') const _ConditionsStrip(),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A service row: icon, name and description on the left, price on the right.
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.option});

  final GtAutoOption option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = option.priceLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(option.icon, size: 22, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (price != null) ...[
            const SizedBox(width: 12),
            Text(
              price,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Square icon tiles, the shape GT7 uses along the bottom of the
/// customisation and driving gear counters.
class _OptionTiles extends StatelessWidget {
  const _OptionTiles({required this.options});

  final List<GtAutoOption> options;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // A square tile only works once three fit across. Narrower than that
        // the descriptions set the height, every tile stretches to the tallest
        // one, and the grid fills with dead space — so a phone gets the same
        // rows the service counter uses.
        if (width <= 480) {
          return Column(
            children: [for (final o in options) _OptionRow(option: o)],
          );
        }

        var columns = 3;
        if (width > 780) columns = 4;
        columns = columns.clamp(1, options.length);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [for (final o in options) _OptionTile(option: o)],
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option});

  final GtAutoOption option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(option.icon, size: 26, color: theme.colorScheme.secondary),
          const SizedBox(height: 10),
          Text(
            option.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              option.description,
              overflow: TextOverflow.fade,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                height: 1.3,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// GT7 prints dirt, oil and body rigidity along the bottom of the service
/// counter. Reading them needs the car's save data, which this app has no
/// access to, so each one names the service that restores it instead of
/// showing a level it cannot know.
class _ConditionsStrip extends StatelessWidget {
  const _ConditionsStrip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONDITIONS',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The game tracks these three per car. The app cannot read them '
            '— it has no access to your save.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final condition in kGtAutoConditions)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(condition.icon, size: 15, color: Colors.white60),
                      const SizedBox(width: 6),
                      Text(
                        condition.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '→ ${condition.restoredBy}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
