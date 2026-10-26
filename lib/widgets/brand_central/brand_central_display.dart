import 'package:gt7_companion/widgets/window_navigation_safe_area.dart';
import 'package:gt7_companion/l10n/ui_messages.dart';
// START_MODULE_CONTRACT
// PURPOSE: Independent manufacturer catalogue and Gran Turismo-style showroom.
// SCOPE: Responsive brand/car browsing, content language and local back stack.
// DEPENDS: M-REPO-BRAND-CENTRAL, M-MODEL-BRAND-CENTRAL
// LINKS: M-WIDGET-BRAND-CENTRAL, V-M-WIDGET-BRAND-CENTRAL
// END_MODULE_CONTRACT
// START_MODULE_MAP
// BrandCentralDisplay - routed catalogue screen.
// END_MODULE_MAP
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/brand_central/brand_central_data.dart';
import '../../repositories/brand_central_repository.dart';
import 'brand_central_showroom.dart';
import 'brand_central_background.dart';
import 'brand_central_region_lobby.dart';

@RoutePage()
class BrandCentralDisplay extends StatefulWidget {
  const BrandCentralDisplay({super.key});
  @override
  State<BrandCentralDisplay> createState() => _BrandCentralDisplayState();
}

class _BrandCentralDisplayState extends State<BrandCentralDisplay> {
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final repo = context.read<BrandCentralRepository>();
      _search.text = repo.query;
      repo.load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<BrandCentralRepository>(
      builder: (context, repo, _) {
        final nested =
            repo.carId != null ||
            repo.brandId != null ||
            repo.allCars ||
            repo.regionChosen;
        final countries =
            repo.brands.map((brand) => brand.country).toSet().toList()..sort();
        return PopScope(
          canPop: !nested,
          onPopInvokedWithResult: (popped, _) {
            if (!popped) repo.back();
          },
          child: Scaffold(
            body: BrandCentralBackground(
              showMap: repo.selectedCar == null,
              region: repo.region,
              mapOpacity:
                  repo.regionChosen || repo.allCars || repo.brandId != null
                  ? .14
                  : .42,
              child: SafeArea(
                child: Column(
                  children: [
                    WindowNavigationSafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            if (nested)
                              IconButton(
                                key: const ValueKey('brand-back'),
                                tooltip: context.tr('Back'),
                                onPressed: repo.back,
                                icon: const Icon(Icons.arrow_back),
                              ),
                            const Spacer(),

                            IconButton(
                              key: const ValueKey('brand-close'),
                              tooltip: context.tr('Close Brand Central'),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_sharp),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: repo.data == null
                          ? Center(
                              child: repo.isLoading
                                  ? const CircularProgressIndicator()
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          context.tr(
                                            repo.error ?? 'Loading catalogue…',
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: repo.load,
                                          tooltip: context.tr(
                                            'Retry catalogue',
                                          ),
                                          icon: const Icon(Icons.refresh),
                                        ),
                                      ],
                                    ),
                            )
                          : repo.selectedCar != null
                          ? BrandCentralShowroom(
                              key: ValueKey(repo.carId),
                              repository: repo,
                            )
                          : !repo.regionChosen &&
                                !repo.allCars &&
                                repo.brandId == null
                          ? BrandCentralRegionLobby(
                              repository: repo,
                              onChooseRegion: (region) {
                                _search.clear();
                                repo.chooseRegion(region);
                              },
                            )
                          : CustomScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              key: PageStorageKey(
                                'brands-${repo.brandId}-${repo.allCars}',
                              ),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr(
                                            repo.selectedBrand?.country
                                                    .toUpperCase() ??
                                                'GRAN TURISMO / BRAND CENTRAL',
                                          ),
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                letterSpacing: 2,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                        const SizedBox(height: 20),
                                        Wrap(
                                          spacing: 20,
                                          runSpacing: 12,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            if (repo.selectedBrand
                                                case final brand?)
                                              SizedBox(
                                                width: 108,
                                                height: 56,
                                                child: _BrandLogo(brand: brand),
                                              ),
                                            Text(
                                              context.tr(
                                                repo.selectedBrand?.name ??
                                                    (repo.allCars
                                                        ? 'All GT7 cars'
                                                        : 'Select a manufacturer'),
                                              ),
                                              style: theme
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w300,
                                                    letterSpacing: -.5,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          context.tr(
                                            '${repo.data!.editions[repo.language]!.length} cars · ${repo.data!.brands.length} marques · Official GT7 catalogue',
                                          ),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 20),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 640,
                                          ),
                                          child: TextField(
                                            key: const ValueKey('brand-search'),
                                            controller: _search,
                                            onChanged: repo.search,
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                Icons.search,
                                              ),
                                              hintText: context.tr(
                                                'Search brands or cars',
                                              ),
                                              suffixIcon: IconButton(
                                                tooltip: context.tr(
                                                  'Clear search',
                                                ),
                                                icon: const Icon(Icons.close),
                                                onPressed: () {
                                                  _search.clear();
                                                  repo.search('');
                                                },
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        if (!repo.allCars &&
                                            repo.brandId == null)
                                          TextButton.icon(
                                            key: const ValueKey(
                                              'brand-change-region',
                                            ),
                                            onPressed: repo.back,
                                            icon: const Icon(Icons.public),
                                            label: Text(
                                              context.tr(
                                                'Change region · ${repo.region == 'North America' ? 'America' : repo.region}',
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            if (!repo.allCars &&
                                                repo.brandId == null)
                                              OutlinedButton.icon(
                                                key: const ValueKey(
                                                  'brand-all-cars',
                                                ),
                                                onPressed: () =>
                                                    repo.openBrand(null),
                                                icon: const Icon(
                                                  Icons.grid_view,
                                                ),
                                                label: Text(
                                                  context.tr('All GT7 cars'),
                                                ),
                                              ),
                                            if (repo.allCars ||
                                                repo.brandId != null)
                                              SizedBox(
                                                width: 240,
                                                child:
                                                    DropdownButton<
                                                      ShowroomSort
                                                    >(
                                                      isExpanded: true,
                                                      value: repo.sort,
                                                      onChanged: (value) =>
                                                          repo.setSort(value!),
                                                      items: [
                                                        DropdownMenuItem(
                                                          value:
                                                              ShowroomSort.name,
                                                          child: Text(
                                                            context.tr(
                                                              'Name A–Z',
                                                            ),
                                                          ),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: ShowroomSort
                                                              .performance,
                                                          child: Text(
                                                            context.tr(
                                                              'Performance points',
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: ShowroomSort
                                                              .power,
                                                          child: Text(
                                                            context.tr('Power'),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              ),
                                            Text(
                                              context.tr(
                                                '${repo.allCars || repo.brandId != null ? repo.cars.length : repo.brands.length} results',
                                              ),
                                              style: theme.textTheme.labelLarge,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (repo.allCars || repo.brandId != null)
                                  _CatalogueGrid(
                                    cars: repo.cars,
                                    repository: repo,
                                  )
                                else ...[
                                  for (final country in countries)
                                    SliverMainAxisGroup(
                                      slivers: [
                                        SliverToBoxAdapter(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              24,
                                              12,
                                              24,
                                              12,
                                            ),
                                            child: Text(
                                              context.tr(country.toUpperCase()),
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    letterSpacing: 2,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        _BrandGrid(
                                          brands: repo.brands
                                              .where(
                                                (brand) =>
                                                    brand.country == country,
                                              )
                                              .toList(),
                                          repository: repo,
                                        ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 24),
                                        ),
                                      ],
                                    ),
                                ],
                                if ((repo.allCars || repo.brandId != null)
                                    ? repo.cars.isEmpty
                                    : repo.brands.isEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text(
                                        context.tr(
                                          'No matches. Try another name or region.',
                                        ),
                                      ),
                                    ),
                                  ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      24,
                                      16,
                                      120,
                                    ),
                                    child: Text(
                                      context.tr(
                                        'Car data & photography: Polyphony Digital / gran-turismo.com.\nThis catalogue includes all listed GT7 cars; availability in the game varies.',
                                      ),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.brand});
  final ShowroomBrand brand;
  @override
  Widget build(BuildContext context) => Image.network(
    brand.logoUrl,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => Center(
      child: Text(context.tr(brand.name), textAlign: TextAlign.center),
    ),
  );
}

class _BrandGrid extends StatelessWidget {
  const _BrandGrid({required this.brands, required this.repository});
  final List<ShowroomBrand> brands;
  final BrandCentralRepository repository;
  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.crossAxisExtent;
      final columns = width >= 1200
          ? 6
          : width >= 900
          ? 5
          : width >= 600
          ? 4
          : 2;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final theme = Theme.of(context);
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 140 + 32 * (scale - 1),
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final brand = brands[index];
            return Tooltip(
              message: context.tr(
                '${brand.name} · ${repository.count(brand.id)} cars',
              ),
              child: Semantics(
                button: true,
                label: context.tr(brand.name),
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(6),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('brand-${brand.id}'),
                    hoverColor: theme.colorScheme.onSurface.withValues(
                      alpha: .13,
                    ),
                    focusColor: theme.colorScheme.onSurface.withValues(
                      alpha: .18,
                    ),
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      repository.openBrand(brand.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  .2126,
                                  .7152,
                                  .0722,
                                  0,
                                  0,
                                  .2126,
                                  .7152,
                                  .0722,
                                  0,
                                  0,
                                  .2126,
                                  .7152,
                                  .0722,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                                child: _BrandLogo(brand: brand),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr(brand.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }, childCount: brands.length),
        ),
      );
    },
  );
}

class _CatalogueGrid extends StatelessWidget {
  const _CatalogueGrid({required this.cars, required this.repository});
  final List<ShowroomCar> cars;
  final BrandCentralRepository repository;
  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.crossAxisExtent >= 1200
          ? 4
          : constraints.crossAxisExtent >= 800
          ? 3
          : constraints.crossAxisExtent >= 480
          ? 2
          : 1;
      final theme = Theme.of(context);
      final scale = MediaQuery.textScalerOf(context).scale(1);
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 270 + 56 * (scale - 1),
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final car = cars[index];
            return Material(
              color: theme.colorScheme.surfaceContainerLow.withValues(
                alpha: .72,
              ),
              borderRadius: BorderRadius.circular(6),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('showroom-${car.id}'),
                onTap: () => repository.selectCar(car.id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: Image.network(
                            car.thumbnail,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.directions_car, size: 64),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(car.name),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          '${car.text('performancePoint')} · ${car.text('power')}',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }, childCount: cars.length),
        ),
      );
    },
  );
}
