import 'dart:async';
import 'dart:math';
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
  double _demoLapTime = 0.0;
  double _demoPosX = 0.0;
  double _demoPosY = 0.0;
  double _demoFuel = 100.0;
  DateTime? _lapStartTime;
  Timer? _demoTimer;

  TelemetryData? get telemetry => _currentTelemetry;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;

  TelemetryService() {
    _udpService.onDataReceived = _onDataReceived;
    _udpService.onError = _onError;
  }

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
      final decryptedData = CryptoUtils.decryptSalsa20(data);
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

        // Handle lap timing
        if (newTelemetry.currentLap > 0) {
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
    _demoFuel = 100.0;
    _currentTelemetry = _createDemoTelemetry();

    _demoTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      _updateDemoTelemetry,
    );
    notifyListeners();
  }

  void _updateDemoTelemetry(Timer timer) {
    _demoPacketId++;
    _demoLapTime += 0.5;
    if (_demoLapTime > 90) {
      _demoLap++;
      _demoLapTime = 0.0;
    }

    final angle = timer.tick / 12.0;
    _demoSpeed = (120 + sin(angle) * 45 + cos(angle * 0.45) * 15).clamp(
      0.0,
      320.0,
    );
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
    _demoPosX += 4.5;
    _demoPosY += 2.7;
    if (_demoPosX > 1000) _demoPosX -= 1000;
    if (_demoPosY > 600) _demoPosY -= 600;
    _demoFuel = max(0.0, _demoFuel - 0.18);

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
    telemetry.carId = 1;
    telemetry.throttle = _demoThrottle;
    telemetry.rpm = _demoRPM;
    telemetry.speed = _demoSpeed;
    telemetry.brake = max(0.0, 1.0 - _demoThrottle);
    telemetry.currentGear = _demoGear;
    telemetry.suggestedGear = min(7, _demoGear + 1);
    telemetry.boost = 0.0;
    telemetry.rpmWarning = 0;
    telemetry.rpmLimiter = 0;
    telemetry.estTopSpeed = 320;
    telemetry.clutch = 0.0;
    telemetry.clutchEngaged = 0.0;
    telemetry.rpmAfterClutch = 0.0;
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
    telemetry.gearUnknown = 0.0;
    telemetry.posX = _demoPosX;
    telemetry.posY = _demoPosY;
    final angle = _demoPosX / 120.0;
    telemetry.posZ = sin(angle) * 18.0;
    telemetry.velX = cos(angle) * (_demoSpeed / 3.6);
    telemetry.velY = sin(angle * 0.7) * (_demoSpeed / 3.6);
    telemetry.velZ = 0.0;
    telemetry.rotPitch = sin(angle * 0.67) * 4.0;
    telemetry.rotYaw = cos(angle * 0.67) * 12.0;
    telemetry.rotRoll = sin(angle * 0.5) * 3.0;
    telemetry.angVelX = 0.0;
    telemetry.angVelY = 0.0;
    telemetry.angVelZ = 0.0;
    telemetry.fuel = _demoFuel;
    telemetry.maxFuel = 100.0;
    telemetry.isEV = false;
    telemetry.flags8E = 0;
    telemetry.flags8F = 0;
    telemetry.flags93 = 0;
    telemetry.float94 = 0.0;
    telemetry.float98 = 0.0;
    telemetry.float9C = 0.0;
    telemetry.floatA0 = 0.0;
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
