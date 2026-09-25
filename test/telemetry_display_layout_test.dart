import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/blocs/throttle_brake_graph/throttle_brake_graph_bloc.dart';
import 'package:gt7_companion/models/telemetry/telemetry_data.dart';
import 'package:gt7_companion/models/telemetry/track_trace.dart';
import 'package:gt7_companion/repositories/track_catalog.dart';
import 'package:gt7_companion/services/telemetry_service.dart';
import 'package:gt7_companion/widgets/telemetry/telemetry_display.dart';

/// The data view as a whole, on a real route: the panels have to survive being
/// put in a row together, and the only way to know that is to lay the page out.
///
/// This exists because it did not: the track map was written for the full width
/// of the page, and the moment it shared a row with the motion block its footer
/// - four facts and a five-step speed legend - overflowed the column by 100 px,
/// which the layout tests missed because they stood a `SizedBox` in for the map.
void main() {
  TelemetryData telemetry() => TelemetryData()
    ..packetType = 'C'
    ..speed = 180
    ..rpm = 5200
    ..currentGear = 4
    ..suggestedGear = 5
    ..fuel = 62
    ..maxFuel = 100
    ..currentLap = 2
    ..totalLaps = 3
    ..currentPos = 3
    ..totalPositions = 12
    ..bestLapTime = 88600
    ..lastLapTime = 92351
    ..lapTimeMs = 41200
    ..steeringAngle = 0.2
    ..frontWheelAngleLeft = 0.2
    ..frontWheelAngleRight = 0.14
    ..surfaceTypes = 'TCGT'
    ..carCategory = 'GR3'
    ..leftWheelbaseMeters = 2.6
    ..oilTemp = 110
    ..waterTemp = 88
    ..brake = 20
    ..tireTempFL = 86
    ..tireTempFR = 87
    ..tireTempRL = 85
    ..tireTempRR = 86;

  /// A driven route: a circle, sampled far enough apart that the trace keeps
  /// every point, so the map has something to draw.
  TrackTrace route() {
    final trace = TrackTrace(minStep: 0.1);
    for (var i = 0; i < 120; i++) {
      final angle = i * 0.12;
      final packet = telemetry()
        ..posX = 60 * math.cos(angle)
        ..posY = 12 * math.sin(angle * 0.7)
        ..posZ = 60 * math.sin(angle)
        ..speed = 150 + 40 * math.sin(angle * 2)
        ..headingNorth = angle + 0.05
        ..curLapTime = i * 0.5
        ..fuel = 60.0 - i * 0.05;
      trace.add(packet);
    }
    return trace;
  }

  Future<void> pumpAt(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width * 2, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final service = TelemetryService();
    final bloc = ThrottleBrakeGraphBloc(service);
    // Not awaited: a widget test's teardown runs under the fake clock, and
    // awaiting the bloc's own shutdown there stalls the test. The timer it owns
    // is cancelled synchronously by `close()`, which is all the invariant needs.
    addTearDown(() {
      unawaited(bloc.close());
      unawaited(service.disconnect());
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TrackCatalog>(create: (_) => TrackCatalog()),
          ChangeNotifierProvider<TelemetryService>.value(value: service),
          BlocProvider<ThrottleBrakeGraphBloc>.value(value: bloc),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TelemetryDisplay(telemetry: telemetry(), trace: route()),
          ),
        ),
      ),
    );
    // One frame to lay out, one to settle, then cancel the graph's poll timer
    // before the test body returns - a pending timer fails the test.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    unawaited(bloc.close());
  }

  testWidgets('a wide page lays out with the map beside the motion block', (
    tester,
  ) async {
    await pumpAt(tester, 1400);

    expect(tester.takeException(), isNull);
    expect(find.text('TRACK MAP'), findsOneWidget);
    expect(find.text('MOTION'), findsOneWidget);
    expect(find.text('TYRES & VEHICLE'), findsOneWidget);

    // The top row is the route and the motion block: two thirds and a third.
    // The *panels*, not the headings: a heading is ten characters wide whatever
    // the layout is, and comparing those would pass for any arrangement at all.
    Rect panelOf(Finder heading) => tester.getRect(
          find.ancestor(of: heading, matching: find.byType(Container)).first,
        );

    final map = panelOf(find.text('TRACK MAP'));
    final motion = panelOf(find.text('MOTION'));
    expect(map.left, lessThan(motion.left));
    expect(map.top, closeTo(motion.top, 1));
    // The route takes the width the motion column does not: the column is a fixed
    // 430 px - the car's card is the same box - so the ratio moves with the page
    // rather than being a rule of its own.
    expect(map.width, greaterThan(motion.width));

    // The motion block and the car's card are the same column: equal widths, so
    // the dial above lines up with the tyres below.
    final carCard = panelOf(find.text('TYRES & VEHICLE'));
    expect(
      motion.width,
      closeTo(carCard.width, 1),
      reason: 'dial above, car card below: one column',
    );

    // And the two come out the same height: the drawing box is sized so that the
    // map's panel lands level with the motion block, which is the dial plus its
    // heading. Not to the pixel - the map's own footer takes a line more or less
    // depending on the numbers in it - but to within one line of it, because a
    // row with one panel ending 50 px short of the other reads as a mistake.
    expect(map.height, closeTo(motion.height, 12));

    // The session's numbers sit *on* the map, in its own drawing box; the car's
    // state is below the dials, in the column the dial stands in.
    final lap = tester.getRect(find.text('LAP'));
    final tyres = tester.getRect(find.text('TYRES & VEHICLE'));
    final wheel = tester.getRect(find.text('WHEEL'));
    expect(
      lap.left,
      greaterThan(map.left),
      reason: 'the session overlay is on the map',
    );
    expect(lap.right, lessThan(map.right));
    expect(lap.top, greaterThan(map.top));
    // The car's card is the column the motion block stands in: right-aligned
    // under it, not stretched across the page.
    expect(tyres.top, greaterThan(motion.bottom));
    expect(carCard.right, closeTo(motion.right, 1));
    expect(
      wheel.top,
      greaterThan(tyres.top),
      reason: 'the instrument is in the car card, under its heading',
    );
  });

  testWidgets('speed and revs follow the top row', (tester) async {
    // The two dials a driver reads while driving come straight after the route
    // and the load, and above the car's card.
    await pumpAt(tester, 1400);

    expect(tester.takeException(), isNull);
    final motion = tester.getRect(
      find.ancestor(of: find.text('MOTION'), matching: find.byType(Container))
          .first,
    );
    final speed = tester.getRect(find.byType(GaugeDial).first);
    final tyres = tester.getRect(
      find.ancestor(
        of: find.text('TYRES & VEHICLE'),
        matching: find.byType(Container),
      ).first,
    );

    expect(speed.top, greaterThan(motion.bottom), reason: 'under the top row');
    expect(tyres.top, greaterThan(speed.bottom), reason: 'the card is below');
  });

  testWidgets('a mid-width page keeps the top row without overflowing', (
    tester,
  ) async {
    // The map's header - its title, the speed range and the mode button - is the
    // tightest thing on the page, and it was written for the full width. At
    // 1000 px the map gets about two thirds of it, which is where it broke
    // before the caption learned to give way.
    await pumpAt(tester, 1000);

    expect(tester.takeException(), isNull);
    final map = tester.getRect(
      find.ancestor(
        of: find.text('TRACK MAP'),
        matching: find.byType(Container),
      ).first,
    );
    final motion = tester.getRect(
      find.ancestor(of: find.text('MOTION'), matching: find.byType(Container))
          .first,
    );
    expect(map.left, lessThan(motion.left));
  });

  testWidgets('a narrow page stacks them without overflowing', (tester) async {
    await pumpAt(tester, 600);

    expect(tester.takeException(), isNull);
    final map = tester.getRect(find.text('TRACK MAP'));
    final motion = tester.getRect(find.text('MOTION'));
    expect(map.top, lessThan(motion.top));
  });
}
