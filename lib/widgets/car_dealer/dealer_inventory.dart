import 'dart:math' as math;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../l10n/ui_messages.dart';
import '../../repositories/car_repository.dart';
import '../../repositories/dealer_catalog_repository.dart';
import '../gt_loading_indicator.dart';
import '../window_navigation_safe_area.dart';
import 'car_dealer_error_panel.dart';
import 'dealer_car_dialog.dart';
import 'dealer_theme.dart';
import 'used/used_car_grid_item.dart';
import 'legendary/legendary_car_grid_item.dart';

class DealerInventory extends StatefulWidget {
  const DealerInventory({super.key, required this.legendary});
  final bool legendary;
  @override
  State<DealerInventory> createState() => _DealerInventoryState();
}

class _DealerInventoryState extends State<DealerInventory> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CarRepository>().fetchAllCars();
        context.read<DealerCatalogRepository>().load();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: dealerTheme(Theme.of(context), legendary: widget.legendary),
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
        final mobile =
            theme.platform == TargetPlatform.iOS ||
            theme.platform == TargetPlatform.android;
        final phone = mobile && MediaQuery.sizeOf(context).shortestSide < 600;
        final scale = math.max(
          1.0,
          MediaQuery.textScalerOf(context).scale(14) / 14,
        );
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Consumer2<CarRepository, DealerCatalogRepository>(
              builder: (context, repository, catalog, _) {
                return Column(
                  children: [
                    WindowNavigationSafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: widget.legendary
                                    ? (constraints.maxWidth < 600 ? 112 : 160)
                                    : (constraints.maxWidth < 600 ? 86 : 128),
                                height: 32,
                                child: SvgPicture.asset(
                                  widget.legendary
                                      ? 'assets/images/legend-hagerty.svg'
                                      : 'assets/images/ucd-auto.svg',
                                  width: widget.legendary
                                      ? (constraints.maxWidth < 600 ? 112 : 160)
                                      : constraints.maxWidth < 600
                                      ? 86
                                      : 128,
                                  height: 32,
                                  colorFilter: widget.legendary
                                      ? ColorFilter.mode(
                                          colors.onSurface,
                                          BlendMode.srcIn,
                                        )
                                      : null,
                                ),
                              ),
                              if (!widget.legendary) ...[
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: colors.outline,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    context.tr('USED CAR DEALERSHIP'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                              ] else
                                const Spacer(),
                              if (constraints.maxWidth >= 600)
                                OutlinedButton.icon(
                                  onPressed: () => AutoTabsRouter.of(
                                    context,
                                  ).setActiveIndex(1),
                                  icon: const Icon(
                                    Icons.outlined_flag,
                                    size: 16,
                                  ),
                                  label: Text(context.tr('Wishlist')),
                                )
                              else
                                IconButton(
                                  tooltip: context.tr('Wishlist'),
                                  onPressed: () => AutoTabsRouter.of(
                                    context,
                                  ).setActiveIndex(1),
                                  icon: const Icon(Icons.outlined_flag),
                                ),
                              if (!phone)
                                IconButton(
                                  key: const ValueKey('dealer-refresh'),
                                  tooltip: context.l10n.dealerRetry,
                                  onPressed: repository.isLoading
                                      ? null
                                      : () => repository.fetchAllCars(
                                          forceRefresh: true,
                                        ),
                                  icon: const Icon(Icons.refresh),
                                ),
                              IconButton(
                                key: ValueKey(
                                  widget.legendary
                                      ? 'dealer-legendary-close'
                                      : 'dealer-used-close',
                                ),
                                tooltip: context.l10n.dealerClose,
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (repository.dataDate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${context.l10n.dealerUpdated} ${repository.dataDate}${repository.isOffline ? ' · ${context.tr('Offline')}' : ''}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    if (catalog.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l10n.dealerCatalogError,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                            IconButton(
                              tooltip: context.l10n.dealerRetry,
                              onPressed: () => catalog.load(force: true),
                              icon: const Icon(Icons.refresh, size: 18),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () =>
                            repository.fetchAllCars(forceRefresh: true),
                        notificationPredicate: (notification) =>
                            phone && notification.depth == 0,
                        child:
                            repository.isLoading && repository.allCars.isEmpty
                            ? const Center(
                                child: GtLoadingIndicator(withBackdrop: true),
                              )
                            : repository.errorMessage != null &&
                                  repository.allCars.isEmpty
                            ? CarDealerErrorPanel(
                                title: context.tr('Error loading cars'),
                                message: repository.errorMessage!,
                                onRetry: () =>
                                    repository.fetchAllCars(forceRefresh: true),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final cars = widget.legendary
                                      ? repository.getLegendCars()
                                      : repository.getUsedCars();
                                  final width = constraints.maxWidth;
                                  final columns = widget.legendary
                                      ? (width >= 1200
                                            ? 5
                                            : width >= 700
                                            ? 3
                                            : 2)
                                      : (width >= 1100
                                            ? 3
                                            : width >= 700
                                            ? 2
                                            : 1);
                                  // GT7's desktop collection is a single row of tall
                                  // columns, navigated horizontally. Narrow layouts
                                  // keep the two-column vertical inventory.
                                  final horizontal =
                                      widget.legendary &&
                                      width >= 700 &&
                                      !phone;
                                  if (horizontal) {
                                    final tileWidth = math.max(
                                      190.0 * scale,
                                      width >= 1200
                                          ? width * .15625
                                          : (width - 80) / 3,
                                    );
                                    final tileHeight = math.max(
                                      448.0 * scale,
                                      tileWidth / .42,
                                    );
                                    return Scrollbar(
                                      controller: _scroll,
                                      thumbVisibility: true,
                                      child: ListView.separated(
                                        key: const PageStorageKey(
                                          'legend-inventory-horizontal',
                                        ),
                                        controller: _scroll,
                                        scrollDirection: Axis.horizontal,
                                        padding: EdgeInsets.fromLTRB(
                                          width >= 1200 ? width * .079 : 16,
                                          12,
                                          width >= 1200 ? width * .079 : 16,
                                          24,
                                        ),
                                        itemCount: cars.length,
                                        separatorBuilder: (_, _) => SizedBox(
                                          width: width >= 1200
                                              ? width * .0156
                                              : 12,
                                        ),
                                        itemBuilder: (context, index) => Align(
                                          alignment: Alignment.topCenter,
                                          child: SizedBox(
                                            width: tileWidth,
                                            height: math.min(
                                              tileHeight,
                                              math.max(
                                                0,
                                                constraints.maxHeight - 36,
                                              ),
                                            ),
                                            child: SingleChildScrollView(
                                              child: SizedBox(
                                                height: tileHeight,
                                                child: LegendaryCarCardItem(
                                                  car: cars[index],
                                                  onTap: () =>
                                                      DealerCarDialog.show(
                                                        context,
                                                        cars[index],
                                                        legendary: true,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return GridView.builder(
                                    key: PageStorageKey(
                                      widget.legendary
                                          ? 'legend-inventory'
                                          : 'used-inventory',
                                    ),
                                    controller: _scroll,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      16,
                                      mobile ? 128 : 24,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          mainAxisExtent:
                                              (widget.legendary
                                                  ? 448
                                                  : math.max(
                                                      140.0,
                                                      ((width -
                                                                  32 -
                                                                  12 *
                                                                      (columns -
                                                                          1)) /
                                                              columns) /
                                                          2.86,
                                                    )) *
                                              scale,
                                        ),
                                    itemCount: cars.length,
                                    itemBuilder: (context, index) {
                                      final car = cars[index];
                                      void open() => DealerCarDialog.show(
                                        context,
                                        car,
                                        legendary: widget.legendary,
                                      );
                                      return widget.legendary
                                          ? LegendaryCarCardItem(
                                              car: car,
                                              onTap: open,
                                            )
                                          : UsedCarCardItem(
                                              car: car,
                                              onTap: open,
                                            );
                                    },
                                  );
                                },
                              ),
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
