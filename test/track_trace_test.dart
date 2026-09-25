import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/telemetry/telemetry_data.dart';
import 'package:gt7_companion/models/telemetry/track_trace.dart';

/// The track map is drawn from the coordinates in the telemetry packet, so the
/// trace has to thin a 60 Hz stream sensibly, notice a new session, and know
/// where the lap in progress began.
void main() {
  TelemetryData at(
    double x,
    double z, {
    double y = 0,
    double speed = 120,
    int lap = 1,
    double time = 0,
  }) {
    return TelemetryData()
      ..posX = x
      ..posY = y
      ..posZ = z
      ..speed = speed
      ..currentLap = lap
      ..curLapTime = time;
  }

  _packetParsing();
  _motionBlock();
  _extendedPackets();
  _quaternionRotation();
  _fuelBookkeeping();
  _bestLapAndDelta();
  _ghostIsItsOwnLine();
  _bodyAttitude();
  _driftFit();

  group('TrackTrace', () {
    test('records a point once the car has moved far enough', () {
      final trace = TrackTrace();

      trace.add(at(0, 0)); // ignored: the packet is empty before a session
      trace.add(at(10, 0));
      expect(trace.add(at(11, 0)), isFalse, reason: '1 m is below minStep');
      expect(trace.add(at(13, 0)), isTrue, reason: '3 m is above minStep');

      expect(trace.length, 2);
      expect(trace.distance, closeTo(3, 0.001));
    });

    test('ignores the zeros the packet reports before a car is on track', () {
      final trace = TrackTrace();

      trace.add(at(0, 0));
      trace.add(at(0, 0));

      expect(trace.length, 0);
      expect(trace.hasRoute, isFalse);
    });

    test('follows the extent of the route', () {
      final trace = TrackTrace(minStep: 1);

      trace.add(at(5, 0, y: 5));
      trace.add(at(100, -50, y: 15));
      trace.add(at(40, 80, y: 9));

      expect(trace.bounds.left, 5);
      expect(trace.bounds.right, 100);
      expect(trace.bounds.top, -50);
      expect(trace.bounds.bottom, 80);
      expect(trace.elevationRange, 10);
    });

    test('starts over when the position jumps to another track', () {
      final trace = TrackTrace();

      trace.add(at(5, 0));
      trace.add(at(50, 0));
      expect(trace.length, 2);

      trace.add(at(-12000, 400)); // a different track, or a new session

      expect(trace.length, 1, reason: 'the line across the world is dropped');
      expect(trace.distance, 0);
    });

    test('counts laps and finds where the current one started', () {
      final trace = TrackTrace(minStep: 1);

      for (var i = 0; i < 5; i++) {
        trace.add(at(5 + i * 10, 0, lap: 1, time: i.toDouble()));
      }
      for (var i = 0; i < 5; i++) {
        trace.add(at(i * 10, 30, lap: 2, time: i.toDouble()));
      }

      expect(trace.laps, 2);
      expect(trace.currentLapStart, 5);
      expect(trace.samples[trace.currentLapStart].lap, 2);
    });

    test('reports the heading of travel in screen radians', () {
      final trace = TrackTrace(minStep: 1);

      trace.add(at(5, 0));
      trace.add(at(15, 0)); // moving along +X
      expect(trace.heading, closeTo(0, 0.001));

      trace.clear();
      trace.add(at(5, 0));
      trace.add(at(5, 10)); // moving along +Z, which is *down* the screen
      expect(trace.heading, closeTo(-1.5708, 0.001));
    });

    test('counts the revision so caches can be invalidated', () {
      final trace = TrackTrace(minStep: 1);
      final before = trace.revision;

      trace.add(at(5, 0));
      trace.add(at(15, 0));

      expect(trace.revision, greaterThan(before));
      expect(trace.hasRoute, isTrue);
      expect(trace.speedRange!.$1, 120);
    });
  });
}

/// The map can only work if the parser really reads the positions out of the
/// packet, so this pins the offsets the community layout documents for packet
/// "A": position at 0x04..0x0F, rotation at 0x1C..0x27.
void _packetParsing() {
  group('TelemetryData.fromBytes positions', () {
    test('reads position, velocity and rotation from packet A', () {
      final bytes = Uint8List(296);
      ByteData.view(bytes.buffer).setInt32(0, 0x47375330, Endian.little);
      _setFloat(bytes, 0x04, 123.5); // posX
      _setFloat(bytes, 0x08, -7.25); // posY
      _setFloat(bytes, 0x0C, -456.75); // posZ
      _setFloat(bytes, 0x10, 1.5); // velX
      _setFloat(bytes, 0x1C, 0.25); // pitch
      _setFloat(bytes, 0x20, -0.5); // yaw
      _setFloat(bytes, 0x28, 1.0); // orientation to north
      _setFloat(bytes, 0x4C, 55.5); // speed, m/s

      final telemetry = TelemetryData.fromBytes(bytes);

      expect(telemetry.posX, closeTo(123.5, 0.001));
      expect(telemetry.posY, closeTo(-7.25, 0.001));
      expect(telemetry.posZ, closeTo(-456.75, 0.001));
      expect(telemetry.velX, closeTo(1.5, 0.001));
      expect(telemetry.rotPitch, closeTo(0.25, 0.001));
      expect(telemetry.rotYaw, closeTo(-0.5, 0.001));
      expect(telemetry.headingNorth, closeTo(1.0, 0.001));
      expect(telemetry.speed, closeTo(199.8, 0.1)); // the packet is m/s
    });
  });
}

void _setFloat(Uint8List bytes, int offset, double value) {
  ByteData.view(bytes.buffer).setFloat32(offset, value, Endian.little);
}

/// The steering angle and the g-forces only exist in packet B and up, and the
/// heartbeat character is what asks for them. These tests pin both the offsets
/// and the "packet A has none of this" case.
void _motionBlock() {
  group('packet B motion block', () {
    test('reads steering and accelerations from 0x128', () {
      final bytes = Uint8List(316); // "B": 296 + 5 floats
      ByteData.view(bytes.buffer).setInt32(0, 0x47375330, Endian.little);
      _setFloat(bytes, 0x4C, 40.0);
      _setFloat(bytes, 0x128, -0.42); // steering, radians
      _setFloat(bytes, 0x12C, 1.25); // steering rate, rad/s
      _setFloat(bytes, 0x130, 9.80665); // sway, m/s^2 -> 1.0 g
      _setFloat(bytes, 0x134, -2.0); // heave
      _setFloat(bytes, 0x138, -9.80665); // surge -> -1.0 g

      final telemetry = TelemetryData.fromBytes(bytes);

      expect(telemetry.packetType, 'B');
      expect(telemetry.hasMotionData, isTrue);
      expect(telemetry.steeringAngle, closeTo(-0.42, 0.001));
      expect(telemetry.steeringRate, closeTo(1.25, 0.001));
      expect(telemetry.lateralG, closeTo(1.0, 0.001));
      expect(telemetry.longitudinalG, closeTo(-1.0, 0.001));
    });

    test('packet A reports no steering instead of a fake zero', () {
      final bytes = Uint8List(296);
      ByteData.view(bytes.buffer).setInt32(0, 0x47375330, Endian.little);
      _setFloat(bytes, 0x4C, 40.0);

      final telemetry = TelemetryData.fromBytes(bytes);

      expect(telemetry.packetType, 'A');
      expect(telemetry.hasMotionData, isFalse);
      expect(telemetry.lateralG, isNull);
    });

    test('packet C carries the same motion block', () {
      final bytes = Uint8List(368);
      ByteData.view(bytes.buffer).setInt32(0, 0x47375330, Endian.little);
      _setFloat(bytes, 0x4C, 40.0);
      _setFloat(bytes, 0x128, 0.2);
      _setFloat(bytes, 0x130, 4.9);

      final telemetry = TelemetryData.fromBytes(bytes);

      expect(telemetry.packetType, 'C');
      expect(telemetry.steeringAngle, closeTo(0.2, 0.001));
      expect(telemetry.lateralG, closeTo(0.5, 0.01));
    });
  });
}

/// The drift angle is the body's yaw against the direction of travel. The
/// packet only says its yaw field is -1…1, so the unit is measured from the
/// drive; these tests build a synthetic drive and check the measurement.
void _driftFit() {
  /// Feeds a car that follows [radius] into an arc, at 60 km/h, with [slip]
  /// radians of body angle added over [slipFrom]..[slipTo].
  TrackTrace drive({
    required int count,
    double radius = 60,
    double slip = 0.4,
    int slipFrom = -1,
    int slipTo = -1,
  }) {
    final trace = TrackTrace(minStep: 1);
    final speed = 60 / 3.6;
    final step = 2.5; // metres between samples
    final turn = step / radius;
    var angle = 0.0;
    for (var i = 0; i < count; i++) {
      final x = math.cos(angle) * radius;
      final z = math.sin(angle) * radius;
      final sliding = slipFrom >= 0 && i >= slipFrom && i < slipTo;
      // Travel direction in screen terms is -angle (z grows downwards on
      // screen); the body is turned by the slip angle.
      final travel = -angle;
      final body = travel + (sliding ? slip : 0);
      trace.add(
        TelemetryData()
          ..posX = x
          ..posZ = z
          ..speed = speed * 3.6
          ..currentLap = 1
          // A full turn is pi per packet unit, which is what the community
          // layout implies for a "-1 -> 1" field.
          ..rotYaw = body / math.pi,
      );
      angle += turn;
    }
    return trace;
  }

  group('drift angle', () {
    test('measures the packet yaw unit from a gripping drive', () {
      final trace = drive(count: 120);

      expect(trace.yawScale, isNotNull);
      expect(trace.yawScale!, closeTo(math.pi, 0.35));
      expect(trace.hasDriftData, isTrue);
    });

    test('reads no slip while the car grips', () {
      final trace = drive(count: 120);

      expect(trace.slipAngle!.abs(), lessThan(0.05));
      expect(trace.bodyHeading, isNotNull);
      expect(trace.bodyHeading!, closeTo(trace.heading, 0.05));
    });

    test('reads the slip angle out of a slide', () {
      // The car grips for most of the drive and then slides: the offset stays
      // on the gripping majority, so the slide shows up as the angle. The
      // drive ends inside the slide, because the reported angle is the one the
      // car has right now.
      //
      // The convention is slip = travel - body: the fixture turns the body
      // *into* the direction of travel (body = travel + 0.4), which is the nose
      // pointing right of the way the car is actually going, so the reported
      // angle is negative.
      final trace = drive(count: 100, slipFrom: 88, slipTo: 140);

      expect(trace.slipAngle!, closeTo(-0.4, 0.12));
      expect(trace.yawScale!, closeTo(math.pi, 0.5));
    });

    test('mirrors the sign when the nose points the other way', () {
      final trace = drive(count: 100, slip: -0.4, slipFrom: 88, slipTo: 140);

      expect(trace.slipAngle!, closeTo(0.4, 0.12));
    });

    test('is not available before there is enough of a drive', () {
      final trace = drive(count: 10);

      expect(trace.hasDriftData, isFalse);
      expect(trace.bodyHeading, isNull);
      expect(trace.slipAngle, isNull);
    });
  });
}

/// Packets "~" and "C" extend the chain A -> B -> ~ -> C, which is what makes
/// their documented sizes (296, 316, 344, 368) add up. These tests pin the two
/// blocks we were missing: the extended data and the car's own geometry.
void _extendedPackets() {
  group('packet ~ and C blocks', () {
    test('reads filtered inputs, torque vectors and regen from 0x13C', () {
      final bytes = Uint8List(344);
      ByteData.view(bytes.buffer).setInt32(0, 0x47375330, Endian.little);
      _setFloat(bytes, 0x4C, 40.0);
      _setFloat(bytes, 0x128, 0.1); // B block still there
      bytes[0x13C] = 200; // throttleFiltered
      bytes[0x13D] = 12; // brakeFiltered
      _setFloat(bytes, 0x140, 120.0); // torque vector FL
      _setFloat(bytes, 0x144, 118.0);
      _setFloat(bytes, 0x148, -40.0);
      _setFloat(bytes, 0x14C, -39.0);
      _setFloat(bytes, 0x150, 55.5); // energy recovery

      final telemetry = TelemetryData.fromBytes(bytes);

      expect(telemetry.packetType, '~');
      expect(telemetry.hasExtendedData, isTrue);
      expect(telemetry.throttleFiltered, 200);
      expect(telemetry.brakeFiltered, 12);
      expect(telemetry.torqueVectors, hasLength(4));
      expect(telemetry.torqueVectors[0], closeTo(120, 0.001));
      expect(telemetry.torqueVectors[2], closeTo(-40, 0.001));
      expect(telemetry.energyRecovery, closeTo(55.5, 0.001));
      // A C-only field must stay unknown in "~".
      expect(telemetry.hasCategoryData, isFalse);
    });

    test('reads surface, wheel angles, wheelbase and category from 0x158', () {
      final bytes = Uint8List(368);
      ByteData.view(bytes.buffer).setInt32(0, 0x47375330, Endian.little);
      _setFloat(bytes, 0x4C, 40.0);
      // surfaces: FL tarmac, FR kerb, RL grass, RR grass
      bytes.setRange(0x158, 0x158 + 4, 'TCGG'.codeUnits);
      ByteData.view(bytes.buffer).setInt32(0x15C, 72345, Endian.little);
      _setFloat(bytes, 0x160, 0.12); // front left wheel angle
      _setFloat(bytes, 0x164, 0.09); // front right
      _setFloat(bytes, 0x168, 2.6); // wheelbase
      bytes.setRange(0x16C, 0x16C + 4, [0x47, 0x52, 0x33, 0x00]); // "GR3\0"

      final telemetry = TelemetryData.fromBytes(bytes);

      expect(telemetry.packetType, 'C');
      expect(telemetry.surfaceTypes, 'TCGG');
      expect(telemetry.surfaceSummary, 'T C G G');
      expect(telemetry.offTrack, isTrue, reason: 'grass under the rear tyres');
      expect(telemetry.lapTimeMs, 72345);
      expect(telemetry.frontWheelAngleLeft, closeTo(0.12, 0.001));
      expect(telemetry.frontWheelAngleRight, closeTo(0.09, 0.001));
      expect(telemetry.leftWheelbaseMeters, closeTo(2.6, 0.001));
      expect(telemetry.carCategory, 'GR3');
      expect(telemetry.hasCategoryData, isTrue);
    });

    test('prefers the C wheel angles over the B wheel rotation', () {
      final bytes = Uint8List(368);
      ByteData.view(bytes.buffer).setInt32(0, 0x47375330, Endian.little);
      _setFloat(bytes, 0x4C, 40.0);
      _setFloat(bytes, 0x128, -1.5); // B wheel rotation
      _setFloat(bytes, 0x160, 0.2);
      _setFloat(bytes, 0x164, 0.1);

      final telemetry = TelemetryData.fromBytes(bytes);

      expect(telemetry.steeringSource, 'C');
      expect(telemetry.steeringRadians, closeTo(0.15, 0.001));
    });

    test('a base packet has none of the extended data', () {
      final bytes = Uint8List(296);
      ByteData.view(bytes.buffer).setInt32(0, 0x47375330, Endian.little);
      _setFloat(bytes, 0x4C, 40.0);

      final telemetry = TelemetryData.fromBytes(bytes);

      expect(telemetry.hasExtendedData, isFalse);
      expect(telemetry.hasCategoryData, isFalse);
      expect(telemetry.surfaceSummary, '—');
      expect(telemetry.offTrack, isFalse);
      expect(telemetry.steeringRadians, isNull);
      expect(telemetry.steeringSource, isNull);
    });
  });
}

/// The rotation block is disputed: three angles plus a heading, or a unit
/// quaternion. The length tells us which, and a quaternion gives the body angle
/// exactly - which is what the drift readout needs.
void _quaternionRotation() {
  group('rotation block', () {
    TelemetryData yawQuaternion(double worldAngle) {
      // Rotation about the up axis that turns the car's forward axis to
      // (cos, sin) in the ground plane.
      final half = -worldAngle / 2;
      return TelemetryData()
        ..rotPitch = 0
        ..rotYaw = math.sin(half)
        ..rotRoll = 0
        ..headingNorth = math.cos(half);
    }

    test('recognises a unit quaternion', () {
      final telemetry = yawQuaternion(1.0);

      expect(telemetry.rotationIsQuaternion, isTrue);
      // Screen convention: atan2(-z, x), so the world angle negates.
      expect(telemetry.quaternionHeading!, closeTo(-1.0, 0.001));
    });

    test('rejects three angles that are not a quaternion', () {
      final telemetry = TelemetryData()
        ..rotPitch = 0.3
        ..rotYaw = -0.7
        ..rotRoll = 0.1
        ..headingNorth = 0.5;

      expect(telemetry.rotationIsQuaternion, isFalse);
      expect(telemetry.quaternionHeading, isNull);
    });

    test('a quaternion makes the drift angle exact, with no fit', () {
      final trace = TrackTrace(minStep: 1);
      for (var i = 0; i < 60; i++) {
        final telemetry = yawQuaternion(0.0) // car points along +X
          ..posX = 10.0 + i * 3
          ..posZ = 0
          ..speed = 120
          ..currentLap = 1;
        trace.exactBodyHeading = telemetry.quaternionHeading;
        trace.add(telemetry);
      }

      // Travelling along +X, body along +X: no slip, and no fitting involved.
      expect(trace.slipAngle!.abs(), lessThan(0.001));
      expect(trace.hasDriftData, isTrue);
      expect(trace.yawScale, isNull, reason: 'the fit is skipped');
    });
  });
}

/// Fuel per lap is arithmetic on a real packet field (0x44), so it is the one
/// strategy number the app can honestly compute. The lap bookkeeping lives in
/// the trace, and the HUD's stint page reads it from there.
void _fuelBookkeeping() {
  group('fuel per lap', () {
    /// Three laps of a kilometre, burning two litres each.
    TrackTrace drive(double startFuel) {
      final trace = TrackTrace(minStep: 1);
      var fuel = startFuel;
      for (var lap = 1; lap <= 3; lap++) {
        for (var i = 0; i < 100; i++) {
          trace.add(
            TelemetryData()
              ..posX = (lap - 1) * 1000 + i * 10
              ..posZ = 0
              ..speed = 100
              ..currentLap = lap
              ..curLapTime = i / 10
              ..fuel = fuel,
          );
        }
        fuel -= 2;
      }
      return trace;
    }

    test('measures the fuel a lap takes', () {
      final trace = drive(60);

      expect(trace.fuelPerLap, isNotNull);
      expect(trace.fuelPerLap!, closeTo(2.0, 0.01));
      expect(trace.lastLapFuel!, closeTo(2.0, 0.01));
    });

    test('knows the length of the lap it just closed', () {
      final trace = drive(60);

      expect(trace.lastLapDistance, closeTo(1000, 20));
      final signature = trace.lapSignature;
      expect(signature, isNotNull);
      expect(signature!.lapDistance, closeTo(1000, 20));
    });

    test('says how many laps are left in the tank', () {
      final trace = drive(60);

      // The last recorded sample carries 56 litres (three laps were burned:
      // 60 -> 58 -> 56), at two litres a lap that is 28 laps.
      expect(trace.lapsRemaining!, closeTo(28, 0.01));
    });

    test('refuses to report a lap from a refuel', () {
      final trace = TrackTrace(minStep: 1);
      // A lap that somehow gains fuel is not a lap worth reporting.
      for (var i = 0; i < 100; i++) {
        trace.add(
          TelemetryData()
            ..posX = i * 10.0
            ..posZ = 0
            ..speed = 100
            ..currentLap = 1
            ..fuel = 60,
        );
      }
      for (var i = 0; i < 100; i++) {
        trace.add(
          TelemetryData()
            ..posX = 1000 + i * 10.0
            ..posZ = 0
            ..speed = 100
            ..currentLap = 2
            ..fuel = 75, // filled up between laps
        );
      }

      expect(trace.fuelPerLap, isNull);
      expect(trace.lapsRemaining, isNull);
    });
  });
}

/// The ghost lap and the live delta: compare the current lap with the fastest
/// completed one *at the same point on the track*, which needs no reference
/// data from anywhere else.
void _bestLapAndDelta() {
  group('best lap and live delta', () {
    /// Drives [laps] laps of 1000 m. Each lap is slower than the last by
    /// [slowdown] seconds, and the time inside a lap is read from the packet's
    /// own lap clock the way packet "C" reports it.
    TrackTrace drive({int laps = 3, double slowdown = 2.0}) {
      final trace = TrackTrace(minStep: 1);
      for (var lap = 1; lap <= laps; lap++) {
        final lapSeconds = 60.0 + (lap - 1) * slowdown;
        for (var i = 0; i < 200; i++) {
          trace.add(
            TelemetryData()
              ..posX = (lap - 1) * 1000 + i * 5.0
              ..posZ = 0
              ..speed = 100
              ..currentLap = lap
              ..curLapTime = lapSeconds * i / 200
              ..lapTimeMs = (lapSeconds * 1000 * i / 200).round()
              ..lastLapTime = lap == 1 ? 0 : ((lapSeconds - slowdown) * 1000).round()
              ..fuel = 60,
          );
        }
      }
      return trace;
    }

    test('finds the fastest completed lap', () {
      final trace = drive();

      expect(trace.bestLap, isNotNull);
      expect(trace.bestLapSamples.length, greaterThan(100));
      // The first lap was the quickest.
      expect(trace.bestLap, 0);
    });

    test('reports how far ahead or behind the current lap is', () {
      final trace = drive();

      // Lap three is two seconds a lap slower than lap one, so by the end of
      // the lap it is about four seconds down.
      final delta = trace.deltaToBest();
      expect(delta, isNotNull);
      expect(delta!, closeTo(4.0, 0.5));
    });

    test('says nothing before a lap has been completed', () {
      final trace = TrackTrace(minStep: 1);
      for (var i = 0; i < 50; i++) {
        trace.add(
          TelemetryData()
            ..posX = i * 5.0
            ..posZ = 0
            ..speed = 100
            ..currentLap = 1
            ..curLapTime = i / 10
            ..fuel = 60,
        );
      }

      expect(trace.bestLap, isNull);
      expect(trace.deltaToBest(), isNull);
      expect(trace.bestLapSamples, isEmpty);
    });
  });
}

/// The ghost is the fastest lap's own line, not the current one: if the driver
/// took a different line on that lap, the two must not be the same samples.
void _ghostIsItsOwnLine() {
  group('ghost lap geometry', () {
    test('keeps the fastest lap apart from the current one', () {
      final trace = TrackTrace(minStep: 1);
      // Lap 1 runs at z = 0, lap 2 ten metres to the side of it.
      for (var lap = 1; lap <= 2; lap++) {
        for (var i = 0; i < 200; i++) {
          trace.add(
            TelemetryData()
              ..posX = (lap - 1) * 1000 + i * 5.0
              ..posZ = lap == 1 ? 0 : 10
              ..speed = 100
              ..currentLap = lap
              ..curLapTime = 60 * i / 200
              ..lastLapTime = lap == 1 ? 0 : 61000
              ..fuel = 60,
          );
        }
      }

      final ghost = trace.bestLapSamples;
      expect(ghost, isNotEmpty);
      // The first lap is the only one with a time on it, so it is the ghost.
      expect(ghost.first.z, 0);
      expect(ghost.last.z, 0);
      expect(trace.samples.last.z, 10, reason: 'the current lap is elsewhere');
    });
  });
}

/// The load dial shows the car's *measured* attitude: the rotation block is a
/// quaternion, so roll and pitch come out of it rather than being guessed from
/// the g-forces.
void _bodyAttitude() {
  group('body attitude from the rotation quaternion', () {
    test('reads roll and pitch out of the quaternion', () {
      double s(double a) => math.sin(a / 2);
      double c(double a) => math.cos(a / 2);

      // The car points along +X, so its long axis is X: rolling it means
      // rotating about X. The convention here is that a positive roll puts the
      // right-hand side down, which is a *negative* right-hand rotation about
      // +X, hence the sign on the half angle.
      const wantRoll = 0.2;
      const wantPitch = -0.1;

      // q = roll(about x) * pitch(about z) for a car along +X.
      final qx = s(-wantRoll), qwRoll = c(-wantRoll);
      final qz = s(wantPitch), qwPitch = c(wantPitch);
      // (qx,0,0,qwRoll) * (0,0,qz,qwPitch)
      final x = qx * qwPitch;
      final y = -qwRoll * qz;
      final z = qwRoll * qz;
      final w = qwRoll * qwPitch;

      final telemetry = TelemetryData()
        ..rotPitch = x
        ..rotYaw = y
        ..rotRoll = z
        ..headingNorth = w;

      expect(telemetry.rotationIsQuaternion, isTrue);
      expect(telemetry.bodyRollRadians!, closeTo(wantRoll, 0.03));
      expect(telemetry.bodyPitchRadians!, closeTo(wantPitch, 0.03));
    });

    test('has no attitude when the block is not a quaternion', () {
      final telemetry = TelemetryData()
        ..rotPitch = 0.4
        ..rotYaw = 0.9
        ..rotRoll = -0.3
        ..headingNorth = 0.2;

      expect(telemetry.bodyRollRadians, isNull);
      expect(telemetry.bodyPitchRadians, isNull);
    });
  });
}
