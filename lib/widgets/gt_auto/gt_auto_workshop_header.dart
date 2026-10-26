import 'package:gt7_companion/l10n/ui_messages.dart';
import 'package:flutter/material.dart';

import '../../repositories/car_catalog.dart';

class GtAutoWorkshopHeader extends StatelessWidget {
  const GtAutoWorkshopHeader({
    super.key,
    required this.car,
    required this.catalog,
    required this.onChoose,
  });
  final CarInfo car;
  final CarCatalog catalog;
  final VoidCallback onChoose;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final id = int.tryParse(car.id.replaceFirst('car', ''));
    final url = id == null ? null : catalog.photoUrl(id);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final height =
            (constraints.maxWidth * .55).clamp(260.0, 340.0) *
            textScale.clamp(1.0, 1.7);
        return Material(
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          color: colors.surfaceContainerHighest,
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Center(
                            child: Icon(
                              Icons.directions_car_outlined,
                              size: 72,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(
                        Icons.directions_car_outlined,
                        size: 72,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Icon(
                      Icons.directions_car_outlined,
                      size: 72,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, .38, 1],
                      colors: [
                        colors.scrim.withValues(alpha: .08),
                        colors.scrim.withValues(alpha: .12),
                        colors.scrim.withValues(alpha: .97),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: FilledButton.tonalIcon(
                    key: const ValueKey('gt-auto-choose-car'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.surface.withValues(alpha: .95),
                      foregroundColor: colors.onSurface,
                    ),
                    onPressed: onChoose,
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(context.tr('Change car')),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('SELECTED CAR / STOCK'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(car.name),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          if (car.performancePoints.isNotEmpty)
                            Text(
                              context.tr('PP ${car.performancePoints}'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.secondary,
                              ),
                            ),
                          if (car.power.isNotEmpty)
                            Text(
                              context.tr(car.power),
                              style: theme.textTheme.bodySmall,
                            ),
                          if (car.driveTrain.isNotEmpty)
                            Text(
                              context.tr(car.driveTrain),
                              style: theme.textTheme.bodySmall,
                            ),
                          if (car.aspiration.isNotEmpty)
                            Text(
                              context.tr(car.aspiration),
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
