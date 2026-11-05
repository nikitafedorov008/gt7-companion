import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../l10n/ui_messages.dart';
import '../../models/car_dealer/dealer_car_details.dart';

class DealerPoints extends StatelessWidget {
  const DealerPoints({super.key, required this.details});
  final DealerCarDetails details;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.onSurface),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          'PP ${details.pp}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}

class DealerStockLabel extends StatelessWidget {
  const DealerStockLabel({
    super.key,
    required this.details,
    this.onlySpecial = false,
  });
  final DealerCarDetails details;
  final bool onlySpecial;
  @override
  Widget build(BuildContext context) {
    final car = details.car;
    final text = !details.hasStock
        ? context.l10n.dealerStockUnknown
        : car.isSoldOut
        ? context.l10n.dealerSoldOut
        : car.isLimitedStock
        ? context.l10n.dealerLimited
        : car.isNew
        ? context.l10n.dealerNewArrival
        : context.l10n.dealerInStock;
    if (onlySpecial && !car.isSoldOut && !car.isLimitedStock && !car.isNew) {
      return const SizedBox.shrink();
    }
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: car.isSoldOut || car.isLimitedStock
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (car.isLimitedStock) ...[
          Icon(Icons.warning_amber_rounded, size: 14, color: style?.color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class DealerPrice extends StatelessWidget {
  const DealerPrice({super.key, required this.details, this.large = false});
  final DealerCarDetails details;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final legend = theme.brightness == Brightness.dark;
    final style =
        (large ? theme.textTheme.headlineMedium : theme.textTheme.titleLarge)
            ?.copyWith(
              fontSize: large ? 28 : (legend ? 18 : 20),
              fontWeight: legend ? FontWeight.w400 : FontWeight.w700,
              letterSpacing: -.4,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          style: style,
          children: details.hasPrice
              ? [
                  TextSpan(
                    text: 'Cr. ',
                    style: style?.copyWith(
                      fontSize: (style.fontSize ?? 22) * .58,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextSpan(
                    text: details.car.displayPrice.replaceFirst('Cr. ', ''),
                  ),
                ]
              : [const TextSpan(text: '—')],
        ),
        maxLines: 1,
      ),
    );
  }
}

/// Mirrors the baked-in watermark on Used dealership photographs.
class UsedDealerWatermark extends StatelessWidget {
  const UsedDealerWatermark({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: FractionallySizedBox(
      widthFactor: .32,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AspectRatio(
          aspectRatio: 5,
          child: SvgPicture.asset(
            'assets/images/ucd-auto.svg',
            colorFilter: const ColorFilter.mode(
              Color(0xFFFFFFFF),
              BlendMode.srcIn,
            ),
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}
