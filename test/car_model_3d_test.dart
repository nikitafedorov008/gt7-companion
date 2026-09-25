import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/theme/gt7_theme.dart';
import 'package:gt7_companion/widgets/telemetry/surface_codes.dart';
import 'package:gt7_companion/widgets/telemetry/car_model_3d.dart';
import 'package:gt7_companion/widgets/telemetry/g_force_ball.dart';

/// The car on the load dial is a small 3D model, and two things about it are
/// easy to get wrong and hard to see: whether a wheel steers about its own axis
/// or swings around the car, and whether the wheels climb with the body when it
/// leans. These tests answer both by projecting the actual geometry.
void main() {
  const centre = Offset(200, 200);
  const scale = 22.0;
  const yaw = 0.32;

  Offset at(
    ({double x, double y, double z}) local, {
    double roll = 0,
    double pitch = 0,
    bool onGround = false,
  }) {
    return CarModel3D.project(
      centre: centre,
      metresToPixels: scale,
      local: local,
      yaw: yaw,
      roll: roll,
      pitch: pitch,
      onGround: onGround,
    );
  }

  group('wheels and the body during a lean', () {
    test('all four wheels stay exactly where they are when the body rolls', () {
      const roll = 0.3; // ~17 degrees, a hard corner

      for (final wheel in [
        CarModel3D.frontLeftWheel,
        CarModel3D.frontRightWheel,
        CarModel3D.rearLeftWheel,
        CarModel3D.rearRightWheel,
      ]) {
        final flat = at(wheel, onGround: true);
        final leaned = at(wheel, roll: roll, onGround: true);

        expect(
          (leaned - flat).distance,
          lessThan(0.001),
          reason: 'wheels are on the road, not on the springs',
        );
      }
    });

    test('the body does move when it rolls', () {
      final flat = at(CarModel3D.bodyRoofRight);
      final leaned = at(CarModel3D.bodyRoofRight, roll: 0.3);

      // A seventh of a metre at 22 px/m: the body visibly leans, the wheels
      // above did not move at all.
      expect((leaned - flat).distance, greaterThan(1.5));
    });

    test('and the same holds under braking pitch', () {
      const pitch = -0.15;

      for (final wheel in [
        CarModel3D.frontLeftWheel,
        CarModel3D.rearRightWheel,
      ]) {
        expect(
          (at(wheel, pitch: pitch, onGround: true) - at(wheel, onGround: true))
              .distance,
          lessThan(0.001),
        );
      }

      expect(
        (at(CarModel3D.bodyRoofRight, pitch: pitch) -
                at(CarModel3D.bodyRoofRight))
            .distance,
        greaterThan(0.5),
      );
    });

    test('a wheel placed on the body basis would climb, which is the bug that '
        'was fixed', () {
      final onRoad = at(CarModel3D.frontLeftWheel, roll: 0.3, onGround: true);
      final onBody = at(CarModel3D.frontLeftWheel, roll: 0.3);

      expect((onBody - onRoad).distance, greaterThan(1.0));
    });
  });

  group('every wheel of the car, not just the ones we remembered', () {
    test('the model has four wheels and the painter builds them from one list', () {
      expect(CarModel3D.wheels, hasLength(4));
      expect(
        CarModel3D.wheels.map((wheel) => wheel.name).toSet(),
        {'front-left', 'front-right', 'rear-left', 'rear-right'},
      );
      // Two front (nose, -z) and two rear, on both sides.
      expect(CarModel3D.wheels.where((w) => w.front), hasLength(2));
      expect(
        CarModel3D.wheels.where((w) => !w.front).every((w) => w.centre.z > 0),
        isTrue,
      );
      expect(
        CarModel3D.wheels.where((w) => w.front).every((w) => w.centre.z < 0),
        isTrue,
      );
    });

    test('none of the four climbs with the body when it rolls', () {
      // The rear-left one was built without the flag and spent a day attached
      // to the body. Walking the list is what catches that.
      const roll = 0.35;
      for (final wheel in CarModel3D.wheels) {
        final flat = at(wheel.centre, onGround: true);
        final leaned = at(wheel.centre, roll: roll, onGround: true);

        expect(
          (leaned - flat).distance,
          lessThan(0.001),
          reason: '${wheel.name} must stay on the road, not on the springs',
        );
      }
    });
  });

  group('the car is shown from behind, right side on the right', () {
    // Both of these were wrong at one point, and both are invisible in a still
    // frame: the model used to be built with its nose on +z (a mirror image),
    // which put the car's right on the screen's left and made the wheels look
    // like they steered away from the corner.
    test('the nose is drawn further away than the tail', () {
      final nose = at(CarModel3D.frontLeftWheel, onGround: true);
      final tail = at(CarModel3D.rearLeftWheel, onGround: true);

      expect(nose.dy, lessThan(tail.dy), reason: 'nose up the dial, tail near');
    });

    test('the car right-hand side lands on the right of the screen', () {
      final right = at(CarModel3D.rearRightWheel, onGround: true);
      final left = at(CarModel3D.rearLeftWheel, onGround: true);

      expect(right.dx, greaterThan(left.dx));
    });
  });

  group('the surface under each tyre', () {
    Offset patchCentre(int wheel, {double steering = 0}) {
      final corners = CarModel3D.contactPatchCorners(
        centre: centre,
        metresToPixels: scale,
        yaw: yaw,
        wheelIndex: wheel,
        steering: steering,
      );
      return corners.fold(Offset.zero, (a, b) => a + b) /
          corners.length.toDouble();
    }

    // The motion panel reads the four surface letters out of packet C, and the
    // car on the dial now shows them: a wheel standing on grass is drawn green,
    // one on a kerb takes the HUD's amber. The mapping is one function, so the
    // chips and the tyres cannot drift apart.
    test('all four wheels on tarmac tint nothing at all', () {
      expect(gt7WheelSurfaceColours('TTTT'), isNull);
    });

    test('a packet without surface data tints nothing', () {
      expect(gt7WheelSurfaceColours(''), isNull);
      expect(gt7WheelSurfaceColours('TTT'), isNull);
    });

    test('the colours are per wheel, in the order the model lists them', () {
      // Front-left on grass, front-right on a kerb, rears still on tarmac.
      final colours = gt7WheelSurfaceColours('GCTT');

      expect(colours, hasLength(4));
      expect(colours![0], gt7SurfaceColour('G'));
      expect(colours[1], gt7SurfaceColour('C'));
      expect(colours[2], isNull, reason: 'tarmac keeps the tyre black');
      expect(colours[3], isNull);
    });

    test('every off-track surface reads as a warning, snow as cold', () {
      expect(gt7SurfaceIsOffTrack('G'), isTrue);
      expect(gt7SurfaceIsOffTrack('D'), isTrue);
      expect(gt7SurfaceIsOffTrack('S'), isTrue);
      expect(gt7SurfaceIsOffTrack('T'), isFalse);
      expect(gt7SurfaceIsOffTrack('C'), isFalse);

      expect(gt7SurfaceColour('G'), gt7Warn);
      expect(gt7SurfaceColour('D'), gt7Warn);
      expect(gt7SurfaceColour('S'), gt7Warn);
      expect(gt7SurfaceColour('C'), gt7SlotB);
      expect(gt7SurfaceColour('s'), gt7SlotA);
    });

    test('the patch lies on the road under its own wheel, and turns with it',
        () {
      Offset wheelCentre(int wheel) => at(
            switch (wheel) {
              0 => CarModel3D.frontLeftWheel,
              1 => CarModel3D.frontRightWheel,
              2 => CarModel3D.rearLeftWheel,
              _ => CarModel3D.rearRightWheel,
            },
            onGround: true,
          );

      for (var wheel = 0; wheel < 4; wheel++) {
        final patch = patchCentre(wheel);
        final tyre = wheelCentre(wheel);

        // The patch is on the ground plane and the tyre sits on it, so the two
        // are close in x and the patch is the lower of the two on screen.
        expect(
          (patch.dx - tyre.dx).abs(),
          lessThan(scale * 0.6),
          reason: 'wheel $wheel: patch under its own tyre',
        );
        expect(
          patch.dy,
          greaterThan(tyre.dy - 1),
          reason: 'wheel $wheel: patch on the road, not floating',
        );
      }

      // The four patches are at four different places: a shared centre would
      // mean they were all drawn in one spot.
      final centres = [for (var w = 0; w < 4; w++) patchCentre(w)];
      for (var a = 0; a < 4; a++) {
        for (var b = a + 1; b < 4; b++) {
          expect(
            (centres[a] - centres[b]).distance,
            greaterThan(scale),
            reason: 'patches $a and $b must not coincide',
          );
        }
      }

      // Steering turns the patch about its own centre rather than swinging it
      // around the car, so the centre barely moves while the shape does.
      final straight = CarModel3D.contactPatchCorners(
        centre: centre,
        metresToPixels: scale,
        yaw: yaw,
        wheelIndex: 0,
      );
      final turned = CarModel3D.contactPatchCorners(
        centre: centre,
        metresToPixels: scale,
        yaw: yaw,
        wheelIndex: 0,
        steering: 0.5,
      );

      expect(
        (patchCentre(0, steering: 0.5) - patchCentre(0)).distance,
        lessThan(scale * 0.5),
        reason: 'a patch turns about itself, it does not slide forward',
      );
      expect(
        straight[1] - straight[0],
        isNot(equals(turned[1] - turned[0])),
        reason: 'the shape really does rotate',
      );
    });

    test('the rear wheels take no steering', () {
      // Only the front pair is steered in the picture; a rear patch that
      // reacted to the steering angle would be a visible error.
      final straight = patchCentre(2);
      final turned = patchCentre(2, steering: 0.4);
      expect((straight - turned).distance, lessThan(0.001));
    });
  });
}
