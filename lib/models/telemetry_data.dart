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
  double gearUnknown = 0.0;

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
  double float94 = 0.0;
  double float98 = 0.0;
  double float9C = 0.0;
  double floatA0 = 0.0;
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
      telemetry.gearUnknown = _getFloat32(data, 0x100);

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
      telemetry.float94 = _getFloat32(data, 0x94);
      telemetry.float98 = _getFloat32(data, 0x98);
      telemetry.float9C = _getFloat32(data, 0x9C);
      telemetry.floatA0 = _getFloat32(data, 0xA0);
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
