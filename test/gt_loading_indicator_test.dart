import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/widgets/gt_loading_indicator.dart';

void main() {
  testWidgets('loading mark fits compact and full-size hosts in both themes', (
    tester,
  ) async {
    for (final theme in [ThemeData.light(), ThemeData.dark()]) {
      for (final size in [18.0, 24.0, 56.0]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(child: GtLoadingIndicator(size: size)),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        final mark = find.byType(GtLoadingIndicator);
        expect(tester.getSize(mark), Size.square(size));
        expect(
          tester
              .getRect(mark)
              .contains(tester.getCenter(find.byType(SvgPicture))),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
    'reduced motion stops spinning while retaining loading semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: Center(child: GtLoadingIndicator())),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('legacy light canvas retains contrast under a dark app theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: GtLoadingIndicator(withBackdrop: true)),
        ),
      ),
    );
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(GtLoadingIndicator),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color!.computeLuminance(), lessThan(.1));
    expect(tester.takeException(), isNull);
  });
}
