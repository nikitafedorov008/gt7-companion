import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../l10n/ui_messages.dart';
import '../../../models/car_dealer/car.dart';
import '../../../repositories/dealer_catalog_repository.dart';
import '../card_artwork.dart';
import '../dealer_card_parts.dart';

/// Open collection columns measured against the GT7 Hagerty reference.
class LegendaryCarCardItem extends StatelessWidget {
  const LegendaryCarCardItem({super.key, required this.car, this.onTap});
  final Car car;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    return Consumer<DealerCatalogRepository>(
      builder: (context, catalog, _) {
        final details = catalog.details(car, context.l10n.localeName);
        return Material(
          color: colors.surface.withValues(alpha: 0),
          child: InkWell(
            key: ValueKey('dealer-legendary-car-${details.id}'),
            onTap: onTap,
            child: CustomPaint(
              painter: _CollectionCorners(
                colors.onSurface.withValues(alpha: .2),
              ),
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final h = bounds.maxHeight;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: bounds.maxWidth * .1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: h * .055,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: SvgPicture.asset(
                              'assets/images/legend_hagerty_icon.svg',
                              width: 23,
                              height: 23,
                            ),
                          ),
                        ),
                        SizedBox(height: h * .055),
                        SizedBox(
                          height: h * .095,
                          child: details.logoUrl != null
                              ? CardArtwork(
                                  url: details.logoUrl!,
                                  fit: BoxFit.contain,
                                  cacheWidth: 256,
                                )
                              : Center(
                                  child: Text(
                                    details.manufacturer,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                        SizedBox(height: h * .07),
                        SizedBox(
                          height: h * .145,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                details.manufacturer,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                details.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontSize: 14,
                                  height: 1.12,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: .7,
                          color: colors.primary.withValues(alpha: .65),
                        ),
                        SizedBox(
                          height: h * .08,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              details.year,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 30,
                                height: 1.2,
                                letterSpacing: -.8,
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h * .025),
                        SizedBox(
                          height: h * .19,
                          child: Opacity(
                            opacity: car.isSoldOut ? .4 : 1,
                            child: CardArtwork(
                              key: ValueKey(
                                'dealer-legendary-image-${details.id}',
                              ),
                              url: details.thumbnailUrl,
                              fit: BoxFit.contain,
                              cacheWidth: 640,
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: .7,
                          color: colors.primary.withValues(alpha: .65),
                        ),
                        const SizedBox(height: 10),
                        DealerPrice(details: details),
                        const SizedBox(height: 4),
                        Tooltip(
                          message: context.l10n.dealerMileage,
                          child: Text(
                            '—',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DealerStockLabel(details: details, onlySpecial: true),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CollectionCorners extends CustomPainter {
  const _CollectionCorners(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    const length = 9.0;
    for (final corner in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final dx = corner.dx == 0 ? length : -length;
      final dy = corner.dy == 0 ? length : -length;
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx + dx, corner.dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx, corner.dy + dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CollectionCorners oldDelegate) =>
      oldDelegate.color != color;
}
