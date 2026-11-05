import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gt7_companion/l10n/generated/app_localizations.dart';
import 'package:gt7_companion/models/car_dealer/car.dart';
import 'package:gt7_companion/repositories/car_repository.dart';
import 'package:gt7_companion/repositories/dealer_catalog_repository.dart';
import 'package:gt7_companion/repositories/wishlist_repository.dart';
import 'package:gt7_companion/services/brand_central_service.dart';
import 'package:gt7_companion/services/gt7info_service.dart';
import 'package:gt7_companion/services/gtdb_service.dart';
import 'package:gt7_companion/widgets/car_dealer/dealer_inventory.dart';
import 'package:gt7_companion/widgets/car_dealer/dealer_car_dialog.dart';
import 'package:gt7_companion/widgets/car_dealer/dealer_wishlist.dart';
import 'package:gt7_companion/widgets/car_dealer/used/used_car_grid_item.dart';
import 'dealer_gt7_data_test.dart' show sample;
import 'dealer_gt7_dialog_test.dart' show DialogPreferences;

class InventoryFixture extends CarRepository {
  InventoryFixture(this.rows)
    : super(
        GT7InfoService(),
        GTDBService(),
        catalog: DealerCatalogRepository(BrandCentralService()),
      );
  final List<Car> rows;
  bool forced = false;
  @override
  List<Car> get allCars => rows;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => 'one source is offline';
  @override
  bool get isOffline => true;
  @override
  String get dataDate => '2026-11-04';
  @override
  List<Car> getUsedCars() => rows;
  @override
  List<Car> getLegendCars() => rows;
  @override
  Future<void> fetchAllCars({bool forceRefresh = false}) async {
    forced = forceRefresh;
  }
}

Future<
  ({
    DealerCatalogRepository catalog,
    WishlistRepository wishlist,
    InventoryFixture inventory,
    BrandCentralService source,
  })
>
dependencies(WidgetTester tester, {bool saved = false}) async {
  final source = BrandCentralService(), prefs = DialogPreferences();
  if (saved) prefs.data[WishlistRepository.storageKey] = ['car1523'];
  final catalog = DealerCatalogRepository(source),
      wishlist = WishlistRepository(preferences: () async => prefs);
  final inventory = InventoryFixture(
    List.generate(
      36,
      (i) => sample(id: ['car1523', 'car3438', 'car3442', 'car204'][i % 4]),
    ),
  );
  await tester.runAsync(() => Future.wait([catalog.load(), wishlist.load()]));
  addTearDown(source.dispose);
  addTearDown(catalog.dispose);
  addTearDown(wishlist.dispose);
  addTearDown(inventory.dispose);
  return (
    catalog: catalog,
    wishlist: wishlist,
    inventory: inventory,
    source: source,
  );
}

Widget host(
  Widget child,
  DealerCatalogRepository catalog,
  WishlistRepository wishlist,
  CarRepository inventory, {
  String language = 'ru',
  double scale = 1,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: catalog),
    ChangeNotifierProvider.value(value: wishlist),
    ChangeNotifierProvider<CarRepository>.value(value: inventory),
  ],
  child: MaterialApp(
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: ThemeData(platform: TargetPlatform.iOS),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  ),
);
void size(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  for (final width in [390.0, 820.0, 1280.0]) {
    for (final legendary in [false, true]) {
      for (final language in ['ru', 'en']) {
        for (final scale in [1.0, 1.5]) {
          testWidgets(
            'inventory $width $language legend=$legendary scale=$scale retains partial-source cars',
            (tester) async {
              size(tester, width);
              final d = await dependencies(tester);
              await tester.pumpWidget(
                host(
                  DealerInventory(legendary: legendary),
                  d.catalog,
                  d.wishlist,
                  d.inventory,
                  language: language,
                  scale: scale,
                ),
              );
              await tester.pumpAndSettle();
              if (legendary && width >= 700) {
                final list = tester.widget<ListView>(
                  find.byKey(
                    const PageStorageKey('legend-inventory-horizontal'),
                  ),
                );
                expect(list.scrollDirection, Axis.horizontal);
                await tester.drag(
                  find.byKey(
                    const PageStorageKey('legend-inventory-horizontal'),
                  ),
                  const Offset(-500, 0),
                );
                await tester.pumpAndSettle();
                expect(list.controller!.offset, greaterThan(0));
              } else {
                expect(find.byType(GridView), findsOneWidget);
              }
              if (!legendary && width >= 1100) {
                final cardSize = tester.getSize(
                  find.byType(UsedCarCardItem).first,
                );
                expect(
                  cardSize.width / cardSize.height * scale,
                  closeTo(2.86, .02),
                );
              }
              expect(tester.takeException(), isNull);
              if (width < 600) {
                expect(
                  find.byKey(const ValueKey('dealer-refresh')),
                  findsNothing,
                );
                await tester.drag(find.byType(GridView), const Offset(0, 420));
                await tester.pumpAndSettle();
              } else {
                await tester.tap(find.byKey(const ValueKey('dealer-refresh')));
              }
              await tester.pumpAndSettle();
              expect(d.inventory.forced, isTrue);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
  testWidgets(
    'opening and closing a real inventory card preserves scroll position',
    (tester) async {
      size(tester, 390);
      final d = await dependencies(tester);
      await tester.pumpWidget(
        host(
          const DealerInventory(legendary: false),
          d.catalog,
          d.wishlist,
          d.inventory,
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(GridView), const Offset(0, -600));
      await tester.pumpAndSettle();
      final controller = tester
          .widget<GridView>(find.byType(GridView))
          .controller!;
      final offset = controller.offset;
      expect(offset, greaterThan(0));
      await tester.tap(find.byType(UsedCarCardItem).hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.byType(DealerCarDialog), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dealer-dialog-close')));
      await tester.pumpAndSettle();
      expect(controller.offset, closeTo(offset, .1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'wishlist tab opens details and removes a restored rotated-out car',
    (tester) async {
      size(tester, 390);
      final d = await dependencies(tester, saved: true);
      d.inventory.rows.clear();
      await tester.pumpWidget(
        host(const DealerWishlist(), d.catalog, d.wishlist, d.inventory),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('wishlist-row-car1523')),
        findsOneWidget,
      );
      expect(find.text('Cr. 0'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('dealer-used-car-car1523')));
      await tester.pumpAndSettle();
      expect(find.byType(DealerCarDialog), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dealer-dialog-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('wishlist-remove-car1523')));
      await tester.pumpAndSettle();
      expect(d.wishlist.ids, isEmpty);
      expect(find.text('В избранном пока нет автомобилей'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
