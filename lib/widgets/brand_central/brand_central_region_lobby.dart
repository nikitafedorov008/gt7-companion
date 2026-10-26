import 'package:gt7_companion/l10n/ui_messages.dart';
import 'package:flutter/material.dart';
import '../../repositories/brand_central_repository.dart';

/// GT7 entry sequence: choose a geographic region, then a manufacturer.
class BrandCentralRegionLobby extends StatelessWidget {
  const BrandCentralRegionLobby({
    super.key,
    required this.repository,
    required this.onChooseRegion,
  });
  final BrandCentralRepository repository;
  final ValueChanged<String> onChooseRegion;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final portrait =
            constraints.maxHeight > constraints.maxWidth ||
            constraints.maxWidth < 600;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        return SingleChildScrollView(
          key: const ValueKey('brand-region-lobby'),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                portrait ? 24 : 48,
                24,
                portrait ? 24 : 48,
                120,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: portrait
                        ? 16
                        : (constraints.maxHeight * .17).clamp(20.0, 180.0),
                  ),
                  Text(
                    context.tr('BRAND CENTRAL'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      letterSpacing: portrait ? 5 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: portrait ? 130 : 48),
                  Text(
                    context.tr('Select a region'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: portrait
                        ? Column(
                            children: [
                              for (final entry in _regions.indexed) ...[
                                if (entry.$1 != 0) const SizedBox(height: 12),
                                _RegionButton(
                                  region: entry.$2,
                                  onTap: () => onChooseRegion(entry.$2.$2),
                                  height: 56 + 12 * (scale - 1),
                                ),
                              ],
                            ],
                          )
                        : Row(
                            children: [
                              for (final entry in _regions.indexed) ...[
                                if (entry.$1 != 0) const SizedBox(width: 16),
                                Expanded(
                                  child: _RegionButton(
                                    region: entry.$2,
                                    onTap: () => onChooseRegion(entry.$2.$2),
                                    height: 56 + 12 * (scale - 1),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  SizedBox(height: portrait ? 32 : 80),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        key: const ValueKey('brand-all-cars'),
                        onPressed: () => repository.openBrand(null),
                        icon: const Icon(
                          Icons.directions_car_outlined,
                          size: 20,
                        ),
                        label: Text(context.tr('All GT7 cars')),
                      ),
                      TextButton.icon(
                        key: const ValueKey('brand-all-marques'),
                        onPressed: () => onChooseRegion('All regions'),
                        icon: const Icon(Icons.public, size: 20),
                        label: Text(context.tr('All marques')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      '${repository.data!.editions[repository.language]!.length} cars · ${repository.data!.brands.length} marques',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: .8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static const _regions = [
    ('AMERICA', 'North America', 'america'),
    ('EUROPE', 'Europe', 'europe'),
    ('ASIA-PACIFIC', 'Asia-Pacific', 'asia-pacific'),
  ];
}

class _RegionButton extends StatelessWidget {
  const _RegionButton({
    required this.region,
    required this.onTap,
    required this.height,
  });
  final (String, String, String) region;
  final VoidCallback onTap;
  final double height;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: .26),
        shape: StadiumBorder(
          side: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: .75),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('brand-region-${region.$3}'),
          onTap: onTap,
          hoverColor: theme.colorScheme.onSurface.withValues(alpha: .18),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                context.tr(region.$1),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
