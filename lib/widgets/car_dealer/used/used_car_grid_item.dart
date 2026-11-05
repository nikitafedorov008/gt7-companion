import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/ui_messages.dart';
import '../../../models/car_dealer/car.dart';
import '../../../repositories/dealer_catalog_repository.dart';
import '../card_artwork.dart';
import '../dealer_card_parts.dart';
import '../dealer_theme.dart';

class UsedCarCardItem extends StatelessWidget {
  const UsedCarCardItem({super.key, required this.car, this.onTap});
  final Car car;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    return Consumer<DealerCatalogRepository>(
      builder: (context, catalog, _) {
        final details = catalog.details(car, context.l10n.localeName);
        return Material(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(2),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('dealer-used-car-${details.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CardArtwork(
                          url: car.carImageUrl,
                          fallbackUrl: details.thumbnailUrl,
                          fit: BoxFit.contain,
                          cacheWidth: 640,
                          thumbnailOverlay: const UsedDealerWatermark(),
                          thumbnailBackground: dealerThumbnailBackground(
                            car.region,
                          ),
                          imageBuilder: (context, image, isThumbnail) => Stack(
                            fit: StackFit.expand,
                            children: [
                              ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  colors.scrim.withValues(
                                    alpha: car.isSoldOut ? .6 : 0,
                                  ),
                                  BlendMode.srcATop,
                                ),
                                child: image,
                              ),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: isThumbnail ? 8 : 20,
                                child: const _Mileage(),
                              ),
                            ],
                          ),
                        ),
                        if (car.isSoldOut)
                          Center(
                            child: Transform.rotate(
                              angle: -.2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colors.error,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'SOLD OUT',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: colors.error,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (car.flagUrl.isNotEmpty) ...[
                              CardArtwork(
                                url: car.flagUrl,
                                width: 16,
                                height: 11,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Expanded(
                              child: Text(
                                details.manufacturer.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          details.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 14,
                            height: 1.05,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: DealerPoints(details: details),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${details.drive} / ${details.aspiration}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          height:
                              24 *
                              (MediaQuery.textScalerOf(context).scale(14) / 14)
                                  .clamp(1.0, double.infinity),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: DealerStockLabel(
                              details: details,
                              onlySpecial: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Align(
                          alignment: Alignment.centerRight,
                          child: DealerPrice(details: details),
                        ),
                      ],
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
}

class _Mileage extends StatelessWidget {
  const _Mileage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = [
      Shadow(
        color: theme.colorScheme.scrim.withValues(alpha: .7),
        blurRadius: 3,
      ),
    ];
    return Semantics(
      label: '${context.l10n.dealerMileage} —',
      child: Row(
        children: [
          Icon(
            Icons.speed_outlined,
            size: 19,
            color: const Color(0xFFFFFFFF),
            shadows: shadows,
          ),
          const SizedBox(width: 5),
          Text(
            '—',
            style: theme.textTheme.labelMedium?.copyWith(
              color: const Color(0xFFFFFFFF),
              shadows: shadows,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
