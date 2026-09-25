import 'dart:async';
import 'dart:math';
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import '../services/udp_service.dart';
import '../utils/crypto_utils.dart';
import '../models/telemetry/telemetry_data.dart';

class TelemetryService extends ChangeNotifier {
  final UdpService _udpService = UdpService();
  TelemetryData? _currentTelemetry;
  String? _errorMessage;
  bool _isConnected = false;
  bool _isDemo = false;
  int _packetCount = 0;
  int _demoPacketId = 0;
  int _prevLap = -1;
  int _demoLap = 1;
  double _demoSpeed = 0.0;
  double _demoRPM = 1000.0;
  double _demoThrottle = 0.0;
  int _demoGear = 1;

  /// The gear the demo car was in on the previous tick. The packet is built
  /// fresh every tick, so `telemetry.currentGear` is 0 at the top of one and
  /// comparing against it - as this did first - made every tick look like a
  /// shift and held the clutch down for good.
  int _demoLastGear = 0;

  /// Seconds since the demo car last changed gear. The clutch pedal is pressed
  /// for the shift and released over about a third of a second after it, the way
  /// a driver with a clutch pedal uses it - the demo has one so that the clutch
  /// trace on the graph has something to show on a paddle-shift car.
  double _demoSinceShift = 9.0;

  /// How far the demo car's clutch is actually let in, 0..1. It follows the
  /// pedal with a lag, the way a real clutch does, so the two traces on the
  /// graph are not just mirror images of each other.
  double _demoClutchEngaged = 1.0;
  double _demoLapTime = 0.0;
  double _demoPosX = 0.0;
  double _demoPosY = 0.0;
  double _demoPosZ = 0.0;
  double _demoDistance = 0.0;
  double _demoFuel = 100.0;
  DateTime? _lapStartTime;
  Timer? _demoTimer;

  TelemetryData? get telemetry => _currentTelemetry;

  /// Which packet we are asking the console for.
  ///
  /// GT7 chooses the format from the heartbeat character, and the base packet
  /// has no steering angle or g-forces: `A` is 296 bytes, `B` adds the motion
  /// block, `C` adds more on top. The console switches on the next heartbeat,
  /// which this service sends every ten seconds and every hundred packets.
  String get packetType => _udpService.packetType;

  set packetType(String type) {
    if (!UdpService.packetTypes.contains(type)) return;
    if (_udpService.packetType == type) return;
    _udpService.packetType = type;
    notifyListeners();
  }
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;

  TelemetryService() {
    _udpService.onDataReceived = _onDataReceived;
    _udpService.onError = _onError;
  }

  /// Composes yaw about the up axis with roll about the car's long axis and
  /// pitch about its lateral axis into one unit quaternion.
  static (double, double, double, double) _quaternion({
    required double yaw,
    required double roll,
    required double pitch,
  }) {
    double cx(double a) => cos(a);
    double sx(double a) => sin(a);

    // yaw (about y) * roll (about z) * pitch (about x)
    final y1 = sx(yaw), w1 = cx(yaw);
    final z2 = sx(roll), w2 = cx(roll);
    final x3 = sx(pitch), w3 = cx(pitch);

    // Multiply (0, y1, 0, w1) * (0, 0, z2, w2) * (x3, 0, 0, w3) step by step.
    final a = (0.0, y1, 0.0, w1);
    final b = (0.0, 0.0, z2, w2);
    final c = (x3, 0.0, 0.0, w3);
    (double, double, double, double) mul(
      (double, double, double, double) p,
      (double, double, double, double) q,
    ) {
      final (px, py, pz, pw) = p;
      final (qx, qy, qz, qw) = q;
      return (
        pw * qx + px * qw + py * qz - pz * qy,
        pw * qy - px * qz + py * qw + pz * qx,
        pw * qz + px * qy - py * qx + pz * qw,
        pw * qw - px * qx - py * qy - pz * qz,
      );
    }

    return mul(mul(a, b), c);
  }

  /// The fictional circuit the demo drives around.
  static final _DemoCircuit _demoCircuit = _DemoCircuit();

  Future<void> connectToGT7(String ipAddress) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Start listening - this will automatically bind socket and send initial heartbeat
      await _udpService.startListening(ipAddress);

      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _onError('Failed to connect: $e');
    }
  }

  void _onDataReceived(Uint8List data) {
    _packetCount++;

    try {
      print('Received packet #$_packetCount, ${data.length} bytes');

      // Decrypt the data using Salsa20
      final decryptedData = CryptoUtils.decryptSalsa20(
        data,
        packetType: _udpService.packetType,
      );
      if (decryptedData == null) {
        print('Failed to decrypt packet');
        return;
      }

      print('Successfully decrypted packet, ${decryptedData.length} bytes');

      // Verify the magic number at the beginning (0x47375330)
      final magic = _bytesToInt(decryptedData, 0);
      if (magic != 0x47375330) {
        print('Invalid magic number: ${magic.toRadixString(16)}');
        return;
      }

      print('Valid magic number found');

      // Parse the telemetry data
      final newTelemetry = TelemetryData.fromBytes(decryptedData);
      print(
        'Parsed telemetry data - Packet ID: ${newTelemetry.packetId}, Speed: ${newTelemetry.speed} kph, RPM: ${newTelemetry.rpm}',
      );

      // Only update if packet ID is greater than previous (to match Python behavior)
      if (newTelemetry.packetId > (_currentTelemetry?.packetId ?? 0)) {
        print('Updating telemetry - New packet ID: ${newTelemetry.packetId}');

        // Handle lap timing.
        //
        // Packet "C" carries the live lap clock itself (0x15C), which is the
        // only honest source: the host clock drifts against the console and
        // only starts when this app noticed the lap change. Without C, fall
        // back to the host clock as before.
        if (newTelemetry.lapTimeMs > 0) {
          newTelemetry.curLapTime = newTelemetry.lapTimeMs / 1000.0;
        } else if (newTelemetry.currentLap > 0) {
          if (newTelemetry.currentLap != _prevLap) {
            _prevLap = newTelemetry.currentLap;
            _lapStartTime = DateTime.now();
          }

          if (_lapStartTime != null) {
            final duration = DateTime.now().difference(_lapStartTime!);
            newTelemetry.curLapTime = duration.inMilliseconds / 1000.0;
          }
        } else {
          newTelemetry.curLapTime = 0.0;
          _lapStartTime = null;
        }

        _currentTelemetry = newTelemetry;
        _errorMessage = null;
        notifyListeners();
      } else {
        print(
          'Packet ID ${newTelemetry.packetId} not greater than previous ${_currentTelemetry?.packetId ?? 0}, skipping update',
        );
      }
    } catch (e) {
      _onError('Error processing packet: $e');
    }
  }

  int _bytesToInt(Uint8List bytes, int offset) {
    if (offset + 4 > bytes.length) {
      throw ArgumentError('Not enough bytes for integer conversion');
    }
    return (bytes[offset] & 0xFF) |
        ((bytes[offset + 1] & 0xFF) << 8) |
        ((bytes[offset + 2] & 0xFF) << 16) |
        ((bytes[offset + 3] & 0xFF) << 24);
  }

  void _onError(String error) {
    _errorMessage = error;
    _isConnected = false;
    notifyListeners();
    print('Telemetry Service Error: $error');
  }

  bool get isDemo => _isDemo;

  Future<void> startDemoTelemetry() async {
    _errorMessage = null;
    await disconnect();

    _isDemo = true;
    _isConnected = true;
    _demoPacketId = 1;
    _demoLap = 1;
    _demoSpeed = 40.0;
    _demoRPM = 1500.0;
    _demoThrottle = 0.35;
    _demoGear = 1;
    _demoLapTime = 0.0;
    _demoPosX = 0.0;
    _demoPosY = 0.0;
    _demoPosZ = 0.0;
    _demoDistance = 0.0;
    _demoFuel = 100.0;
    _currentTelemetry = _createDemoTelemetry();

    // 10 Hz, like a real session feels on screen (the game itself sends 60 Hz;
    // the trace thins whatever rate it gets by distance).
    _demoTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      _updateDemoTelemetry,
    );
    notifyListeners();
  }

  static const double _demoStep = 0.1; // seconds between demo packets

  void _updateDemoTelemetry(Timer timer) {
    _demoPacketId++;

    // Drive the demo circuit: the speed follows the corners, the position
    // follows the distance covered, so the track map draws a real lap.
    final angle = timer.tick / 120.0;
    final target = _demoCircuit.speedAt(_demoDistance);
    _demoSpeed = (target + sin(angle) * 6).clamp(0.0, 320.0);
    _demoRPM = (1500 + _demoSpeed * 18).clamp(800.0, 9500.0);
    _demoThrottle = (_demoSpeed / 280).clamp(0.0, 1.0);
    _demoGear = _demoSpeed < 30
        ? 1
        : _demoSpeed < 70
        ? 2
        : _demoSpeed < 110
        ? 3
        : _demoSpeed < 150
        ? 4
        : _demoSpeed < 190
        ? 5
        : _demoSpeed < 240
        ? 6
        : 7;
    _demoDistance += (_demoSpeed / 3.6) * _demoStep;
    // The lap counter follows the distance on the circuit, so laps, lap times
    // and the map's lap markers all agree.
    // The demo runs a three lap race, so it wraps where a real one would end.
    final lap = (_demoDistance / _demoCircuit.length).floor() % 3 + 1;
    if (lap != _demoLap) {
      _demoLap = lap;
      _demoLapTime = 0.0;
    } else {
      _demoLapTime += _demoStep;
    }
    final position = _demoCircuit.positionAt(_demoDistance);
    // A driver never puts the car in exactly the same place twice: a small
    // per-lap offset along the track's normal makes the ghost lap a visibly
    // different line, the way it is in a real session.
    final lateral = sin(_demoLap * 2.3) * 10.0;
    final lineHeading = _demoCircuit.headingAt(_demoDistance);
    _demoPosX = position.dx - sin(lineHeading) * lateral;
    _demoPosZ = position.dy + cos(lineHeading) * lateral;
    // A little elevation, so the map and the elevation readout have something
    // to show on a track that is otherwise flat.
    _demoPosY = sin(_demoDistance / 260) * 22;
    _demoFuel = max(0.0, _demoFuel - 0.018);

    _currentTelemetry = _createDemoTelemetry();
    notifyListeners();
  }

  TelemetryData _createDemoTelemetry() {
    final telemetry = TelemetryData();
    telemetry.packetId = _demoPacketId;
    telemetry.timeOfDay = DateTime.now().millisecondsSinceEpoch;
    telemetry.currentLap = _demoLap;
    telemetry.totalLaps = 3;
    telemetry.currentPos = 1;
    telemetry.totalPositions = 20;
    telemetry.bestLapTime = 88600;
    telemetry.lastLapTime = 92351;
    telemetry.curLapTime = _demoLapTime;
    telemetry.carId = 1027; // DMC DeLorean S2 '04 - a car the catalogue knows
    // Percent, like the packet (u8 / 2.55), not a 0..1 fraction.
    final assistCut = _demoCircuit.slipAt(_demoDistance) > 0.05 ? 0.8 : 1.0;
    telemetry.throttle = (_demoThrottle * 100 * assistCut).clamp(0.0, 100.0);
    telemetry.rpm = _demoRPM;
    telemetry.speed = _demoSpeed;
    telemetry.brake = (max(0.0, 1.0 - _demoThrottle) * 100).clamp(0.0, 100.0);
    if (_demoGear != _demoLastGear) _demoSinceShift = 0.0;
    _demoLastGear = _demoGear;
    telemetry.currentGear = _demoGear;
    telemetry.suggestedGear = min(7, _demoGear + 1);
    telemetry.boost = 0.0;
    telemetry.rpmWarning = 0;
    telemetry.rpmLimiter = 0;
    telemetry.estTopSpeed = 320;
    // The clutch: fully pressed for 0.12 s at the shift, then let out over the
    // next 0.25 s. `clutchEngaged` is the pedal's complement, as in the packet.
    _demoSinceShift += 1 / 60;
    final pedal = _demoSinceShift < 0.12
        ? 1.0
        : _demoSinceShift < 0.37
        ? 1.0 - (_demoSinceShift - 0.12) / 0.25
        : 0.0;
    telemetry.clutch = pedal;
    // A first-order lag on the way back in: the pedal comes up in a step, the
    // clutch takes a moment to follow it, and the gap between the two traces is
    // exactly the slip a driver is looking at.
    _demoClutchEngaged += ((1 - pedal) - _demoClutchEngaged) * 0.22;
    telemetry.clutchEngaged = _demoClutchEngaged.clamp(0.0, 1.0);
    telemetry.rpmAfterClutch = _demoRPM * (0.35 + 0.65 * _demoClutchEngaged);
    telemetry.oilTemp = 95 + (_demoSpeed / 320) * 24;
    telemetry.waterTemp = 82 + (_demoSpeed / 320) * 8;
    telemetry.oilPressure = 3.7;
    telemetry.rideHeight = 42.0;
    telemetry.tireTempFL = 68 + (_demoSpeed / 320) * 26;
    telemetry.tireTempFR = 69 + (_demoSpeed / 320) * 25;
    telemetry.tireTempRL = 67 + (_demoSpeed / 320) * 27;
    telemetry.tireTempRR = 68 + (_demoSpeed / 320) * 26;
    telemetry.tireDiamFL = 64.0;
    telemetry.tireDiamFR = 64.0;
    telemetry.tireDiamRL = 64.0;
    telemetry.tireDiamRR = 64.0;
    telemetry.tireSpeedFL = (_demoSpeed * 0.98).abs();
    telemetry.tireSpeedFR = (_demoSpeed * 0.99).abs();
    telemetry.tireSpeedRL = (_demoSpeed * 0.97).abs();
    telemetry.tireSpeedRR = (_demoSpeed * 0.96).abs();
    telemetry.tireSlipRatioFL = _demoSpeed > 0
        ? (telemetry.tireSpeedFL / _demoSpeed).toStringAsFixed(2)
        : '  –  ';
    telemetry.tireSlipRatioFR = _demoSpeed > 0
        ? (telemetry.tireSpeedFR / _demoSpeed).toStringAsFixed(2)
        : '  –  ';
    telemetry.tireSlipRatioRL = _demoSpeed > 0
        ? (telemetry.tireSpeedRL / _demoSpeed).toStringAsFixed(2)
        : '  –  ';
    telemetry.tireSlipRatioRR = _demoSpeed > 0
        ? (telemetry.tireSpeedRR / _demoSpeed).toStringAsFixed(2)
        : '  –  ';
    telemetry.suspensionFL = 3.4;
    telemetry.suspensionFR = 3.4;
    telemetry.suspensionRL = 3.5;
    telemetry.suspensionRR = 3.5;
    telemetry.gear1 = _demoGear == 1 ? 1.0 : 0.0;
    telemetry.gear2 = _demoGear == 2 ? 1.0 : 0.0;
    telemetry.gear3 = _demoGear == 3 ? 1.0 : 0.0;
    telemetry.gear4 = _demoGear == 4 ? 1.0 : 0.0;
    telemetry.gear5 = _demoGear == 5 ? 1.0 : 0.0;
    telemetry.gear6 = _demoGear == 6 ? 1.0 : 0.0;
    telemetry.gear7 = _demoGear == 7 ? 1.0 : 0.0;
    telemetry.gear8 = 0.0;
    telemetry.transmissionTopSpeed = 0.0;
    telemetry.posX = _demoPosX;
    telemetry.posY = _demoPosY;
    telemetry.posZ = _demoPosZ;
    final heading = _demoCircuit.headingAt(_demoDistance);
    // Velocity is where the car is *going*; the yaw is where it *points*. They
    // only differ in the drift window, which is the whole point of the drift
    // readout - and it means the demo exercises the same slip-angle fit a real
    // session does.
    final slip = _demoCircuit.slipAt(_demoDistance);
    final curvature = _demoCircuit.curvatureAt(_demoDistance);
    final speedMs = _demoSpeed / 3.6;
    telemetry.velX = cos(heading) * (_demoSpeed / 3.6);
    telemetry.velZ = sin(heading) * (_demoSpeed / 3.6);
    telemetry.velY = 0.0;

    // Motion block: the demo answers the heartbeat "B" the way a console does,
    // so the steering and g readouts have something real to show. Steering is
    // the wheel angle that follows the corner, the accelerations come from the
    // same curvature the speed does.
    telemetry.packetType = 'C';
    telemetry.steeringAngle = (atan(curvature * 2.6) * 2.6).clamp(-2.4, 2.4);
    telemetry.steeringRate = curvature * speedMs * 0.8;
    // A race car peaks around two and a half g sideways, so the demo is capped
    // there: driving the synthetic circuit at its own corner speeds can
    // otherwise ask for five, which would only ever pin the ball to the rim.
    telemetry.sway =
        (curvature * speedMs * speedMs + slip * 9.0).clamp(-24.5, 24.5);

    // Extended block ("~") and the car's own geometry ("C"), the way a console
    // answering heartbeat "C" sends them.
    // Raw (pre-TCS) inputs: the demo car asks for full throttle out of the
    // corner and the assistance takes a fifth of it away while it is sliding,
    // which is what the TCS chip reads.
    telemetry.throttleFiltered = (_demoThrottle * 255).clamp(0, 255);
    telemetry.brakeFiltered = (telemetry.brake * 255 / 100).clamp(0, 255);
    telemetry.torqueVectors = const [0, 0, 0, 0];
    telemetry.energyRecovery = 0.0;
    // Tarmac everywhere except through the slide, where the car clips the kerb
    // and puts two wheels on the grass.
    // Running wide on the outside of a corner: the front-right clips the kerb
    // and the rear-right is already on the grass. The two left wheels are still
    // on tarmac, which is the point - the car shows one surface per wheel.
    telemetry.surfaceTypes = slip > 0.05 ? 'TCGT' : 'TTTT';
    telemetry.lapTimeMs = (_demoLapTime * 1000).round();
    // Ackermann: the inner wheel turns sharper than the outer one, and which
    // one is inner depends on the way the corner goes.
    final turningLeft = curvature > 0;
    final spread = telemetry.steeringAngle.abs() * 0.18;
    telemetry.frontWheelAngleLeft =
        telemetry.steeringAngle + (turningLeft ? spread : -spread);
    telemetry.frontWheelAngleRight =
        telemetry.steeringAngle + (turningLeft ? -spread : spread);
    telemetry.leftWheelbaseMeters = 2.6;
    telemetry.carCategory = 'GRN';
    telemetry.heave = sin(_demoDistance / 90) * 1.5;
    telemetry.surge = (cos(_demoDistance / 130) * 3.5).clamp(-9.8, 9.8);

    // Rotation block: PDTools and the community packet spreadsheet read
    // 0x1C..0x2B as a *unit quaternion*, so the demo sends one - a pure yaw of
    // the body angle, which is what a car on a flat track mostly has. The app
    // detects this by checking the length and then uses the exact angle.
    telemetry.rotPitch = 0.0; // quaternion x
    // The nose points *into* the corner the car is sliding through, so the
    // body leads the direction of travel by the slip angle, on the same side
    // as the corner turns.
    final intoCorner = curvature == 0 ? 1.0 : (curvature > 0 ? -1.0 : 1.0);
    final bodyAngle = heading + intoCorner * slip;
    // A car leans out of the corner and pitches under braking: fold those two
    // angles into the same quaternion, so the attitude readout and the load
    // dial show the body moving rather than a car frozen flat.
    final lateralG = curvature * speedMs * speedMs / 9.80665 + slip * 1.4;
    final longitudinalG = telemetry.surge / 9.80665;
    final roll = -lateralG * 0.035;
    final pitch = longitudinalG * 0.03;

    final q = _quaternion(
      yaw: -bodyAngle / 2,
      roll: roll / 2,
      pitch: pitch / 2,
    );
    telemetry.rotPitch = q.$1; // quaternion x
    telemetry.rotYaw = q.$2; // quaternion y
    telemetry.rotRoll = q.$3; // quaternion z
    telemetry.headingNorth = q.$4; // quaternion w

    telemetry.angVelX = 0.0;
    telemetry.angVelY = 0.0;
    telemetry.angVelZ = 0.0;
    telemetry.fuel = _demoFuel;
    telemetry.maxFuel = 100.0;
    telemetry.isEV = false;
    telemetry.flags8E = 0;
    telemetry.flags8F = 0;
    telemetry.flags93 = 0;
    // The demo track is flat, so the road plane is straight up.
    telemetry.roadPlaneX = 0.0;
    telemetry.roadPlaneY = 1.0;
    telemetry.roadPlaneZ = 0.0;
    telemetry.roadPlaneDistance = 0.0;
    telemetry.floatD4 = 0.0;
    telemetry.floatD8 = 0.0;
    telemetry.floatDC = 0.0;
    telemetry.floatE0 = 0.0;
    telemetry.floatE4 = 0.0;
    telemetry.floatE8 = 0.0;
    telemetry.floatEC = 0.0;
    telemetry.floatF0 = 0.0;
    return telemetry;
  }

  Future<void> disconnect() async {
    _demoTimer?.cancel();
    _demoTimer = null;
    _isDemo = false;
    await _udpService.stopListening();
    _isConnected = false;
    _currentTelemetry = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// A closed circuit for the demo session: a loop of straight and corners the
/// demo car drives around, so the track map, the speed colours and the lap
/// counting all have something real to show without a PlayStation.
///
/// This is a stand-in for the coordinates GT7 sends - the real packet carries
/// its own position every frame, and nothing here is used then.
class _DemoCircuit {
  _DemoCircuit() {
    _build();
  }

  /// Control points of the loop, in metres.
  static const List<Offset> _control = [
    Offset(0, 0),
    Offset(300, -40),
    Offset(520, -170),
    Offset(600, -370),
    Offset(540, -560),
    Offset(370, -690),
    Offset(140, -700),
    Offset(-30, -600),
    Offset(-70, -430),
    Offset(-180, -300),
    Offset(-350, -250),
    Offset(-430, -80),
    Offset(-330, 90),
    Offset(-150, 150),
    Offset(-40, 90),
  ];

  final List<Offset> _points = [];
  final List<double> _cumulative = [];
  final List<double> _speed = [];
  final List<double> _tangent = [];

  double _length = 1;

  /// Lap length in metres.
  double get length => _length;

  /// Position on the loop [distance] metres from the start line.
  Offset positionAt(double distance) {
    final d = distance % _length;
    var i = _indexAt(d);
    final segment = _cumulative[i + 1] - _cumulative[i];
    final t = segment <= 0 ? 0.0 : (d - _cumulative[i]) / segment;
    final a = _points[i];
    // The last segment closes the loop, so the second point wraps around.
    final b = _points[(i + 1) % _points.length];
    return Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
  }

  /// Direction of travel at [distance], in radians (X/Z plane).
  ///
  /// The loop is a polyline, so a segment's direction is constant for sixteen
  /// metres: a heading taken from it would step at every vertex while the car
  /// moves smoothly, and the slip-angle fit (which compares a change in heading
  /// with a change in the direction of travel) would see noise. The tangents
  /// are pre-smoothed per vertex and blended along the segment instead, which
  /// is what a real console's continuous yaw looks like.
  double headingAt(double distance) {
    final d = distance % _length;
    final i = _indexAt(d);
    final j = (i + 1) % _points.length;
    final segment = _cumulative[i + 1] - _cumulative[i];
    final t = segment <= 0 ? 0.0 : (d - _cumulative[i]) / segment;

    // Blend as unit vectors: averaging angles directly would wrap badly.
    final x = cos(_tangent[i]) * (1 - t) + cos(_tangent[j]) * t;
    final y = sin(_tangent[i]) * (1 - t) + sin(_tangent[j]) * t;
    return atan2(y, x);
  }

  /// Speed the demo car should be doing, in km/h: corner speed where the loop
  /// turns, top speed where it does not.
  double speedAt(double distance) => _speed[_indexAt(distance % _length)];

  /// Slip angle in radians the demo car carries at [distance]: it kicks the
  /// tail out through one corner so the drift readout has something to show.
  /// Positive means the body points to the left of the direction of travel.
  double slipAt(double distance) {
    final fraction = (distance % _length) / _length;
    const start = 0.42;
    const end = 0.52;
    if (fraction < start || fraction > end) return 0;
    // Ramp in, peak in the middle, ramp out - like catching a slide.
    final t = (fraction - start) / (end - start);
    return sin(t * pi) * 0.5;
  }

  /// Signed curvature (1/m, positive when the loop turns left) at [distance].
  /// The demo feeds it into steering angle and lateral g, so the motion page
  /// moves like the car it pretends to be.
  double curvatureAt(double distance) {
    final i = _indexAt(distance % _length);
    final prev = _points[(i - 1 + _points.length) % _points.length];
    final here = _points[i];
    final next = _points[(i + 1) % _points.length];
    final a = atan2(here.dy - prev.dy, here.dx - prev.dx);
    final b = atan2(next.dy - here.dy, next.dx - here.dx);
    var turn = b - a;
    while (turn > pi) {
      turn -= 2 * pi;
    }
    while (turn < -pi) {
      turn += 2 * pi;
    }
    final arc = ((here - prev).distance + (next - here).distance) / 2;
    return arc <= 0 ? 0 : turn / arc;
  }

  int _indexAt(double distance) {
    var low = 0;
    var high = _cumulative.length - 1;
    while (low < high - 1) {
      final mid = (low + high) ~/ 2;
      if (_cumulative[mid] <= distance) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }

  void _build() {
    // Catmull-Rom through the control points, sampled every ~4 metres.
    for (var i = 0; i < _control.length; i++) {
      final p0 = _control[(i - 1 + _control.length) % _control.length];
      final p1 = _control[i];
      final p2 = _control[(i + 1) % _control.length];
      final p3 = _control[(i + 2) % _control.length];
      for (var step = 0; step < 12; step++) {
        final t = step / 12;
        _points.add(_catmullRom(p0, p1, p2, p3, t));
      }
    }

    _cumulative.add(0);
    for (var i = 1; i <= _points.length; i++) {
      final a = _points[i - 1];
      final b = _points[i % _points.length];
      _cumulative.add(_cumulative[i - 1] + (b - a).distance);
    }
    _length = _cumulative.last;

    // Central difference at every vertex: the smooth tangent of the loop.
    for (var i = 0; i < _points.length; i++) {
      final prev = _points[(i - 1 + _points.length) % _points.length];
      final next = _points[(i + 1) % _points.length];
      _tangent.add(atan2(next.dy - prev.dy, next.dx - prev.dx));
    }

    // Corner speed from the local curvature: v = sqrt(a_lat / k), with the
    // result smoothed so the demo speed does not flicker.
    const lateral = 11.0;
    final raw = <double>[];
    for (var i = 0; i < _points.length; i++) {
      final prev = _points[(i - 1 + _points.length) % _points.length];
      final next = _points[(i + 1) % _points.length];
      final turn = (atan2(next.dy - _points[i].dy, next.dx - _points[i].dx) -
              atan2(_points[i].dy - prev.dy, _points[i].dx - prev.dx))
          .abs();
      final arc = ((_points[i] - prev).distance + (next - _points[i]).distance) /
          2;
      final curvature = arc <= 0 ? 0.0 : turn / arc;
      final v = curvature <= 0.0001
          ? 340.0
          : sqrt(lateral / curvature) * 3.6;
      raw.add(v.clamp(70.0, 300.0));
    }
    for (var i = 0; i < raw.length; i++) {
      var sum = 0.0;
      for (var k = -6; k <= 6; k++) {
        sum += raw[(i + k + raw.length) % raw.length];
      }
      _speed.add(sum / 13);
    }
  }

  static Offset _catmullRom(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    double axis(double a, double b, double c, double d) =>
        0.5 *
        ((2 * b) +
            (-a + c) * t +
            (2 * a - 5 * b + 4 * c - d) * t2 +
            (-a + 3 * b - 3 * c + d) * t3);
    return Offset(
      axis(p0.dx, p1.dx, p2.dx, p3.dx),
      axis(p0.dy, p1.dy, p2.dy, p3.dy),
    );
  }
}
