import 'package:gt7_companion/l10n/ui_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/widgets/home/service_menu.dart';

void main() {
  for (final locale in ['en', 'ru']) {
    for (final width in [320.0, 390.0, 600.0, 768.0, 1024.0, 1280.0, 1920.0]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'all services $locale fit width $width at text scale $scale',
          (tester) async {
            tester.view.physicalSize = Size(width, 1200);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final taps = <String>[];
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(locale),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ServiceMenu(
                        onBrandCentral: () => taps.add('brand-central'),
                        onUsed: () => taps.add('used'),
                        onLegendary: () => taps.add('legendary'),
                        onGTAuto: () => taps.add('gtauto'),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('service-apex')), findsNothing);
            final cards = [
              for (final id in ['brand-central', 'used', 'legendary', 'gtauto'])
                find.byKey(ValueKey('service-$id')),
            ];
            final rects = cards.map(tester.getRect).toList();
            final columns = width - 32 >= 900
                ? 4
                : width - 32 >= 344
                ? 2
                : 1;
            for (var i = 0; i < rects.length; i++) {
              expect(rects[i].left, greaterThanOrEqualTo(16));
              expect(rects[i].right, lessThanOrEqualTo(width - 16 + .01));
              expect(rects[i].width, closeTo(rects.first.width, .01));
              if (i % columns != 0) {
                expect(rects[i].top, closeTo(rects[i - 1].top, .01));
                expect(rects[i].left - rects[i - 1].right, closeTo(12, .01));
              }
              if (i >= columns) {
                expect(rects[i].top, greaterThan(rects[i - columns].bottom));
              }
            }
            final menu = tester.getRect(find.byType(ServiceMenu));
            expect(
              menu.bottom,
              closeTo(
                rects.map((r) => r.bottom).reduce((a, b) => a > b ? a : b),
                .01,
              ),
              reason: 'no reserved empty row below cards',
            );
            for (final card in cards) {
              await tester.ensureVisible(card);
              await tester.tap(card);
              await tester.pump();
            }
            expect(taps, ['brand-central', 'used', 'legendary', 'gtauto']);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
