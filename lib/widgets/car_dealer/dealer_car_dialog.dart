// START_MODULE_CONTRACT
// PURPOSE: Present the GT7 dealership vehicle window inside the shared shell.
// SCOPE: Local image, exact specs/history, wishlist and explicit price-chart action.
// DEPENDS: M-DEALER-CATALOG, M-REPO-WISHLIST
// LINKS: M-WIDGET-CAR-DEALER, V-M-WIDGET-CAR-DEALER
// END_MODULE_CONTRACT
// START_MODULE_MAP
// DealerCarDialog - responsive light vehicle dialog or dark Hagerty showroom.
// END_MODULE_MAP
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../l10n/ui_messages.dart';
import '../../models/car_dealer/car.dart';
import '../../models/car_dealer/dealer_car_details.dart';
import '../../repositories/dealer_catalog_repository.dart';
import '../../repositories/wishlist_repository.dart';
import '../window_navigation_safe_area.dart';
import 'card_artwork.dart';
import 'dealer_card_parts.dart';
import 'dealer_theme.dart';
import 'dealer_price_history_dialog.dart';

class DealerCarDialog extends StatefulWidget {
  const DealerCarDialog({super.key, required this.car, this.legendary = false});
  final Car car;
  final bool legendary;

  static Future<void> show(
    BuildContext context,
    Car car, {
    bool legendary = false,
  }) {
    final theme = dealerTheme(Theme.of(context), legendary: legendary);
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      barrierLabel: context.l10n.dealerClose,
      barrierColor: theme.colorScheme.scrim.withValues(alpha: .38),
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      pageBuilder: (context, _, _) => Theme(
        data: theme,
        child: DealerCarDialog(car: car, legendary: legendary),
      ),
      transitionBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<DealerCarDialog> createState() => _DealerCarDialogState();
}

class _DealerCarDialogState extends State<DealerCarDialog> {
  bool _history = false;
  final _historyKey = GlobalKey();
  void _toggleHistory() {
    setState(() => _history = !_history);
    if (!_history) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _historyKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    final mobile =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.android;
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, mobile ? 112 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1120,
                    maxHeight: 850,
                  ),
                  child: Material(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(3),
                    clipBehavior: Clip.antiAlias,
                    child: Consumer<DealerCatalogRepository>(
                      builder: (context, catalog, _) {
                        final details = catalog.details(
                          widget.car,
                          context.l10n.localeName,
                        );
                        return Semantics(
                          namesRoute: true,
                          label: details.name,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WindowNavigationSafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                    right: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      if (widget.legendary)
                                        SvgPicture.asset(
                                          'assets/images/legend-hagerty.svg',
                                          width: 160,
                                          height: 24,
                                          colorFilter: ColorFilter.mode(
                                            colors.onSurface,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      const Spacer(),
                                      IconButton(
                                        key: const ValueKey(
                                          'dealer-dialog-close',
                                        ),
                                        tooltip: context.l10n.dealerClose,
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Flexible(
                                child: SingleChildScrollView(
                                  key: const ValueKey('dealer-dialog-scroll'),
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _Overview(
                                        details: details,
                                        legendary: widget.legendary,
                                      ),
                                      const SizedBox(height: 20),
                                      _Specifications(details: details),
                                      if (_history)
                                        Padding(
                                          key: _historyKey,
                                          padding: const EdgeInsets.only(
                                            top: 24,
                                          ),
                                          child: SelectableText(
                                            details.history.isEmpty
                                                ? context.l10n.dealerNoHistory
                                                : details.history,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(height: 1.6),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 12,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        OutlinedButton(
                                          key: const ValueKey(
                                            'dealer-learn-more',
                                          ),
                                          onPressed: _toggleHistory,
                                          child: Text(
                                            _history
                                                ? context.l10n.dealerLess
                                                : context.l10n.dealerMore,
                                          ),
                                        ),
                                        Consumer<WishlistRepository>(
                                          builder: (context, wishlist, _) =>
                                              FilledButton.icon(
                                                key: const ValueKey(
                                                  'dealer-wishlist-toggle',
                                                ),
                                                onPressed:
                                                    !wishlist.isLoaded ||
                                                        wishlist.isSaving
                                                    ? null
                                                    : () async {
                                                        await wishlist.toggle(
                                                          details.id,
                                                        );
                                                      },
                                                icon: Icon(
                                                  wishlist.contains(details.id)
                                                      ? Icons.flag
                                                      : Icons.outlined_flag,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  wishlist.contains(details.id)
                                                      ? context.l10n.dealerSaved
                                                      : context.l10n.dealerSave,
                                                ),
                                              ),
                                        ),
                                        TextButton(
                                          key: const ValueKey(
                                            'dealer-price-history',
                                          ),
                                          onPressed: () =>
                                              DealerPriceHistoryDialog.show(
                                                context,
                                                uri: details.priceHistoryUri,
                                                carName: details.name,
                                              ),
                                          child: Text(
                                            context.l10n.dealerPriceHistory,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Consumer<WishlistRepository>(
                                      builder: (context, wishlist, _) =>
                                          wishlist.error == null
                                          ? const SizedBox.shrink()
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Text(
                                                context
                                                    .l10n
                                                    .dealerWishlistError,
                                                style: theme
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: colors.error,
                                                    ),
                                              ),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.details, required this.legendary});
  final DealerCarDetails details;
  final bool legendary;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 680;
      final photo = AspectRatio(
        aspectRatio: legendary ? 1.65 : 1.5,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: CardArtwork(
            url: details.car.carImageUrl,
            fallbackUrl: details.thumbnailUrl,
            fit: BoxFit.contain,
            cacheWidth: 1200,
            thumbnailOverlay: legendary ? null : const UsedDealerWatermark(),
            thumbnailBackground: legendary
                ? null
                : dealerThumbnailBackground(details.car.region),
          ),
        ),
      );
      final identity = _Identity(
        details: details,
        minHeight: narrow
            ? 0
            : (constraints.maxWidth - 24) *
                  (legendary ? .6 : .5) /
                  (legendary ? 1.65 : 1.5),
      );
      return narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [photo, const SizedBox(height: 16), identity],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: legendary ? 6 : 5, child: photo),
                const SizedBox(width: 24),
                Expanded(flex: legendary ? 4 : 5, child: identity),
              ],
            );
    },
  );
}

class _Identity extends StatelessWidget {
  const _Identity({required this.details, required this.minHeight});
  final DealerCarDetails details;
  final double minHeight;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.manufacturer.toUpperCase(),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              Text(
                details.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              DealerPoints(details: details),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.dealerMileage,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Text('—'),
                ],
              ),
              const SizedBox(height: 12),
              DealerStockLabel(details: details),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: DealerPrice(details: details, large: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Specifications extends StatelessWidget {
  const _Specifications({required this.details});
  final DealerCarDetails details;
  static const labels = [
    'Displacement',
    'Drivetrain',
    'Maximum power',
    'Maximum torque',
    'Length',
    'Width',
    'Height',
    'Weight',
    'Aspiration',
  ];
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
      final columns = constraints.maxWidth >= 800
          ? 3
          : constraints.maxWidth >= 290
          ? 2
          : 1;
      final width = (constraints.maxWidth - 32 - (columns - 1) * 16) / columns;
      return ColoredBox(
        color: colors.surfaceContainerHighest.withValues(alpha: .65),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 18,
            children: [
              for (final label in labels)
                SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(label),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DealerCarDetails.value(details.specifications[label]),
                        style: theme.textTheme.bodyMedium,
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
