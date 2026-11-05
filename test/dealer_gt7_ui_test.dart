import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gt7_companion/l10n/generated/app_localizations.dart';
import 'package:gt7_companion/repositories/dealer_catalog_repository.dart';
import 'package:gt7_companion/services/brand_central_service.dart';
import 'package:gt7_companion/widgets/car_dealer/dealer_theme.dart';
import 'package:gt7_companion/widgets/car_dealer/used/used_car_grid_item.dart';
import 'package:gt7_companion/widgets/car_dealer/legendary/legendary_car_grid_item.dart';
import 'dealer_gt7_data_test.dart' show sample;
import 'package:gt7_companion/widgets/car_dealer/dealer_card_parts.dart';

void main() {
  for (final width in [390.0, 820.0, 1280.0]) {
    for (final language in ['en', 'ru']) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('Used card fits $width $language scale $scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final source = BrandCentralService();
          final catalog = DealerCatalogRepository(source);
          await tester.runAsync(catalog.load);
          addTearDown(source.dispose);
          addTearDown(catalog.dispose);
          var tapped = false;
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: catalog,
              child: MaterialApp(
                locale: Locale(language),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: dealerTheme(ThemeData(), legendary: false),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: width < 600 ? width - 32 : 380,
                      height: 140 * scale,
                      child: UsedCarCardItem(
                        car: sample(
                          name: "Fairlady Z 300ZX TT 2seater '89",
                          state: 'limited',
                        ),
                        onTap: () => tapped = true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final mileage = tester.widget<Icon>(find.byIcon(Icons.speed_outlined));
          expect(mileage.color, const Color(0xFFFFFFFF));

          expect(find.text('PP 112.13'), findsOneWidget);
          final priceText = tester.widget<Text>(
            find.descendant(
              of: find.byType(DealerPrice),
              matching: find.byType(Text),
            ),
          );
          final price = priceText.textSpan! as TextSpan;
          final prefix = price.children!.first as TextSpan;
          expect(prefix.style!.fontSize, lessThan(price.style!.fontSize!));
          expect(find.textContaining('12000'), findsNothing);
          await tester.tap(
            find.byKey(const ValueKey('dealer-used-car-car1523')),
          );
          expect(tapped, isTrue);
        });
      }
    }
  }
  for (final width in [390.0, 820.0, 1280.0]) {
    testWidgets('Legend column fits $width with enlarged Russian text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = BrandCentralService();
      final catalog = DealerCatalogRepository(source);
      await tester.runAsync(catalog.load);
      addTearDown(source.dispose);
      addTearDown(catalog.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: catalog,
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: dealerTheme(ThemeData(), legendary: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width < 600 ? 170 : 220,
                  height: 672,
                  child: LegendaryCarCardItem(car: sample()),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('1968'), findsOneWidget);
      final ink = tester.widget<InkWell>(
        find.byKey(const ValueKey('dealer-legendary-car-car1523')),
      );
      expect(ink.child, isA<CustomPaint>());
    });
  }
}
