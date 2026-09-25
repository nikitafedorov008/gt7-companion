import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/telemetry/telemetry_data.dart';
import 'package:gt7_companion/models/telemetry/track_trace.dart';
import 'package:gt7_companion/widgets/telemetry/g_force_ball.dart';
import 'package:gt7_companion/widgets/telemetry/motion_side_cards.dart';
import 'package:gt7_companion/widgets/telemetry/motion_workspace.dart';
import 'package:gt7_companion/widgets/telemetry/motion_panel.dart';

/// The motion panel is one component in two orientations: the load dial beside
/// the readouts when there is room, and above them when there is not. Geometry
/// is the only way to check that, so the tests measure where the widgets land.
void main() {
  TelemetryData sample({String surfaces = 'TTTT'}) => TelemetryData()
    ..packetType = 'C'
    ..sway = 9.8 // 1 g sideways
    ..surge = -4.9
    ..heave = 1.2
    ..steeringAngle = 0.2
    ..steeringRate = 0.4
    ..frontWheelAngleLeft = 0.2
    ..frontWheelAngleRight = 0.14
    ..throttle = 80
    ..brake = 20
    ..throttleFiltered = 200
    ..brakeFiltered = 60
    ..surfaceTypes = surfaces
    ..carCategory = 'GR3'
    ..leftWheelbaseMeters = 2.6;

  Future<void> pumpAt(WidgetTester tester, double width, {Widget? side}) async {
    tester.view.physicalSize = const Size(1800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: width,
                child: side ??
                    MotionPanel(
                      telemetry: sample(),
                      trace: TrackTrace(),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('wide: the dial is on the left and the readouts beside it', (
    tester,
  ) async {
    await pumpAt(tester, 1400);

    final dial = tester.getRect(find.byType(GForceBall));
    // The bar's own label, not the panel header, which also mentions steering.
    final steering = tester.getRect(find.text('WHEEL'));

    expect(
      dial.right,
      lessThan(steering.left),
      reason: 'the dial sits left of the readouts, not above them',
    );
  });

  testWidgets('narrow: the dial is on top and the readouts below', (
    tester,
  ) async {
    await pumpAt(tester, 600);

    final dial = tester.getRect(find.byType(GForceBall));
    // The bar's own label, not the panel header, which also mentions steering.
    final steering = tester.getRect(find.text('WHEEL'));

    expect(
      dial.bottom,
      lessThanOrEqualTo(steering.top),
      reason: 'the dial stacks above the readouts when there is no room',
    );
  });

  testWidgets('the load numbers are not repeated beside the dial', (
    tester,
  ) async {
    await pumpAt(tester, 1400);

    // The dial carries LATERAL and LONGITUDINAL itself; the old text blocks
    // must be gone, or the panel says everything twice.
    expect(find.text('LATERAL'), findsNothing);
    expect(find.text('LONGITUDINAL'), findsNothing);
  });

  group('the top row: the route beside the motion block', () {
    Future<void> pumpWorkspace(WidgetTester tester, double width,
        {Widget? leading}) async {
      tester.view.physicalSize = const Size(2400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: width,
                  child: MotionWorkspace(
                    telemetry: sample(),
                    trace: TrackTrace(),
                    leading: leading,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('wide: the route beside a fixed-width motion column', (
      tester,
    ) async {
      await pumpWorkspace(
        tester,
        1300,
        leading: const SizedBox(
          key: Key('leading'),
          height: 300,
          width: double.infinity,
        ),
      );

      expect(tester.takeException(), isNull);
      final leading = tester.getRect(find.byKey(const Key('leading')));
      final motion = tester.getRect(find.byType(MotionPanel));

      expect(leading.left, lessThan(motion.left), reason: 'the route is first');
      expect(
        motion.width,
        closeTo(kMotionColumnWidth, 1),
        reason: 'the motion column is the fixed width the car card shares',
      );
      expect(leading.width, greaterThan(motion.width));
    });

    testWidgets('narrow: the route goes above the motion block', (tester) async {
      await pumpWorkspace(
        tester,
        600,
        leading: const SizedBox(
          key: Key('leading'),
          height: 300,
          width: double.infinity,
        ),
      );

      final leading = tester.getRect(find.byKey(const Key('leading')));
      final motion = tester.getRect(find.byType(MotionPanel));
      expect(leading.bottom, lessThanOrEqualTo(motion.top));
    });

    testWidgets('the motion block is the dial and its chrome', (tester) async {
      await pumpWorkspace(tester, 1300);

      final motion = tester.getRect(find.byType(MotionPanel));
      final dial = tester.getRect(find.byType(GForceBall));
      expect(
        motion.height,
        greaterThan(dial.height),
        reason: 'the heading and the padding are the rest of it',
      );
      expect(
        motion.height - dial.height,
        lessThan(140),
        reason: 'nothing else lives in the block on the data view',
      );
      expect(dial.center.dx, closeTo(motion.center.dx, 2));
    });

    testWidgets('the workspace carries the dial and nothing else', (
      tester,
    ) async {
      // The data view puts the steering instrument and the facts in the car's
      // card, so the motion block is the dial. The HUD, which has no cards,
      // still gets them inline - see the test below.
      await pumpWorkspace(tester, 1300);

      expect(find.byType(GForceBall), findsOneWidget);
      expect(find.text('WHEEL'), findsNothing);
    });

    testWidgets('the HUD keeps the instrument inline', (tester) async {
      tester.view.physicalSize = const Size(1800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MotionPanel(
                telemetry: sample(),
                trace: TrackTrace(),
                bare: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('WHEEL'), findsOneWidget);
      expect(find.text('NOSE'), findsOneWidget);
    });
  });

  group('the surface is written on the tyre, not beside it', () {
    // The row of FL/FR/RL/RR chips is gone: each of those four letters belongs
    // to one wheel, and the wheel itself is on screen in the tyres card.
    Future<void> pumpSurfaces(WidgetTester tester, String surfaces) async {
      tester.view.physicalSize = const Size(2400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: 1400,
                  child: MotionSideCards(telemetry: sample(surfaces: surfaces)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('each tyre tile names its own surface', (tester) async {
      await pumpSurfaces(tester, 'GCTT');

      expect(tester.takeException(), isNull);
      // Front-left on grass, front-right on a kerb, both rears on tarmac.
      expect(find.text('GRASS'), findsOneWidget);
      expect(find.text('KERB'), findsOneWidget);
      expect(find.text('TARMAC'), findsNWidgets(2));
    });

    testWidgets('the chip row that used to carry them is gone', (
      tester,
    ) async {
      await pumpSurfaces(tester, 'GCTT');

      expect(
        find.text('SURFACE'),
        findsNothing,
        reason: 'the surfaces moved onto the wheels',
      );
    });

    testWidgets('a wheel off the racing surface raises OFF TRACK', (
      tester,
    ) async {
      await pumpSurfaces(tester, 'GCTT');
      expect(find.text('OFF TRACK'), findsOneWidget);

      await pumpSurfaces(tester, 'TTCT');
      expect(
        find.text('OFF TRACK'),
        findsNothing,
        reason: 'a kerb is not off track',
      );
      expect(find.text('KERB'), findsOneWidget);
    });

    testWidgets('without a surface block the tiles say so', (tester) async {
      // Packets A and B: no surface letters at all.
      await pumpSurfaces(tester, '');

      expect(tester.takeException(), isNull);
      expect(find.text('NO SURFACE DATA'), findsNWidgets(4));
      expect(find.text('TARMAC'), findsNothing);
    });
  });

  group('the steering/drift instrument reads the two together', () {
    // A drive that grips and then slides, the way `track_trace_test.dart`
    // builds one: the packet's yaw unit is measured from the gripping majority,
    // and the last samples carry the slide.
    TrackTrace drive({required double slip, double radius = 60}) {
      final trace = TrackTrace(minStep: 1);
      const step = 2.5;
      final turn = step / radius;
      var angle = 0.0;
      for (var i = 0; i < 120; i++) {
        final sliding = i >= 88;
        final travel = -angle;
        final body = travel + (sliding ? slip : 0);
        trace.add(
          TelemetryData()
            ..posX = math.cos(angle) * radius
            ..posZ = math.sin(angle) * radius
            ..speed = 60
            ..currentLap = 1
            ..rotYaw = body / math.pi,
        );
        angle += turn;
      }
      return trace;
    }

    TelemetryData wheelLeft() => sample()
      ..steeringAngle = 0.2
      ..frontWheelAngleLeft = 0.2
      ..frontWheelAngleRight = 0.14;

    Future<void> pumpWith(WidgetTester tester, TrackTrace trace) async {
      tester.view.physicalSize = const Size(1800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: 1300,
                  child: MotionPanel(telemetry: wheelLeft(), trace: trace),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a car that grips says so', (tester) async {
      await pumpWith(tester, drive(slip: 0));

      expect(tester.takeException(), isNull);
      expect(find.text('WHEEL'), findsOneWidget);
      expect(find.text('NOSE'), findsOneWidget);
      expect(find.text('GRIP'), findsOneWidget);
    });

    testWidgets('a nose turned further in than the wheels is oversteer', (
      tester,
    ) async {
      // Wheels to the left, nose further left of the travel than they are:
      // the rear is the end that has let go.
      await pumpWith(tester, drive(slip: -0.4));

      expect(find.text('OVERSTEER'), findsOneWidget);
    });

    testWidgets('a nose turned out of the corner is understeer', (tester) async {
      await pumpWith(tester, drive(slip: 0.4));

      expect(find.text('UNDERSTEER'), findsOneWidget);
    });

    testWidgets('with no slip measurements it refuses to guess', (tester) async {
      // No route at all: there is nothing to compare the wheel against, and the
      // instrument says so instead of inventing a verdict.
      await pumpWith(tester, TrackTrace());

      expect(find.text('—'), findsWidgets);
      expect(find.text('OVERSTEER'), findsNothing);
      expect(find.text('UNDERSTEER'), findsNothing);
      expect(find.text('GRIP'), findsNothing);
    });
  });
}
