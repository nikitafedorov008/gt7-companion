import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/ui_messages.dart';
import '../../repositories/car_repository.dart';
import '../../repositories/dealer_catalog_repository.dart';
import '../../repositories/wishlist_repository.dart';
import '../gt_loading_indicator.dart';
import '../window_navigation_safe_area.dart';
import 'dealer_car_dialog.dart';
import 'dealer_theme.dart';
import 'used/used_car_grid_item.dart';

class DealerWishlist extends StatefulWidget {
  const DealerWishlist({super.key});
  @override
  State<DealerWishlist> createState() => _DealerWishlistState();
}

class _DealerWishlistState extends State<DealerWishlist> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WishlistRepository>().load();
        context.read<DealerCatalogRepository>().load();
        context.read<CarRepository>().fetchAllCars();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: dealerTheme(Theme.of(context), legendary: false),
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child:
                Consumer3<
                  WishlistRepository,
                  DealerCatalogRepository,
                  CarRepository
                >(
                  builder: (context, wishlist, catalog, inventory, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WindowNavigationSafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.outlined_flag),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    context.tr('Wishlist'),
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                ),
                                Text(
                                  '${wishlist.ids.length}',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            context.l10n.dealerWishlistLocal,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        if (wishlist.error != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    context.l10n.dealerWishlistError,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => wishlist.load(force: true),
                                  child: Text(context.l10n.dealerRetry),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: !wishlist.isLoaded && wishlist.error == null
                              ? const Center(
                                  child: GtLoadingIndicator(withBackdrop: true),
                                )
                              : wishlist.ids.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          context.l10n.dealerWishlistEmpty,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          context.l10n.dealerWishlistHint,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  key: const PageStorageKey(
                                    'dealer-wishlist-list',
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    136,
                                  ),
                                  itemCount: wishlist.ids.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final id = wishlist.ids[index],
                                        car = catalog.savedCar(
                                          wishlist.ids[index],
                                          inventory.allCars,
                                        );
                                    final scale = math.max(
                                      1.0,
                                      MediaQuery.textScalerOf(
                                            context,
                                          ).scale(14) /
                                          14,
                                    );
                                    final legend =
                                        car?.source?.contains('legend') ??
                                        false;
                                    return Row(
                                      key: ValueKey('wishlist-row-$id'),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: car == null
                                              ? Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Text(
                                                    '${context.l10n.dealerUnknownCar} · $id',
                                                  ),
                                                )
                                              : SizedBox(
                                                  height: 200 * scale,
                                                  child: UsedCarCardItem(
                                                    car: car,
                                                    onTap: () =>
                                                        DealerCarDialog.show(
                                                          context,
                                                          car,
                                                          legendary: legend,
                                                        ),
                                                  ),
                                                ),
                                        ),
                                        IconButton(
                                          key: ValueKey('wishlist-remove-$id'),
                                          tooltip: context.l10n.dealerRemove,
                                          onPressed: wishlist.isSaving
                                              ? null
                                              : () => wishlist.toggle(id),
                                          icon: const Icon(Icons.close),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
          ),
        );
      },
    ),
  );
}
