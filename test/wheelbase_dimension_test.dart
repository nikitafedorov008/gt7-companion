import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/telemetry/telemetry_data.dart';
import 'package:gt7_companion/widgets/telemetry/g_force_ball.dart';
import 'package:gt7_companion/widgets/telemetry/motion_panel.dart';
import 'package:gt7_companion/widgets/telemetry/motion_workspace.dart';

/// The wheelbase is drawn *in* the round dial, as a dimension line along the
/// car's left flank - so this is a claim about pixels, and about the one
/// threshold that decides whether the dial or the readouts carry the number.
/// Both are checked here, because "written twice" and "not written at all" are
/// the two ways this goes wrong.
void main() {
  const side = 940; // the dial at 470 px, captured at pixelRatio 2

  TelemetryData sample({double wheelbase = 2.6, String surfaces = 'TTTT'}) =>
      TelemetryData()
        ..packetType = 'C'
        ..sway = 8.0
        ..surge = 3.5
        ..steeringAngle = 0.45
        ..frontWheelAngleLeft = 0.51
        ..frontWheelAngleRight = 0.39
        ..surfaceTypes = surfaces
        ..leftWheelbaseMeters = wheelbase;

  /// Paints the dial through its own widget, on a transparent canvas.
  Future<ui.Image> dialImage(
    WidgetTester tester,
    TelemetryData data,
    double size,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: GForceBall(telemetry: data, size: size),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 32));
    late ui.Image image;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      image = await boundary.toImage(pixelRatio: 2);
    });
    return image;
  }

  Future<List<int>> pixels(WidgetTester tester, ui.Image image) async {
    late List<int> bytes;
    await tester.runAsync(() async {
      bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List()
          .toList();
    });
    return bytes;
  }

  int differences(List<int> a, List<int> b) {
    var count = 0;
    for (var i = 0; i < a.length; i += 4) {
      if ((a[i] - b[i]).abs() +
              (a[i + 1] - b[i + 1]).abs() +
              (a[i + 2] - b[i + 2]).abs() >
          24) {
        count++;
      }
    }
    return count;
  }

  testWidgets('a big dial draws the wheelbase, a small one does not', (
    tester,
  ) async {
    final withLine = await pixels(
      tester,
      await dialImage(tester, sample(), 470),
    );
    final without = await pixels(
      tester,
      await dialImage(tester, sample(wheelbase: 0), 470),
    );

    expect(
      differences(withLine, without),
      greaterThan(500),
      reason: 'the dimension has to reach the canvas',
    );

    // Below the threshold the number is text in the panel instead, and the dial
    // must not draw it: an annotation that outgrows the rim is worse than none.
    final smallWith = await pixels(
      tester,
      await dialImage(tester, sample(), kGForceBallWheelbaseSize - 20),
    );
    final smallWithout = await pixels(
      tester,
      await dialImage(tester, sample(wheelbase: 0),
          kGForceBallWheelbaseSize - 20),
    );
    expect(differences(smallWith, smallWithout), 0);
  });

  testWidgets('the number is in the panel only while the dial cannot hold it', (
    tester,
  ) async {
    Future<void> pumpAt(WidgetTester tester, double width) async {
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
                  child: MotionWorkspace(telemetry: sample()),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    // Wide panel: the dial is 470 px, so it draws the dimension and the facts
    // drop the number - the same value twice, one panel apart, is how a readout
    // stops being read.
    await pumpAt(tester, 1400);
    expect(find.text('LEFT WHEELBASE'), findsNothing);

    // A narrow panel: the dial is under the threshold - 344 px, which is the
    // size at which its own label still fits inside a circle with the dimension
    // drawn on it - so the readout keeps the number instead.
    await pumpAt(tester, 360);
    expect(find.text('LEFT WHEELBASE'), findsOneWidget);

    // 420 px is above it, and the dial takes the width it is offered: the
    // dimension is on the car, so the readout drops the number.
    await pumpAt(tester, 420);
    expect(find.text('LEFT WHEELBASE'), findsNothing);
  });
}
