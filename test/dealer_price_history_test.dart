import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/l10n/generated/app_localizations.dart';
import 'package:gt7_companion/widgets/car_dealer/dealer_price_history_dialog.dart';

void main() {
  for (final width in [390.0, 820.0, 1280.0]) {
    testWidgets('chart loads, zooms, resets and returns at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Actual GT7Info image, supplied as a fixture: no network dependency.
      final provider = MemoryImage(
        File('test/fixtures/dealers/price_history.png').readAsBytesSync(),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => DealerPriceHistoryDialog(
                    uri: Uri.https(
                      'ddm999.github.io',
                      '/gt7info/cars/prices_1523.png',
                    ),
                    carName: "500 F '68",
                    imageProvider: provider,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(provider, tester.element(find.text('Open'))),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const ValueKey('dealer-price-chart')),
      );
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
      await tester.tap(find.byKey(const ValueKey('dealer-chart-zoom-in')));
      await tester.pump();
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        closeTo(1.5, .001),
      );
      await tester.tap(find.byKey(const ValueKey('dealer-chart-reset')));
      await tester.pump();
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DealerPriceHistoryDialog), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });
  }
  testWidgets('invalid image shows retry and retry stays in the viewer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: DealerPriceHistoryDialog(
          uri: Uri.https('ddm999.github.io', '/missing.png'),
          carName: 'Missing',
          imageProvider: MemoryImage(Uint8List.fromList([0, 1, 2])),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dealer-chart-retry')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dealer-chart-retry')));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.byType(DealerPriceHistoryDialog), findsOneWidget);
    expect(find.byKey(const ValueKey('dealer-chart-retry')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('chart panning stays above the swipeable app tabs', (
    tester,
  ) async {
    final tabs = PageController();
    addTearDown(tabs.dispose);
    final provider = MemoryImage(
      File('test/fixtures/dealers/price_history.png').readAsBytesSync(),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PageView(
          controller: tabs,
          children: [
            Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => DealerPriceHistoryDialog.show(
                      context,
                      uri: Uri.https(
                        'ddm999.github.io',
                        '/gt7info/cars/prices_1523.png',
                      ),
                      carName: 'FIAT',
                      imageProvider: provider,
                    ),
                    child: const Text('Open chart'),
                  ),
                ),
              ),
            ),
            const Scaffold(body: Text('Another app tab')),
          ],
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(provider, tester.element(find.text('Open chart'))),
    );
    await tester.tap(find.text('Open chart'));
    await tester.pumpAndSettle();
    final viewer = tester.widget<InteractiveViewer>(
      find.byKey(const ValueKey('dealer-price-chart')),
    );
    await tester.tap(find.byKey(const ValueKey('dealer-chart-zoom-in')));
    await tester.pump();
    final before = viewer.transformationController!.value.getTranslation().x;
    await tester.drag(
      find.byKey(const ValueKey('dealer-price-chart')),
      const Offset(-150, 0),
    );
    await tester.pumpAndSettle();
    expect(tabs.page, 0);
    expect(
      viewer.transformationController!.value.getTranslation().x,
      lessThan(before),
    );
    await tester.tap(find.byKey(const ValueKey('dealer-chart-close')));
    await tester.pumpAndSettle();
    expect(find.text('Open chart'), findsOneWidget);
    expect(tabs.page, 0);
    expect(tester.takeException(), isNull);
  });
}
