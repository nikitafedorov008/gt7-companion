import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/blocs/throttle_brake_graph/throttle_brake_graph_bloc.dart';
import 'package:gt7_companion/blocs/throttle_brake_graph/throttle_brake_graph_event.dart';
import 'package:gt7_companion/blocs/throttle_brake_graph/throttle_brake_graph_state.dart';
import 'package:gt7_companion/services/telemetry_service.dart';
import 'package:gt7_companion/widgets/telemetry/throttle_brake_graph.dart';

/// The clutch on the throttle/brake graph is the packet's `0xF4`, which is a
/// 0..1 pedal position. Two things can go quietly wrong with it: the value can
/// fail to reach the graph at all, and the scale can be missed (0.4 shown as
/// "0%" or as "0.4%"). Both are checked here, and the demo is asked to drive a
/// clutch so the trace has something to draw on a paddle-shift car.
void main() {
  test('a clutch value reaches the history, in percent', () async {
    final service = TelemetryService();
    final bloc = ThrottleBrakeGraphBloc(service);
    addTearDown(bloc.close);

    bloc.add(
      ThrottleBrakeGraphEvent.telemetryUpdated(
        throttle: 100,
        brake: 0,
        clutch: 42,
        clutchEngaged: 17,
        timestamp: DateTime(2026, 1, 1, 12),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final state = bloc.state;
    expect(state, isA<ThrottleBrakeGraphState>());
    state.when(
      initial: () => fail('the bloc never left its initial state'),
      loading: () => fail('the bloc never left its loading state'),
      error: (message) => fail(message),
      success: (history) {
        expect(history, hasLength(1));
        expect(history.single.clutch, 42);
        expect(history.single.clutchEngaged, 17);
        expect(history.single.throttle, 100);
      },
    );
  });

  test('the clutch is clamped like the other two pedals', () async {
    final service = TelemetryService();
    final bloc = ThrottleBrakeGraphBloc(service);
    addTearDown(bloc.close);

    bloc.add(
      ThrottleBrakeGraphEvent.telemetryUpdated(
        throttle: 100,
        brake: 0,
        clutch: 140,
        timestamp: DateTime(2026, 1, 1, 12),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    bloc.state.when(
      initial: () => fail('initial'),
      loading: () => fail('loading'),
      error: (message) => fail(message),
      success: (history) => expect(history.single.clutch, 100),
    );
  });

  test('a data point without a clutch is zero, not null', () {
    // Packet A always carries the field, but a point built by hand (a test, a
    // replay) must still be a number, because the graph adds it to a series.
    final point = ThrottleBrakeDataPoint(
      throttle: 10,
      brake: 20,
      timestamp: DateTime(2026),
    );
    expect(point.clutch, 0.0);
    expect(point.clutchEngaged, 0.0);
  });

  test('the demo works a clutch pedal, the way a clutch trace needs', () async {
    final service = TelemetryService();
    await service.startDemoTelemetry();
    addTearDown(service.disconnect);

    // The demo shifts gear as the speed climbs, and the pedal goes with it: down
    // for a moment, then back up. A pedal that is *never* released is the bug
    // this test exists for - the first version held it down for good because it
    // compared the gear against the packet it was building, which always starts
    // at zero and so looked like a shift on every tick.
    var pressed = 0.0;
    var releasedAfterPress = false;
    for (var i = 0; i < 500; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final clutch = service.telemetry?.clutch ?? 0;
      if (clutch > pressed) pressed = clutch;
      if (pressed > 0.9 && clutch == 0.0) releasedAfterPress = true;
      if (releasedAfterPress) break;
    }

    expect(
      pressed,
      greaterThan(0.9),
      reason: 'the demo has to press the clutch for a shift',
    );
    expect(
      releasedAfterPress,
      isTrue,
      reason: 'and let it out again, or the trace is a flat line at 100%',
    );
    expect(
      service.telemetry!.clutchEngaged,
      lessThanOrEqualTo(1.0),
      reason: 'engagement follows the pedal, inverted',
    );
    // Pedal and engagement are two different traces, not one mirrored: while
    // the pedal is down the clutch is still on its way out.
    var differed = false;
    for (var i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final t = service.telemetry!;
      if ((t.clutch - t.clutchEngaged).abs() > 0.05) differed = true;
    }
    expect(
      differed,
      isTrue,
      reason: 'the pedal and the clutch itself must not be the same line',
    );
  });

  group('on the graph', () {
    /// Builds a bloc with a fixed window of samples: throttle and brake steady
    /// at 100/20, the clutch whatever the caller asks for.
    Future<ThrottleBrakeGraphBloc> blocWith(
      WidgetTester tester,
      double clutch, {
      double? engaged,
    }) async {
      final bloc = ThrottleBrakeGraphBloc(TelemetryService());
      final start = DateTime(2026, 1, 1, 12);
      for (var i = 0; i < 40; i++) {
        bloc.add(
          ThrottleBrakeGraphEvent.telemetryUpdated(
            throttle: 100,
            brake: 20,
            clutch: clutch,
            clutchEngaged: engaged ?? clutch,
            timestamp: start.add(Duration(milliseconds: 120 * i)),
          ),
        );
      }
      await tester.pump();
      return bloc;
    }

    Future<List<int>> render(
      WidgetTester tester,
      double clutch, {
      double? engaged,
    }) async {
      final bloc = await blocWith(tester, clutch, engaged: engaged);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF14161B),
            body: BlocProvider<ThrottleBrakeGraphBloc>.value(
              value: bloc,
              child: RepaintBoundary(
                key: key,
                child: const ThrottleBrakeGraph(height: 230),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      late List<int> bytes;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        bytes = data!.buffer.asUint8List().toList();
        image.dispose();
      });
      // The graph's initState started the bloc polling; cancel it before the
      // test body returns or the binding reports a pending timer. Not awaited:
      // `close()` cancels the timer synchronously, and awaiting the rest of it
      // inside the fake clock is what stalls a widget test.
      unawaited(bloc.close());
      return bytes;
    }

    int differing(List<int> a, List<int> b) {
      var count = 0;
      for (var i = 0; i < a.length; i += 4) {
        if (a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]) {
          count++;
        }
      }
      return count;
    }

    testWidgets('the readout names the clutch and shows its value', (
      tester,
    ) async {
      final bloc = await blocWith(tester, 60);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<ThrottleBrakeGraphBloc>.value(
              value: bloc,
              child: const ThrottleBrakeGraph(height: 230),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('CLUTCH'), findsOneWidget);
      expect(find.text('ENGAGED'), findsOneWidget);
      expect(find.text('60%'), findsWidgets);
      unawaited(bloc.close());
    });

    testWidgets('a pressed clutch is drawn, a zero one is not', (tester) async {
      final pressed = await render(tester, 60);
      final released = await render(tester, 0);
      final barely = await render(tester, 0.5);

      expect(
        differing(pressed, released),
        greaterThan(200),
        reason: 'the clutch trace has to reach the plot',
      );
      expect(
        differing(released, barely),
        0,
        reason: 'under a percent is noise, not a trace: nothing is drawn',
      );
    });

    testWidgets('the clutch and its engagement are two lines, not one', (
      tester,
    ) async {
      // Same pedal, different clutch: a car letting it in slowly. If the
      // engagement were drawn from the pedal's own series the two pictures
      // would be identical.
      final together = await render(tester, 80, engaged: 80);
      final slipping = await render(tester, 80, engaged: 30);

      expect(differing(together, slipping), greaterThan(200));
    });

    testWidgets('a paddle-shift car shows no clutch entries at all', (
      tester,
    ) async {
      final bloc = await blocWith(tester, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<ThrottleBrakeGraphBloc>.value(
              value: bloc,
              child: const ThrottleBrakeGraph(height: 230),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.text('THROTTLE'), findsOneWidget);
      expect(find.text('BRAKE'), findsOneWidget);
      expect(find.text('CLUTCH'), findsNothing);
      expect(find.text('ENGAGED'), findsNothing);
      unawaited(bloc.close());
    });
  });
}
