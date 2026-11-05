import 'package:gt7_companion/l10n/ui_messages.dart';
// START_MODULE_CONTRACT
// PURPOSE: Show the four home services in a width-driven, content-height layout.
// SCOPE: Service cards and their navigation callbacks.
// DEPENDS: none
// LINKS: M-WIDGET-SERVICE-MENU, V-M-WIDGET-SERVICE-MENU
// END_MODULE_CONTRACT
// START_MODULE_MAP
// ServiceMenu - responsive service cards with stable artwork proportions.
// END_MODULE_MAP
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ServiceMenu extends StatelessWidget {
  const ServiceMenu({
    super.key,
    required this.onBrandCentral,
    required this.onUsed,
    required this.onLegendary,
    required this.onGTAuto,
  });

  final VoidCallback onBrandCentral;
  final VoidCallback onUsed;
  final VoidCallback onLegendary;
  final VoidCallback onGTAuto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 344
            ? 2
            : 1;
        final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
        final logoHeight = (width * .23).clamp(40.0, 68.0);
        return Wrap(
          spacing: 12,
          runSpacing: 16,
          children: [
            _ServiceCard(
              width: width,
              id: 'brand-central',
              label: 'Brand Central',
              onTap: onBrandCentral,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.surface,
                ],
              ),
              child: FittedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('BRAND'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 5,
                      ),
                    ),
                    Text(
                      context.tr('CENTRAL'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ServiceCard(
              width: width,
              id: 'used',
              label: 'Used car dealer',
              onTap: onUsed,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.primaryContainer,
                ],
              ),
              child: Image.asset(
                'assets/images/auto_plus.webp',
                height: logoHeight,
                fit: BoxFit.contain,
              ),
            ),
            _ServiceCard(
              width: width,
              id: 'legendary',
              label: 'Legendary car dealer',
              onTap: onLegendary,
              gradient: const LinearGradient(
                colors: [Color(0xFF070707), Color(0xFF141414)],
              ),
              child: SizedBox(
                height: logoHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/legend_hagerty_icon.svg',
                      height: logoHeight * .48,
                    ),
                    SizedBox(height: logoHeight * .12),
                    SvgPicture.asset(
                      'assets/images/hagerty_title.svg',
                      height: logoHeight * .24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ServiceCard(
              width: width,
              id: 'gtauto',
              label: 'GT Auto',
              onTap: onGTAuto,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF1D6), Color(0xFFFFB347)],
              ),
              child: Image.asset(
                'assets/images/gt_auto.webp',
                height: logoHeight,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.width,
    required this.id,
    required this.label,
    required this.onTap,
    required this.gradient,
    required this.child,
  });
  final double width;
  final String id;
  final String label;
  final VoidCallback onTap;
  final Gradient gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Semantics(
      button: true,
      label: context.tr(label),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('service-$id'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Ink(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: .10),
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 2.7,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(child: child),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                child: Text(
                  context.tr(label),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
