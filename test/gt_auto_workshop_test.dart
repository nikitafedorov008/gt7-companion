import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gt7_companion/repositories/gt_auto_repository.dart';
import 'package:gt7_companion/theme/gt7_theme.dart';
import 'package:gt7_companion/widgets/gt_auto/gt_auto_display.dart';

import 'gt_auto_data_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<GtAutoRepository> mount(
    WidgetTester tester,
    double width, {
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = await tester.runAsync(() => fixture.workshopRepository());
    addTearDown(repo!.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repo,
        child: MaterialApp(
          theme: gt7Theme(),
          builder: (_, child) => MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1100),
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: const GTAutoDisplay(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  for (final width in [320.0, 390.0, 600.0, 820.0, 1024.0, 1280.0, 1920.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('Workshop at $width and scale $scale fits all sections', (
        tester,
      ) async {
        await mount(tester, width, scale: scale);
        expect(find.text('Workshop'), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final section in ['swaps', 'parts', 'build', 'specs']) {
          final button = find.byKey(ValueKey('gt-auto-section-$section'));
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          final scroll = find.byKey(const ValueKey('gt-auto-scroll'));
          await tester.drag(scroll, const Offset(0, -650));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$section at $width / $scale',
          );
        }
      });
    }
  }

  testWidgets('real menu buttons add a swap and a part to a per-car plan', (
    tester,
  ) async {
    final repo = await mount(tester, 1280);
    await tester.tap(find.byKey(const ValueKey('gt-auto-section-swaps')));
    await tester.pumpAndSettle();
    final add = find.byKey(const ValueKey('gt-auto-save-swap'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(repo.build.swapId, isNotNull);
    final partsTab = find.byKey(const ValueKey('gt-auto-section-parts'));
    await tester.ensureVisible(partsTab);
    await tester.tap(partsTab);
    await tester.pumpAndSettle();
    final part = find.byKey(
      const ValueKey('gt-auto-part-Carbon Propeller Shaft'),
    );
    await tester.ensureVisible(part);
    await tester.tap(part);
    await tester.pumpAndSettle();
    expect(repo.build.parts, ['Carbon Propeller Shaft']);
    final planTab = find.byKey(const ValueKey('gt-auto-section-build'));
    await tester.ensureVisible(planTab);
    await tester.tap(planTab);
    await tester.pumpAndSettle();
    expect(find.text('2JZ-GTE-Supra'), findsOneWidget);
    expect(find.text('Carbon Propeller Shaft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('car picker searches and selects a different real car', (
    tester,
  ) async {
    final repo = await mount(tester, 820);
    final initial = repo.selectedCar!.id;
    await tester.tap(find.byKey(const ValueKey('gt-auto-choose-car')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('gt-auto-search')),
      'Abarth 500',
    );
    await tester.pumpAndSettle();
    final car = repo.cars.firstWhere((c) => c.name.contains('Abarth 500'));
    await tester.tap(find.byKey(ValueKey('gt-auto-car-${car.id}')));
    await tester.pumpAndSettle();
    expect(repo.selectedCar!.id, isNot(initial));
    expect(repo.selectedCar!.id, car.id);
    expect(tester.takeException(), isNull);
  });
}
