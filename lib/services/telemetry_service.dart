import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/udp_service.dart';
import '../utils/crypto_utils.dart';
import '../models/telemetry/telemetry_data.dart';

class TelemetryService extends ChangeNotifier {
  final UdpService _udpService = UdpService();
  TelemetryData? _currentTelemetry;
  String? _errorMessage;
  bool _isConnected = false;
  int _packetCount = 0;
  int _prevLap = -1;
  DateTime? _lapStartTime;

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

  Future<void> disconnect() async {
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
