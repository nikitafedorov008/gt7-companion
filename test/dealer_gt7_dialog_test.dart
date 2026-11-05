import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gt7_companion/l10n/generated/app_localizations.dart';
import 'package:gt7_companion/repositories/dealer_catalog_repository.dart';
import 'package:gt7_companion/repositories/wishlist_repository.dart';
import 'package:gt7_companion/services/brand_central_service.dart';
import 'package:gt7_companion/widgets/car_dealer/dealer_car_dialog.dart';
import 'package:gt7_companion/widgets/car_dealer/dealer_theme.dart';
import 'package:gt7_companion/widgets/car_dealer/used/used_car_grid_item.dart';
import 'dealer_gt7_data_test.dart' show sample;
import 'package:gt7_companion/widgets/car_dealer/dealer_price_history_dialog.dart';

class DialogPreferences extends Fake implements SharedPreferences {
  final Map<String, List<String>> data = {};
  @override
  List<String>? getStringList(String key) => data[key];
  @override
  Future<bool> setStringList(String key, List<String> values) async {
    data[key] = List.of(values);
    return true;
  }
}

void main() {
  for (final width in [390.0, 820.0, 1280.0]) {
    for (final legendary in [false, true]) {
      for (final language in ['ru', 'en']) {
        for (final scale in [1.0, 1.5]) {
          testWidgets(
            'vehicle dialog $width legend=$legendary $language scale=$scale closes and saves',
            (tester) async {
              tester.view.physicalSize = Size(width, width == 390 ? 844 : 1000);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              SharedPreferences.setMockInitialValues({});
              final source = BrandCentralService();
              final catalog = DealerCatalogRepository(source);
              final prefs = DialogPreferences();
              final wishlist = WishlistRepository(
                preferences: () async => prefs,
              );
              await tester.runAsync(
                () => Future.wait([catalog.load(), wishlist.load()]),
              );
              addTearDown(source.dispose);
              addTearDown(catalog.dispose);
              addTearDown(wishlist.dispose);
              await tester.pumpWidget(
                MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: catalog),
                    ChangeNotifierProvider.value(value: wishlist),
                  ],
                  child: MaterialApp(
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!,
                    ),
                    locale: Locale(language),
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: dealerTheme(
                      ThemeData(platform: TargetPlatform.iOS),
                      legendary: legendary,
                    ),
                    home: Scaffold(
                      body: Builder(
                        builder: (context) => Center(
                          child: SizedBox(
                            width: 350,
                            height: 200 * scale,
                            child: UsedCarCardItem(
                              car: sample(),
                              onTap: () => DealerCarDialog.show(
                                context,
                                sample(),
                                legendary: legendary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              await tester.tap(
                find.byKey(const ValueKey('dealer-used-car-car1523')),
              );
              await tester.pumpAndSettle();
              expect(find.byType(DealerCarDialog), findsOneWidget);
              expect(find.byType(DealerPriceHistoryDialog), findsNothing);
              expect(tester.takeException(), isNull);
              await tester.tap(
                find.byKey(const ValueKey('dealer-wishlist-toggle')),
              );
              await tester.pumpAndSettle();
              await tester.pumpAndSettle();
              expect(
                wishlist.contains('car1523'),
                isTrue,
                reason:
                    'loaded=${wishlist.isLoaded} saving=${wishlist.isSaving} error=${wishlist.error} ids=${wishlist.ids}',
              );
              await tester.tap(find.byKey(const ValueKey('dealer-learn-more')));
              await tester.pumpAndSettle();
              expect(find.byType(SelectableText), findsOneWidget);
              expect(tester.takeException(), isNull);
              await tester.tap(
                find.byKey(const ValueKey('dealer-price-history')),
              );
              await tester.pumpAndSettle();
              expect(find.byType(DealerPriceHistoryDialog), findsOneWidget);
              expect(
                tester
                    .widget<DealerPriceHistoryDialog>(
                      find.byType(DealerPriceHistoryDialog),
                    )
                    .uri
                    .path,
                '/gt7info/cars/prices_1523.png',
              );
              await tester.tap(
                find.byKey(const ValueKey('dealer-chart-close')),
              );
              await tester.pumpAndSettle();
              expect(find.byType(DealerPriceHistoryDialog), findsNothing);
              expect(find.byType(DealerCarDialog), findsOneWidget);
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              await tester.pumpAndSettle();
              expect(find.byType(DealerCarDialog), findsNothing);
              await tester.tap(
                find.byKey(const ValueKey('dealer-used-car-car1523')),
              );
              await tester.pumpAndSettle();
              await tester.tap(
                find.byKey(const ValueKey('dealer-dialog-close')),
              );
              await tester.pumpAndSettle();
              expect(find.byType(DealerCarDialog), findsNothing);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
