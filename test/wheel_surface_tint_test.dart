import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/theme/gt7_theme.dart';
import 'package:gt7_companion/widgets/telemetry/surface_codes.dart';
import 'package:gt7_companion/widgets/telemetry/car_model_3d.dart';
import 'package:gt7_companion/widgets/telemetry/g_force_ball.dart';

/// The surface readout is not only four letters in the motion panel: each tyre
/// on the car takes the colour of the ground it is standing on, and its contact
/// patch is painted with it. That is a claim about pixels, so it is checked
/// against pixels - the geometry tests can only prove where a patch is drawn,
/// not that the colour reaches the canvas at all.
void main() {
  const centre = Offset(200, 200);
  const scale = 26.0;
  const side = 400;

  /// Paint the car once and hand back its pixels.
  Future<List<int>> render(WidgetTester tester, List<Color?>? colours) async {
    late List<int> bytes;
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      CarModel3D.paint(
        Canvas(recorder),
        centre: centre,
        metresToPixels: scale,
        yaw: 0.32,
        steeringLeft: 0.25,
        steeringRight: 0.18,
        wheelColours: colours,
      );
      final image = await recorder.endRecording().toImage(side, side);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      bytes = data!.buffer.asUint8List().toList();
      image.dispose();
    });
    return bytes;
  }

  int count(List<int> pixels, bool Function(int r, int g, int b) match) {
    var total = 0;
    for (var i = 0; i < pixels.length; i += 4) {
      if (match(pixels[i], pixels[i + 1], pixels[i + 2])) total++;
    }
    return total;
  }

  // Red-dominant and yellow-dominant, rather than an exact match. The body is
  // a translucent shell drawn over the ground, so a patch under the car comes
  // out as the surface colour blended with the car; what survives the blend is
  // the hue, which is exactly what the driver reads. The tyres themselves are
  // near-black and the dial is grey, so nothing else on this canvas is either.
  bool isWarnRed(int r, int g, int b) => r > 120 && r > g + 45 && r > b + 45;
  bool isKerbYellow(int r, int g, int b) =>
      r > 130 && g > 110 && b < 120 && g > b + 40;

  testWidgets('a plain car carries no surface colour at all', (tester) async {
    final plain = await render(tester, null);

    expect(count(plain, isWarnRed), 0);
    expect(count(plain, isKerbYellow), 0);
  });

  testWidgets('four wheels on tarmac stay plain', (tester) async {
    final tarmac = await render(tester, gt7WheelSurfaceColours('TTTT'));

    expect(count(tarmac, isWarnRed), 0);
    expect(count(tarmac, isKerbYellow), 0);
  });

  testWidgets('a wheel on grass paints red, a kerb paints yellow',
      (tester) async {
    // Front-left on grass, front-right on a kerb, both rears on tarmac.
    final mixed = await render(tester, gt7WheelSurfaceColours('GCTT'));

    expect(
      count(mixed, isWarnRed),
      greaterThan(25),
      reason: 'the grass wheel has to be visible as red, even through the '
          'glass body that sits over the front wheels',
    );
    expect(
      count(mixed, isKerbYellow),
      greaterThan(40),
      reason: 'the kerb wheel has to be visible as yellow',
    );

    final plain = await render(tester, null);
    expect(
      count(mixed, isWarnRed),
      greaterThan(count(plain, isWarnRed) + 25),
    );
  });

  testWidgets('the colour lands on the wheel that asked for it', (tester) async {
    // Only the front-left (index 0) is on grass. The car is drawn nose-away, so
    // that wheel is the upper one on the left of the picture - if the tint were
    // applied to the wrong index, or all four shared one colour, the red would
    // not be up there on its own.
    final only = await render(tester, [
      gt7SurfaceColour('G'), // front-left, the only wheel off tarmac
      null,
      null,
      null,
    ]);

    final reds = <int>[]; // x positions of red pixels, in bands of 20
    for (var y = 0; y < side; y++) {
      for (var x = 0; x < side; x++) {
        final i = (y * side + x) * 4;
        if (isWarnRed(only[i], only[i + 1], only[i + 2])) reds.add(y * side + x);
      }
    }
    expect(reds, isNotEmpty);

    final ys = reds.map((p) => p ~/ side).toList()..sort();
    final xs = reds.map((p) => p % side).toList()..sort();

    // The front-left wheel sits high on the dial (nose away) - well above the
    // car's centre line, which is the dial's own centre here.
    expect(
      ys.last,
      lessThan(centre.dy + scale * 1.2),
      reason: 'the tint belongs to a front wheel, not the tail',
    );
    // ...and on the left of the picture, not the right.
    expect(
      xs.reduce((a, b) => a + b) / xs.length,
      lessThan(centre.dx),
    );
  });

  testWidgets('an off-track car is unmistakable', (tester) async {
    final off = await render(tester, gt7WheelSurfaceColours('GGGG'));
    final mixed = await render(tester, gt7WheelSurfaceColours('GCTT'));

    expect(count(off, isWarnRed), greaterThan(count(mixed, isWarnRed)));
    expect(count(off, isWarnRed), greaterThan(150));
  });

  testWidgets('a kerb wheel is yellow and a grass wheel is red, not confused',
      (tester) async {
    // The point is not brightness but identity: the kerb's amber must not be
    // the grass's red, or the car would show "off track" on a kerb. The rear
    // wheels are the ones the camera sees unobstructed, so that is where the
    // hue is read.
    final kerb = await render(tester, gt7WheelSurfaceColours('TTCT'));
    final grass = await render(tester, gt7WheelSurfaceColours('TTGT'));

    expect(count(kerb, isKerbYellow), greaterThan(30));
    expect(count(kerb, isWarnRed), 0, reason: 'a kerb is not off the track');

    expect(count(grass, isWarnRed), greaterThan(30));
    expect(count(grass, isKerbYellow), 0);
  });
}
