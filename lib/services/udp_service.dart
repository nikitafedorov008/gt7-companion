import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

class UdpService {
  static const int receivePort = 33740;
  static const int sendPort = 33739;

  RawDatagramSocket? _socket;
  Timer? _heartbeatTimer;
  bool _isListening = false;
  String? _ipAddress;
  int _packetsSinceHeartbeat = 0;

  Function(Uint8List data)? onDataReceived;
  Function(String error)? onError;

  Future<void> startListening(String ipAddress) async {
    // Clean up any existing connection first
    if (_isListening) {
      await stopListening();
      // Wait a bit to ensure socket is fully closed
      await Future.delayed(Duration(milliseconds: 100));
    }

    _ipAddress = ipAddress;
    try {
      // Create socket - bind to 0.0.0.0 on the receivePort, just like Python
      // This is critical: we use the SAME socket for both sending and receiving
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        receivePort,
        reuseAddress: true, // Allow address reuse
        reusePort: false,
      );
      _socket!.broadcastEnabled = false;

      _isListening = true;

      print(
        'UDP socket bound to port $receivePort, listening for data from GT7...',
      );

      // Listen for incoming data
      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = _socket!.receive();
          if (datagram != null && datagram.data.isNotEmpty) {
            _packetsSinceHeartbeat++;
            print(
              'Received UDP packet #$_packetsSinceHeartbeat: ${datagram.data.length} bytes from ${datagram.address}:${datagram.port}',
            );
            onDataReceived?.call(datagram.data);

            // Send heartbeat every 100 packets (like Python does)
            if (_packetsSinceHeartbeat > 100) {
              _sendHeartbeat();
              _packetsSinceHeartbeat = 0;
            }
          }
        }
      });

      // Wait a bit for socket to be fully ready, then send initial heartbeat
      await Future.delayed(Duration(milliseconds: 100));
      _sendHeartbeat();

      // Also send periodic heartbeats via timer as backup (every 10 seconds)
      _startHeartbeatTimer();
    } catch (e) {
      onError?.call('UDP Error: $e');
    }
  }

  // Start the heartbeat timer - send heartbeat every 10 seconds as backup
  void _startHeartbeatTimer() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isListening && _ipAddress != null) {
        _sendHeartbeat();
      }
    });
  }

  void _sendHeartbeat() {
    if (_socket != null && _ipAddress != null) {
      try {
        // Use the SAME socket for sending heartbeat - this is the key fix
        // GT7 will send data back to the IP:port it received the heartbeat from
        final int bytesSent = _socket!.send(
          Uint8List.fromList([65]), // 'A' in ASCII
          InternetAddress(_ipAddress!),
          sendPort,
        );
        print('Sent heartbeat to $_ipAddress:$sendPort ($bytesSent bytes)');
      } catch (e) {
        onError?.call('Heartbeat Error: $e');
      }
    }
  }

  // Send initial connection packet - using the same socket
  Future<void> sendInitialConnection() async {
    // This method is no longer needed since we send heartbeat after binding
    // But keep it for compatibility
    _sendHeartbeat();
  }

  Future<void> stopListening() async {
    _isListening = false;
    _heartbeatTimer?.cancel();
    _packetsSinceHeartbeat = 0;
    if (_socket != null) {
      _socket!.close();
      _socket = null;
    }
  }
}
