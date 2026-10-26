import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/utils/platform_utils.dart';
import 'package:gt7_companion/widgets/window_navigation_safe_area.dart';

void main() {
  testWidgets('macOS native/system insets overlap and are consumed only once', (
    tester,
  ) async {
    final previous = PlatformUtils.windowInsetsNotifier.value;
    addTearDown(() => PlatformUtils.windowInsetsNotifier.value = previous);
    PlatformUtils.windowInsetsNotifier.value = const EdgeInsets.only(left: 74);
    const marker = ValueKey('safe-header');
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(left: 20)),
          child: WindowNavigationSafeArea(
            animate: false,
            child: WindowNavigationSafeArea(
              animate: false,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(key: marker, width: 30, height: 20),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byKey(marker)).dx, 74);
    PlatformUtils.windowInsetsNotifier.value = EdgeInsets.zero;
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(marker)).dx, 20);
  }, variant: TargetPlatformVariant({TargetPlatform.macOS}));
  testWidgets('body below desktop navbar does not reserve native space again', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WindowNavigationScope(
          hasTopNavigation: true,
          child: WindowNavigationSafeArea(
            animate: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(key: ValueKey('content'), width: 20, height: 20),
            ),
          ),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, 0);
  }, variant: TargetPlatformVariant({TargetPlatform.macOS}));
  testWidgets(
    'iOS and other desktop platforms do not acquire macOS traffic-light spacing',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WindowNavigationSafeArea(
            animate: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(key: ValueKey('content'), width: 20, height: 20),
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dx, 0);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
      TargetPlatform.windows,
      TargetPlatform.linux,
    }),
  );
  testWidgets(
    'standalone AppBar keeps the back button beyond native controls',
    (tester) async {
      final previous = PlatformUtils.windowInsetsNotifier.value;
      addTearDown(() => PlatformUtils.windowInsetsNotifier.value = previous);
      PlatformUtils.windowInsetsNotifier.value = const EdgeInsets.only(
        left: 74,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: WindowNavigationAppBar(
              child: AppBar(
                leading: IconButton(
                  key: const ValueKey('back'),
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back),
                ),
                title: const Text('Settings'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('back'))).dx,
        greaterThanOrEqualTo(74),
      );
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS}),
  );
}
