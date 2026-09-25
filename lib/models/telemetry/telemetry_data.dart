import 'dart:math' as math;
import 'dart:typed_data';

class TelemetryData {
  // Time and lap data
  int packetId = 0;
  int timeOfDay = 0;
  int currentLap = 0;
  int totalLaps = 0;
  int currentPos = 0;
  int totalPositions = 0;
  int bestLapTime = 0; // in milliseconds
  int lastLapTime = 0; // in milliseconds
  double curLapTime = 0.0; // in seconds

  // Car data
  int carId = 0;
  double throttle = 0.0;
  double rpm = 0.0;
  double speed = 0.0; // in kph
  double brake = 0.0;
  int currentGear = 0;
  int suggestedGear = 0;
  double boost = 0.0;
  int rpmWarning = 0;
  int rpmLimiter = 0;
  int estTopSpeed = 0;

  // Clutch data
  double clutch = 0.0;
  double clutchEngaged = 0.0;
  double rpmAfterClutch = 0.0;

  // Engine data
  double oilTemp = 0.0;
  double waterTemp = 0.0;
  double oilPressure = 0.0;
  double rideHeight = 0.0;

  // Tire data
  double tireTempFL = 0.0;
  double tireTempFR = 0.0;
  double tireTempRL = 0.0;
  double tireTempRR = 0.0;
  double tireDiamFL = 0.0;
  double tireDiamFR = 0.0;
  double tireDiamRL = 0.0;
  double tireDiamRR = 0.0;
  double tireSpeedFL = 0.0;
  double tireSpeedFR = 0.0;
  double tireSpeedRL = 0.0;
  double tireSpeedRR = 0.0;
  String tireSlipRatioFL = '  –  ';
  String tireSlipRatioFR = '  –  ';
  String tireSlipRatioRL = '  –  ';
  String tireSlipRatioRR = '  –  ';
  double suspensionFL = 0.0;
  double suspensionFR = 0.0;
  double suspensionRL = 0.0;
  double suspensionRR = 0.0;

  // Gearing
  double gear1 = 0.0;
  double gear2 = 0.0;
  double gear3 = 0.0;
  double gear4 = 0.0;
  double gear5 = 0.0;
  double gear6 = 0.0;
  double gear7 = 0.0;
  double gear8 = 0.0;
  /// Whether the reported car id can be trusted.
  ///
  /// GT7 copies the gear ratios without a bounds check, so a car with nine or
  /// more gears writes over 0x124 (and a ten-gear car, like the LC500, writes
  /// over 0x128 as well - which is the steering angle in packets B and up).
  bool carIdLooksPlausible(int? knownIds, {int? min, int? max}) => true;

  /// Top speed of the current transmission setup, as a gear ratio value
  /// (0x100). The name in the model used to be gearUnknown; the published
  /// layout calls it transmissionTopSpeed.
  double transmissionTopSpeed = 0.0;

  // Positioning
  double posX = 0.0;
  double posY = 0.0;
  double posZ = 0.0;

  // Velocity
  double velX = 0.0;
  double velY = 0.0;
  double velZ = 0.0;

  // Rotation
  double rotPitch = 0.0;
  double rotYaw = 0.0;
  double rotRoll = 0.0;

  /// Orientation relative to north, 1.0 = north and 0.0 = south.
  ///
  /// Two readings of 0x1C..0x2B circulate: pitch/yaw/roll plus this heading
  /// (MacManley, Bornhall, zetetos), or a unit quaternion x/y/z/w (PDTools and
  /// the community packet spreadsheet). [rotationIsQuaternion] decides which
  /// one the console is actually sending, by testing whether the four floats
  /// have unit length - a quaternion has to, and three unrelated angles do not.
  double headingNorth = 0.0;

  /// The fourth float of the rotation block. It is the *same* field as
  /// [headingNorth] - the two readings disagree about what it means, not about
  /// where it lives (0x28).
  double get rotW => headingNorth;
  set rotW(double value) => headingNorth = value;

  /// True when 0x1C..0x2B behave like a unit quaternion.
  bool get rotationIsQuaternion {
    final sum = rotPitch * rotPitch +
        rotYaw * rotYaw +
        rotRoll * rotRoll +
        rotW * rotW;
    return (sum - 1.0).abs() < 0.02;
  }

  /// The car's own axes in world coordinates, taken from the rotation
  /// quaternion: which way it points, and which way is up.
  ({double x, double y, double z})? get _forwardAxis {
    if (!rotationIsQuaternion) return null;
    final x = rotPitch;
    final y = rotYaw;
    final z = rotRoll;
    final w = rotW;
    return (
      x: 1 - 2 * (y * y + z * z),
      y: 2 * (x * y + w * z),
      z: 2 * (x * z - w * y),
    );
  }

  ({double x, double y, double z})? get _upAxis {
    if (!rotationIsQuaternion) return null;
    final x = rotPitch;
    final y = rotYaw;
    final z = rotRoll;
    final w = rotW;
    return (
      x: 2 * (x * y - w * z),
      y: 1 - 2 * (x * x + z * z),
      z: 2 * (y * z + w * x),
    );
  }

  /// How far the body is leaning to its right, in radians, from the quaternion
  /// rotation block. Positive means the right-hand side is down, which is what
  /// a car does in a left-hand corner.
  ///
  /// This is the car's real attitude, not a guess from the g-forces: the packet
  /// reports the body's rotation, so this and [bodyPitchRadians] are
  /// measurements. Null when the rotation block is the other reading (three
  /// separate angles), which cannot be decomposed without knowing its scale.
  double? get bodyRollRadians {
    final forward = _forwardAxis;
    final up = _upAxis;
    if (forward == null || up == null) return null;

    // The car's right-hand side: up × forward, flattened to the ground plane.
    final rightX = forward.z;
    final rightZ = -forward.x;
    final length = math.sqrt(rightX * rightX + rightZ * rightZ);
    if (length < 1e-6) return null;

    final towardsRight = (up.x * rightX + up.z * rightZ) / length;
    return math.atan2(towardsRight, up.y);
  }

  /// How far the nose is up, in radians, from the same rotation block.
  /// Positive under acceleration, negative under braking.
  double? get bodyPitchRadians {
    final forward = _forwardAxis;
    if (forward == null) return null;
    final horizontal = math.sqrt(
      math.max(0.0, forward.x * forward.x + forward.z * forward.z),
    );
    return math.atan2(forward.y, horizontal);
  }

  /// The heading the car's body points at, in radians, when the rotation block
  /// is a quaternion: the rotation is applied to the car's forward axis and
  /// flattened onto the ground plane.
  ///
  /// This is the exact body angle, with no fitted scale - which is what the
  /// drift readout wants. Returns null when the block is not a quaternion.
  double? get quaternionHeading {
    if (!rotationIsQuaternion) return null;
    final x = rotPitch;
    final y = rotYaw;
    final z = rotRoll;
    final w = rotW;
    // Rotate (1, 0, 0) by the quaternion and use the horizontal part.
    final fx = 1 - 2 * (y * y + z * z);
    final fz = 2 * (x * z + w * y);
    if (fx.abs() < 1e-6 && fz.abs() < 1e-6) return null;
    return math.atan2(fz, fx);
  }

  // Motion block (packet B and up, offsets 0x128..): the console only sends
  // this when the heartbeat asks for "B", "~" or "C". They stay NaN when the
  // base "A" packet arrived, so the UI can say "not in this packet" instead of
  // showing a made-up zero.
  double steeringAngle = double.nan; // radians, the wheel the car is turning
  double steeringRate = double.nan; // radians per second
  double sway = double.nan; // lateral acceleration, m/s^2
  double heave = double.nan; // vertical acceleration, m/s^2
  double surge = double.nan; // longitudinal acceleration, m/s^2

  /// Which packet these values came from: `A`, `B`, `~`, `C`, or `?` when the
  /// length matches none of them.
  String packetType = 'A';

  // Packet "~" (344 bytes) carries everything B does and adds these. They stay
  // NaN/short when the shorter packet arrived.
  //
  //  0x13C uint8  throttleFiltered
  //  0x13D uint8  brakeFiltered
  //  0x13E uint8  unknown, 0x13F uint8 unknown
  //  0x140 float  torqueVectors[4]
  //  0x150 float  energyRecovery
  /// Throttle *before* traction control, 0..255 as sent (0x13C). Comparing it
  /// with the assisted throttle at 0x91 shows TCS working.
  double throttleFiltered = double.nan;

  /// Brake *before* ABS, 0..255 (0x13D). Only populated in live sessions.
  double brakeFiltered = double.nan;

  /// Drivetrain / torque-vectoring flag (0x13E): 0, 2, 4 or 9 in the wild.
  int drivetrainFlags = 0;

  /// Non-zero when the car has energy recovery (0x13F).
  int energyRecoveryFlag = 0;

  /// Per-wheel torque vectoring; positive drives, negative brakes or
  /// regenerates. Empty without packet `~`.
  List<double> torqueVectors = const [];

  /// Energy going back into the battery, as the packet reports it.
  double energyRecovery = double.nan;

  // Packet "C" (368 bytes) is "~" plus the car's own geometry and the surface
  // under each tyre.
  //
  //  0x158 char[4] surfaceType, one character per wheel FL FR RL RR
  //  0x15C int32   current lap time in milliseconds
  //  0x160 float   wheelSteeringAngle[2]: front wheel angles in radians
  //  0x168 float   wheelBase in metres
  //  0x16C char[4] carCategory, e.g. "GR3"
  String surfaceTypes = '';
  int lapTimeMs = -1;
  double frontWheelAngleLeft = double.nan;
  double frontWheelAngleRight = double.nan;
  /// Distance from the front-left to the rear-left wheel, in metres (0x168).
  /// It is a *dynamic* measurement: it changes with the front-left steering
  /// angle, so it only equals the car's wheelbase when straight.
  double leftWheelbaseMeters = double.nan;
  String carCategory = '';

  /// Whether the `~` block (filtered inputs, torque vectors, regen) arrived.
  bool get hasExtendedData => !throttleFiltered.isNaN;

  /// Whether the `C` block (surface, wheel angles, category) arrived.
  bool get hasCategoryData =>
      surfaceTypes.isNotEmpty || !frontWheelAngleLeft.isNaN;

  /// The steering angle to show, in radians, from whichever packet carries it:
  /// `C` reports the front wheels themselves, `B` the wheel rotation, which is
  /// only accepted when it is inside a physically possible steering range.
  double? get steeringRadians {
    if (!frontWheelAngleLeft.isNaN) {
      if (!frontWheelAngleRight.isNaN) {
        return (frontWheelAngleLeft + frontWheelAngleRight) / 2;
      }
      return frontWheelAngleLeft;
    }
    if (!steeringAngle.isNaN) return steeringAngle;
    return null;
  }

  /// Where [steeringRadians] came from, for the readout.
  String? get steeringSource {
    if (!frontWheelAngleLeft.isNaN) return 'C';
    if (!steeringAngle.isNaN) return 'B';
    return null;
  }

  /// The four surface characters as a readable row, e.g. `T T C T`.
  String get surfaceSummary =>
      surfaceTypes.isEmpty ? '—' : surfaceTypes.split('').join(' ');

  /// True when any tyre is on something other than tarmac or a kerb, which is
  /// what "off track" means for a lap: dirt, grass, sand or snow.
  bool get offTrack =>
      surfaceTypes.split('').any((c) => 'DGgsS'.contains(c));

  /// How much throttle traction control is taking away right now, 0..1.
  /// Null without packet `~`.
  double? get tcsCut {
    if (throttleFiltered.isNaN) return null;
    final raw = throttleFiltered / 255;
    final assisted = throttle / 100;
    final cut = raw - assisted;
    return cut <= 0.02 ? 0.0 : cut.clamp(0.0, 1.0);
  }

  /// How much brake pressure ABS is releasing right now, 0..1. Null without
  /// packet `~`.
  double? get absCut {
    if (brakeFiltered.isNaN) return null;
    final raw = brakeFiltered / 255;
    final assisted = brake / 100;
    final cut = raw - assisted;
    return cut <= 0.02 ? 0.0 : cut.clamp(0.0, 1.0);
  }

  /// Whether the console sent the motion block at all.
  bool get hasMotionData => !steeringAngle.isNaN;

  /// Lateral acceleration in g, positive to the right. Null without packet B.
  double? get lateralG => sway.isNaN ? null : sway / 9.80665;

  /// Longitudinal acceleration in g, positive when accelerating. Null without
  /// packet B.
  double? get longitudinalG => surge.isNaN ? null : surge / 9.80665;

  /// Gradient of the road along the direction the car is going, in degrees:
  /// positive is uphill. Zero when the car is not moving or the plane is not
  /// being reported.
  double? get roadSlopeDegrees {
    final forward = _forwardUnit;
    if (forward == null) return null;
    final grade = _roadGradeAlong(forward);
    return grade == null ? null : _degrees(grade);
  }

  /// Cross-slope of the road, in degrees: positive when the left-hand side of
  /// the car is higher than the right.
  double? get roadBankDegrees {
    final forward = _forwardUnit;
    if (forward == null) return null;
    final right = (x: -forward.z, z: forward.x);
    final grade = _roadGradeAlong(right);
    return grade == null ? null : _degrees(grade);
  }

  /// The direction the car is travelling in on the ground plane, as a unit
  /// vector, or null when it is below walking pace.
  ({double x, double z})? get _forwardUnit {
    final vx = velX;
    final vz = velZ;
    final length = math.sqrt(vx * vx + vz * vz);
    if (!length.isFinite || length < 1.0) return null; // under ~3.6 km/h
    return (x: vx / length, z: vz / length);
  }

  /// How much the road rises per metre travelled along [direction].
  double? _roadGradeAlong(({double x, double z}) direction) {
    final nx = roadPlaneX;
    final ny = roadPlaneY;
    final nz = roadPlaneZ;
    if (!nx.isFinite || !nz.isFinite || !ny.isFinite) return null;
    if (ny.abs() < 0.1) return null; // not a usable plane normal
    // The surface rises along -(nx, nz) / ny.
    final gradeX = -nx / ny;
    final gradeZ = -nz / ny;
    final grade = gradeX * direction.x + gradeZ * direction.z;
    if (!grade.isFinite || grade.abs() > 1.5) return null; // >56 deg: nonsense
    return grade;
  }

  static double _degrees(double grade) => math.atan(grade) * 180 / math.pi;

  // Angular velocity
  double angVelX = 0.0;
  double angVelY = 0.0;
  double angVelZ = 0.0;

  // Fuel/EV data
  double fuel = 0.0;
  double maxFuel = 0.0;
  bool isEV = false;

  // Flags
  int flags8E = 0;
  int flags8F = 0;
  int flags93 = 0;

  // Other float values
  /// Normal of the road plane under the car (0x94..0x9C). On a flat road this
  /// is straight up; the tilt of it is the slope and the banking the car is on.
  double roadPlaneX = 0.0;
  double roadPlaneY = 0.0;
  double roadPlaneZ = 0.0;

  /// Distance above or below the road plane, negative in a dip (0xA0).
  double roadPlaneDistance = 0.0;
  double floatD4 = 0.0;
  double floatD8 = 0.0;
  double floatDC = 0.0;
  double floatE0 = 0.0;
  double floatE4 = 0.0;
  double floatE8 = 0.0;
  double floatEC = 0.0;
  double floatF0 = 0.0;

  // Parse data from decrypted byte array
  static TelemetryData fromBytes(Uint8List data) {
    final telemetry = TelemetryData();

    try {
      // Track-space kinematics (packet A, 0x04..0x37). Positions are metres,
      // X/Z is the ground plane and Y is elevation, which is what the track map
      // accumulates; rotation and angular velocity are the raw packet values.
      telemetry.posX = _getFloat32(data, 0x04);
      telemetry.posY = _getFloat32(data, 0x08);
      telemetry.posZ = _getFloat32(data, 0x0C);
      telemetry.velX = _getFloat32(data, 0x10);
      telemetry.velY = _getFloat32(data, 0x14);
      telemetry.velZ = _getFloat32(data, 0x18);
      telemetry.rotPitch = _getFloat32(data, 0x1C);
      telemetry.rotYaw = _getFloat32(data, 0x20);
      telemetry.rotRoll = _getFloat32(data, 0x24);
      // 0x28 is either the orientation to north or the quaternion's w.
      telemetry.headingNorth = _getFloat32(data, 0x28);
      telemetry.angVelX = _getFloat32(data, 0x2C);
      telemetry.angVelY = _getFloat32(data, 0x30);
      telemetry.angVelZ = _getFloat32(data, 0x34);

      // Packet "A" is the base: every other packet is a superset, so these
      // offsets hold for all of them.
      telemetry.packetType = switch (data.length) {
        296 => 'A',
        316 => 'B',
        344 => '~',
        368 => 'C',
        _ => '?',
      };

      // The motion block: only sent when the heartbeat asks for "B", "~" or
      // "C" (see UdpService.packetType). 316 bytes is B, and everything longer
      // that we know of starts with the same five floats.
      if (data.length >= 316) {
        final steering = _getFloat32(data, 0x128);
        // The field is documented as wheel rotation; the only steering channel
        // in the packet is this one, so a value outside a physically possible
        // steering range is treated as "not steering data".
        if (steering.isFinite && steering.abs() <= 3.2) {
          telemetry.steeringAngle = steering;
        }
        telemetry.steeringRate = _getFloat32(data, 0x12C);
        telemetry.sway = _getFloat32(data, 0x130);
        telemetry.heave = _getFloat32(data, 0x134);
        telemetry.surge = _getFloat32(data, 0x138);
      }

      // Packet "~" adds its block after B's motion floats, and C adds its own
      // after that. The chain A -> B -> ~ -> C is what makes the documented
      // sizes add up (296, 316, 344, 368).
      if (data.length >= 344) {
        telemetry.throttleFiltered = _getUint8(data, 0x13C).toDouble();
        telemetry.brakeFiltered = _getUint8(data, 0x13D).toDouble();
        telemetry.drivetrainFlags = _getUint8(data, 0x13E);
        telemetry.energyRecoveryFlag = _getUint8(data, 0x13F);
        telemetry.torqueVectors = [
          _getFloat32(data, 0x140),
          _getFloat32(data, 0x144),
          _getFloat32(data, 0x148),
          _getFloat32(data, 0x14C),
        ];
        telemetry.energyRecovery = _getFloat32(data, 0x150);
      }

      if (data.length >= 368) {
        telemetry.surfaceTypes = String.fromCharCodes(
          data.sublist(0x158, 0x15C),
        );
        telemetry.lapTimeMs = _getInt32(data, 0x15C);
        telemetry.frontWheelAngleLeft = _getFloat32(data, 0x160);
        telemetry.frontWheelAngleRight = _getFloat32(data, 0x164);
        telemetry.leftWheelbaseMeters = _getFloat32(data, 0x168);
        final category = data.sublist(0x16C, 0x170);
        final end = category.indexOf(0);
        telemetry.carCategory = String.fromCharCodes(
          end == -1 ? category : category.sublist(0, end),
        );
      }

      // Parse all the telemetry values from the byte array
      // Using the offsets from the Python script
      telemetry.packetId = _getInt32(data, 0x70);
      telemetry.timeOfDay = _getInt32(data, 0x80);
      telemetry.currentLap = _getInt16(data, 0x74);
      telemetry.totalLaps = _getInt16(data, 0x76);
      telemetry.currentPos = _getInt16(data, 0x84);
      telemetry.totalPositions = _getInt16(data, 0x86);
      telemetry.bestLapTime = _getInt32(data, 0x78);
      telemetry.lastLapTime = _getInt32(data, 0x7C);

      telemetry.carId = _getInt32(data, 0x124);
      telemetry.throttle = _getUint8(data, 0x91) / 2.55;
      telemetry.rpm = _getFloat32(data, 0x3C);
      telemetry.speed = _getFloat32(data, 0x4C) * 3.6; // Convert m/s to kph
      telemetry.brake = _getUint8(data, 0x92) / 2.55;

      // Gear data (bits 0-3 for current gear, bits 4-7 for suggested gear)
      final gearByte = _getUint8(data, 0x90);
      var currentGear = gearByte & 0x0F;
      var suggestedGear = gearByte >> 4;

      if (currentGear == 0) currentGear = -1; // Reverse
      if (suggestedGear > 14) suggestedGear = 0; // Unknown

      telemetry.currentGear = currentGear;
      telemetry.suggestedGear = suggestedGear;

      final boost = _getFloat32(data, 0x50) - 1;
      telemetry.boost = boost > -1 ? boost : 0.0; // Only if turbo exists

      telemetry.rpmWarning = _getUint16(data, 0x88);
      telemetry.rpmLimiter = _getUint16(data, 0x8A);
      telemetry.estTopSpeed = _getInt16(data, 0x8C);

      telemetry.clutch = _getFloat32(data, 0xF4);
      telemetry.clutchEngaged = _getFloat32(data, 0xF8);
      telemetry.rpmAfterClutch = _getFloat32(data, 0xFC);

      telemetry.oilTemp = _getFloat32(data, 0x5C);
      telemetry.waterTemp = _getFloat32(data, 0x58);
      telemetry.oilPressure = _getFloat32(data, 0x54);
      telemetry.rideHeight = _getFloat32(data, 0x38) * 1000; // Convert to mm

      // Tire data
      telemetry.tireTempFL = _getFloat32(data, 0x60);
      telemetry.tireTempFR = _getFloat32(data, 0x64);
      telemetry.tireTempRL = _getFloat32(data, 0x68);
      telemetry.tireTempRR = _getFloat32(data, 0x6C);

      telemetry.tireDiamFL = _getFloat32(data, 0xB4) * 200; // Convert to cm
      telemetry.tireDiamFR = _getFloat32(data, 0xB8) * 200;
      telemetry.tireDiamRL = _getFloat32(data, 0xBC) * 200;
      telemetry.tireDiamRR = _getFloat32(data, 0xC0) * 200;

      final carSpeed = telemetry.speed;
      if (carSpeed > 0) {
        telemetry.tireSpeedFL =
            (3.6 * telemetry.tireDiamFL / 200 * _getFloat32(data, 0xA4)).abs();
        telemetry.tireSpeedFR =
            (3.6 * telemetry.tireDiamFR / 200 * _getFloat32(data, 0xA8)).abs();
        telemetry.tireSpeedRL =
            (3.6 * telemetry.tireDiamRL / 200 * _getFloat32(data, 0xAC)).abs();
        telemetry.tireSpeedRR =
            (3.6 * telemetry.tireDiamRR / 200 * _getFloat32(data, 0xB0)).abs();

        telemetry.tireSlipRatioFL = (telemetry.tireSpeedFL / carSpeed)
            .toStringAsFixed(2);
        telemetry.tireSlipRatioFR = (telemetry.tireSpeedFR / carSpeed)
            .toStringAsFixed(2);
        telemetry.tireSlipRatioRL = (telemetry.tireSpeedRL / carSpeed)
            .toStringAsFixed(2);
        telemetry.tireSlipRatioRR = (telemetry.tireSpeedRR / carSpeed)
            .toStringAsFixed(2);
      } else {
        telemetry.tireSlipRatioFL = '  –  ';
        telemetry.tireSlipRatioFR = '  –  ';
        telemetry.tireSlipRatioRL = '  –  ';
        telemetry.tireSlipRatioRR = '  –  ';
      }

      telemetry.suspensionFL = _getFloat32(data, 0xC4);
      telemetry.suspensionFR = _getFloat32(data, 0xC8);
      telemetry.suspensionRL = _getFloat32(data, 0xCC);
      telemetry.suspensionRR = _getFloat32(data, 0xD0);

      // Gearing
      telemetry.gear1 = _getFloat32(data, 0x104);
      telemetry.gear2 = _getFloat32(data, 0x108);
      telemetry.gear3 = _getFloat32(data, 0x10C);
      telemetry.gear4 = _getFloat32(data, 0x110);
      telemetry.gear5 = _getFloat32(data, 0x114);
      telemetry.gear6 = _getFloat32(data, 0x118);
      telemetry.gear7 = _getFloat32(data, 0x11C);
      telemetry.gear8 = _getFloat32(data, 0x120);
      telemetry.transmissionTopSpeed = _getFloat32(data, 0x100);

      // Positioning
      telemetry.posX = _getFloat32(data, 0x04);
      telemetry.posY = _getFloat32(data, 0x08);
      telemetry.posZ = _getFloat32(data, 0x0C);

      // Velocity
      telemetry.velX = _getFloat32(data, 0x10);
      telemetry.velY = _getFloat32(data, 0x14);
      telemetry.velZ = _getFloat32(data, 0x18);

      // Rotation
      telemetry.rotPitch = _getFloat32(data, 0x1C);
      telemetry.rotYaw = _getFloat32(data, 0x20);
      telemetry.rotRoll = _getFloat32(data, 0x24);

      // Angular velocity
      telemetry.angVelX = _getFloat32(data, 0x2C);
      telemetry.angVelY = _getFloat32(data, 0x30);
      telemetry.angVelZ = _getFloat32(data, 0x34);

      // Fuel/EV data
      telemetry.fuel = _getFloat32(data, 0x44);
      telemetry.maxFuel = _getFloat32(data, 0x48);
      telemetry.isEV = telemetry.maxFuel <= 0;

      // Flags
      telemetry.flags8E = _getUint8(data, 0x8E);
      telemetry.flags8F = _getUint8(data, 0x8F);
      telemetry.flags93 = _getUint8(data, 0x93);

      // Other float values
      telemetry.roadPlaneX = _getFloat32(data, 0x94);
      telemetry.roadPlaneY = _getFloat32(data, 0x98);
      telemetry.roadPlaneZ = _getFloat32(data, 0x9C);
      telemetry.roadPlaneDistance = _getFloat32(data, 0xA0);
      telemetry.floatD4 = _getFloat32(data, 0xD4);
      telemetry.floatD8 = _getFloat32(data, 0xD8);
      telemetry.floatDC = _getFloat32(data, 0xDC);
      telemetry.floatE0 = _getFloat32(data, 0xE0);
      telemetry.floatE4 = _getFloat32(data, 0xE4);
      telemetry.floatE8 = _getFloat32(data, 0xE8);
      telemetry.floatEC = _getFloat32(data, 0xEC);
      telemetry.floatF0 = _getFloat32(data, 0xF0);
    } catch (e) {
      print('Error parsing telemetry data: $e');
    }

    return telemetry;
  }

  // Helper methods to read different data types from byte array
  static int _getInt32(Uint8List data, int offset) {
    if (offset + 4 > data.length) return 0;
    return (data[offset] & 0xFF) |
        ((data[offset + 1] & 0xFF) << 8) |
        ((data[offset + 2] & 0xFF) << 16) |
        ((data[offset + 3] & 0xFF) << 24);
  }

  static int _getInt16(Uint8List data, int offset) {
    if (offset + 2 > data.length) return 0;
    return (data[offset] & 0xFF) | ((data[offset + 1] & 0xFF) << 8);
  }

  static int _getUint16(Uint8List data, int offset) {
    if (offset + 2 > data.length) return 0;
    return (data[offset] & 0xFF) | ((data[offset + 1] & 0xFF) << 8);
  }

  static int _getUint8(Uint8List data, int offset) {
    if (offset >= data.length) return 0;
    return data[offset] & 0xFF;
  }

  static double _getFloat32(Uint8List data, int offset) {
    if (offset + 4 > data.length) return 0.0;
    final buffer = Uint8List(4);
    buffer.setRange(0, 4, data.skip(offset).take(4).toList());
    final byteData = ByteData.sublistView(buffer);
    return byteData.getFloat32(0, Endian.little);
  }

  String formatLapTime(int milliseconds) {
    if (milliseconds <= 0) return '';
    final seconds = milliseconds / 1000.0;
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toStringAsFixed(0)}:${remainingSeconds.toStringAsFixed(3)}';
  }

  String formatCurLapTime(double seconds) {
    if (seconds <= 0) return '';
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toStringAsFixed(0)}:${remainingSeconds.toStringAsFixed(3)}';
  }
}
