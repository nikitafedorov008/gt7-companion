import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:network_discovery/network_discovery.dart';

class PlayStationDevice {
  final String ipAddress;
  final String macAddress;
  final String vendor;
  final bool isLikelyPlayStation;
  final int confidence; // 0-100, how confident we are this is a PlayStation

  PlayStationDevice({
    required this.ipAddress,
    required this.macAddress,
    required this.vendor,
    required this.isLikelyPlayStation,
    this.confidence = 0,
  });

  @override
  String toString() => '$ipAddress ($vendor) [$confidence% confidence]';
}

class NetworkScanner {
  // GT7 telemetry ports
  static const int gt7SendPort = 33739;
  static const int gt7ReceivePort = 33740;

  // Known PlayStation MAC address prefixes
  static const List<String> _playstationVendorPrefixes = [
    // Sony Interactive Entertainment (PS4/PS5)
    '00:D9:D1',
    'FC:0F:E6',
    'C0:56:27',
    'E4:A7:A0',
    // Hon Hai Precision (Foxconn) - used in PS4/PS5
    'E8:9E:B4',
    '04:33:C2',
    '90:60:F1',
    // Additional known prefixes for PS4/PS5
    '00:04:1F',
    '00:19:C5',
    '00:1F:A7',
    '00:23:06',
    '00:26:5A',
    '00:02:C7',
    '00:1E:C2',
  ];

  /// Cross-platform scan for PlayStation devices
  /// Uses network_discovery library which works on all platforms including Android and iOS
  static Future<List<PlayStationDevice>> scanForPlayStations() async {
    if (kIsWeb) {
      // Web platform - scanning not supported
      return [];
    }

    // On desktop platforms, try ARP scanning first (faster and provides MAC addresses)
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      List<PlayStationDevice> devices = [];

      if (Platform.isMacOS || Platform.isLinux) {
        devices = await _scanUsingArp();
      } else if (Platform.isWindows) {
        devices = await _scanUsingArpWindows();
      }

      // If ARP scan found PlayStation devices, return them
      if (devices.any((device) => device.isLikelyPlayStation)) {
        return devices;
      }
      // If ARP scan found devices but none are likely PlayStation,
      // we can still return them with updated confidence based on port check
      if (devices.isNotEmpty) {
        final updatedDevices = <PlayStationDevice>[];
        final futures = <Future<PlayStationDevice?>>[];
        for (final device in devices) {
          futures.add(
            _checkIfPlayStationDeviceWithMac(
              device.ipAddress,
              device.macAddress,
            ),
          );
        }
        final results = await Future.wait(futures);
        for (final result in results) {
          if (result != null) {
            updatedDevices.add(result);
          }
        }
        return updatedDevices;
      }
    }

    // For mobile platforms, first try UDP broadcast discovery (most accurate method)
    final udpDevices = await _discoverViaUdpBroadcast();
    if (udpDevices.isNotEmpty) {
      print('Found ${udpDevices.length} PlayStation devices via UDP broadcast');
      return udpDevices;
    }

    // If UDP broadcast didn't find anything, try SSDP discovery
    final ssdpDevices = await _discoverViaSsdp();
    if (ssdpDevices.isNotEmpty) {
      print('Found ${ssdpDevices.length} PlayStation devices via SSDP');
      return ssdpDevices;
    }

    // If SSDP didn't find anything, use network_discovery
    // Get local subnet
    final subnet = await getLocalSubnet();
    if (subnet == null) {
      print('Could not determine local subnet');
      return [];
    }

    print('Scanning subnet $subnet.x for PlayStation devices...');

    // Use network_discovery to find active devices in the subnet
    final stream = NetworkDiscovery.discoverAllPingableDevices(subnet);
    final activeIps = <String>[];

    // Collect all active IPs
    await for (final host in stream) {
      if (host.isActive) {
        activeIps.add(host.ip);
        print('Found active device: ${host.ip}');
      }
    }

    // Now check each active IP for PlayStation characteristics
    final devices = <PlayStationDevice>[];
    final futures = <Future<PlayStationDevice?>>[];

    for (final ip in activeIps) {
      futures.add(_checkIfPlayStationDevice(ip));
    }

    final results = await Future.wait(futures);
    for (final device in results) {
      if (device != null) {
        devices.add(device);
      }
    }

    // Sort devices: PlayStation devices first
    devices.sort((a, b) {
      if (a.isLikelyPlayStation && !b.isLikelyPlayStation) return -1;
      if (!a.isLikelyPlayStation && b.isLikelyPlayStation) return 1;
      return b.confidence.compareTo(a.confidence);
    });

    return devices;
  }

  /// Check if a device at the given IP is likely a PlayStation
  /// This method tries to identify PlayStation devices by checking for GT7 telemetry port
  /// On mobile platforms, we can't get MAC addresses, so we rely on port probing
  static Future<PlayStationDevice?> _checkIfPlayStationDevice(String ip) async {
    try {
      // First, check if the device responds to Remote Play port (987)
      final respondsToRemotePlay = await _probeRemotePlayPort(ip);
      if (respondsToRemotePlay) {
        // If it responds to Remote Play port, it's very likely a PlayStation
        print('Device $ip responds to Remote Play port - likely PlayStation');
        return PlayStationDevice(
          ipAddress: ip,
          macAddress: 'Unknown',
          vendor: 'PlayStation (responds to Remote Play port 987)',
          isLikelyPlayStation: true,
          confidence: 85, // High confidence for Remote Play port response
        );
      }

      // Next, try to probe the GT7 telemetry port
      final gt7Device = await _probeGT7Port(ip);
      if (gt7Device != null) {
        return gt7Device; // If responding on GT7 port, high confidence it's a PlayStation
      }

      // If direct connection fails, try sending heartbeat to activate telemetry
      // This is especially important on mobile platforms where we can't use MAC addresses
      final heartbeatResult = await _probeWithHeartbeat(ip);
      if (heartbeatResult != null) {
        return heartbeatResult;
      }

      // As a last resort, try to get the hostname for the IP
      // PlayStation devices often register with names starting with "PS4-" or "PS5-"
      final hostname = await _getHostnameForIp(ip);
      if (hostname != null &&
          (hostname.toUpperCase().startsWith('PS4-') ||
              hostname.toUpperCase().startsWith('PS5-'))) {
        print('Device $ip has PlayStation-like hostname: $hostname');
        return PlayStationDevice(
          ipAddress: ip,
          macAddress: 'Unknown',
          vendor: 'PlayStation ($hostname)',
          isLikelyPlayStation: true,
          confidence: 75, // High confidence for PlayStation-like hostname
        );
      }

      // If all checks fail, return with low confidence
      return PlayStationDevice(
        ipAddress: ip,
        macAddress: 'Unknown',
        vendor: 'Active device',
        isLikelyPlayStation: false,
        confidence:
            5, // Very low confidence since we can't verify it's a PlayStation
      );
    } catch (e) {
      print('Error checking device $ip: $e');
      return null;
    }
  }

  /// Get hostname for IP address if available
  static Future<String?> _getHostnameForIp(String ip) async {
    try {
      print('Resolving hostname for $ip');
      final hostname = await InternetAddress.lookup(ip);
      if (hostname.isNotEmpty && hostname[0].host != ip) {
        print('Resolved hostname for $ip: ${hostname[0].host}');
        return hostname[0].host;
      }
    } catch (e) {
      print('Could not resolve hostname for $ip: $e');
    }
    return null;
  }

  /// Check if a device responds to PlayStation Remote Play port (987)
  static Future<bool> _probeRemotePlayPort(String ip) async {
    try {
      print('Checking Remote Play port 987 for $ip');
      // Try to connect to port 987 (PlayStation Remote Play)
      final socket =
          await Socket.connect(
            ip,
            987,
            timeout: const Duration(milliseconds: 800),
          ).timeout(
            const Duration(milliseconds: 1000),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      socket.destroy();
      print('Device $ip responds on Remote Play port 987');
      return true;
    } catch (e) {
      print('Device $ip does not respond on Remote Play port 987: $e');
      // If connection fails, it's likely not a PlayStation
      return false;
    }
  }

  /// Discover PlayStation devices using UDP broadcast discovery
  /// This sends a discovery packet to the network and listens for responses from PlayStation consoles
  static Future<List<PlayStationDevice>> _discoverViaUdpBroadcast() async {
    final devices = <PlayStationDevice>[];

    try {
      print('Starting UDP broadcast discovery for PlayStation devices...');

      // Create UDP socket for broadcast discovery
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      // Send discovery packet to port 987 (PS4) and 9302 (PS5)
      // Using "SRCH" command which is standard for PlayStation discovery
      final discoveryPacket = utf8.encode("SRCH * HTTP/1.1\r\n");

      // Send to broadcast address on both PS4 and PS5 ports
      socket.send(discoveryPacket, InternetAddress("255.255.255.255"), 987);
      socket.send(discoveryPacket, InternetAddress("255.255.255.255"), 9302);

      print('UDP discovery packets sent to broadcast addresses');

      // Listen for responses (up to 5 seconds)
      final responses = <String>[];
      final ipAddresses = <String>[];
      final stopwatch = Stopwatch()..start();

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data);
            responses.add(response);
            ipAddresses.add(datagram.address.address);
            print(
              'Received UDP response from ${datagram.address.address}: $response',
            );
          }
        }
      });

      // Wait for responses or timeout
      while (stopwatch.elapsedMilliseconds < 5000) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (responses.length >= 10) break; // Limit responses to avoid hanging
      }

      socket.close();

      // Process responses
      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        final ip = ipAddresses[i];

        // Check if response contains PlayStation identifiers
        if (response.toUpperCase().contains('PLAYSTATION') ||
            response.toUpperCase().contains('SONY') ||
            response.toUpperCase().contains('PS4') ||
            response.toUpperCase().contains('PS5')) {
          print('Found PlayStation via UDP broadcast: $ip');
          devices.add(
            PlayStationDevice(
              ipAddress: ip,
              macAddress: 'Unknown',
              vendor: 'PlayStation (UDP broadcast discovery)',
              isLikelyPlayStation: true,
              confidence: 90, // High confidence for UDP broadcast discovery
            ),
          );
        }
      }
    } catch (e) {
      print('UDP broadcast discovery error: $e');
    }

    return devices;
  }

  /// Discover PlayStation devices using SSDP (UPnP)
  static Future<List<PlayStationDevice>> _discoverViaSsdp() async {
    final devices = <PlayStationDevice>[];

    try {
      // Create multiple SSDP M-SEARCH requests for different device types
      final searchTypes = [
        'urn:schemas-upnp-org:device:MediaRenderer:1',
        'urn:schemas-upnp-org:device:MediaServer:1',
        'ssdp:all',
        'upnp:rootdevice',
      ];

      for (final st in searchTypes) {
        print('Sending SSDP search for: $st');

        // Create an SSDP M-SEARCH request
        final request = [
          'M-SEARCH * HTTP/1.1',
          'HOST: 239.255.255.250:1900',
          'MAN: "ssdp:discover"',
          'MX: 3',
          'ST: $st',
          '',
          '',
        ].join('\r\n');

        // Create UDP socket for SSDP
        final socket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          1901,
        ); // Use different port to avoid conflicts
        socket.broadcastEnabled = true;

        // Send SSDP discovery request
        socket.send(
          utf8.encode(request),
          InternetAddress('239.255.255.250'),
          1900,
        );

        // Wait for responses (up to 3 seconds per search)
        final responses = <String>[];
        final stopwatch = Stopwatch()..start();

        socket.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = socket.receive();
            if (datagram != null) {
              responses.add(String.fromCharCodes(datagram.data));
            }
          }
        });

        // Wait for responses or timeout
        while (stopwatch.elapsedMilliseconds < 3000) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (responses.length >= 5) break; // Limit responses to avoid hanging
        }

        socket.close();

        // Process responses
        for (final response in responses) {
          print('SSDP Response: $response');
          if (response.toUpperCase().contains('PLAYSTATION') ||
              response.toUpperCase().contains('SCE') ||
              response.toUpperCase().contains('SONY') ||
              response.contains('urn:schemas-sce-com:device:PlayStation')) {
            // Extract IP address from response
            final locationMatch = RegExp(
              r'LOCATION: http://([\d\.]+):\d+',
            ).firstMatch(response);
            if (locationMatch != null) {
              final ip = locationMatch.group(1);
              if (ip != null) {
                print('Found PlayStation via SSDP: $ip');
                devices.add(
                  PlayStationDevice(
                    ipAddress: ip,
                    macAddress: 'Unknown',
                    vendor: 'PlayStation (SSDP discovery)',
                    isLikelyPlayStation: true,
                    confidence: 95, // Very high confidence for SSDP discovery
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print('SSDP discovery error: $e');
    }

    return devices;
  }

  /// Try to activate PlayStation telemetry by sending heartbeat
  /// This method mimics the behavior of UdpService to activate telemetry
  static Future<PlayStationDevice?> _probeWithHeartbeat(String ip) async {
    try {
      // First, check if the device responds to Remote Play port (987)
      final respondsToRemotePlay = await _probeRemotePlayPort(ip);
      if (respondsToRemotePlay) {
        // If it responds to Remote Play port, it's very likely a PlayStation
        print('Device $ip responds to Remote Play port - likely PlayStation');
        return PlayStationDevice(
          ipAddress: ip,
          macAddress: 'Unknown',
          vendor: 'PlayStation (responds to Remote Play port 987)',
          isLikelyPlayStation: true,
          confidence: 85, // High confidence for Remote Play port response
        );
      }

      // If not responding to Remote Play port, try the original heartbeat approach
      // First, verify that we can send UDP heartbeat to the send port (33739)
      // This is typically how PlayStation receives activation signal
      final sendSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        gt7ReceivePort + 100,
      ); // Bind to a different port to avoid conflicts

      // Send heartbeat to trigger telemetry
      final bytesSent = sendSocket.send(
        [65],
        InternetAddress(ip),
        gt7SendPort,
      ); // Send 'A' as heartbeat
      print('Sent heartbeat to $ip:$gt7SendPort ($bytesSent bytes)');

      // Close the sending socket
      sendSocket.close();

      // If we successfully sent the heartbeat, this is a positive sign
      // Now check if the device responds differently to connection attempts on receive port
      try {
        final verifySocket =
            await Socket.connect(
              ip,
              gt7ReceivePort,
              timeout: const Duration(milliseconds: 1000),
            ).timeout(
              const Duration(milliseconds: 1500),
              onTimeout: () => throw TimeoutException('Connection timeout'),
            );

        verifySocket.destroy();

        // If we can connect to the receive port, it's likely a PlayStation
        return PlayStationDevice(
          ipAddress: ip,
          macAddress: 'Unknown',
          vendor: 'PlayStation (telemetry activated by heartbeat)',
          isLikelyPlayStation: true,
          confidence:
              70, // High confidence if telemetry was activated by heartbeat
        );
      } catch (e) {
        // If we can't connect, check the type of error
        if (e is SocketException) {
          // PlayStation typically responds with "Connection refused" to TCP connections
          // on port 33740 when telemetry is not active, rather than "Connection timed out"
          // This is a key distinguishing feature
          if (e.osError?.errorCode == 111) {
            // Connection refused
            // This behavior (accepts UDP heartbeat but refuses TCP connection) is common
            // for many devices, not just PlayStation. We'll mark it as potentially
            // a PlayStation but with low confidence
            print(
              'Received connection refused for GT7 receive port after heartbeat for $ip - marked with low confidence',
            );
            return PlayStationDevice(
              ipAddress: ip,
              macAddress: 'Unknown',
              vendor: 'Device with GT7-like port behavior',
              isLikelyPlayStation:
                  false, // Mark as not likely PlayStation to avoid false positives
              confidence: 15, // Low confidence
            );
          } else if (e.osError?.errorCode == 110) {
            // Connection timed out
            // This means the port is not reachable, likely not a PlayStation
            print(
              'Connection timed out for GT7 receive port after heartbeat for $ip - not a PlayStation',
            );
            return null;
          }
        }

        print('Cannot connect to GT7 receive port after heartbeat for $ip: $e');
        return null; // Return null to indicate this is likely not a PlayStation
      }
    } catch (e) {
      print('Heartbeat probe failed for $ip: $e');
      return null;
    }
  }

  /// Check if a device with known MAC address is likely a PlayStation
  /// This method updates the device information based on both MAC address and port check
  static Future<PlayStationDevice?> _checkIfPlayStationDeviceWithMac(
    String ip,
    String macAddress,
  ) async {
    try {
      // Check if MAC address indicates PlayStation
      final vendor = _identifyVendor(macAddress);
      final isPlayStation = _isPlayStationMac(macAddress);
      var confidence = isPlayStation ? 95 : 20;

      // Also check if responding on GT7 port for additional confirmation
      final gt7Device = await _probeGT7Port(ip);
      if (gt7Device != null) {
        // If responding on GT7 port, increase confidence
        confidence = isPlayStation ? 100 : 80;
        return PlayStationDevice(
          ipAddress: ip,
          macAddress: macAddress,
          vendor: vendor,
          isLikelyPlayStation:
              true, // If responding on GT7 port, consider it a PlayStation
          confidence: confidence,
        );
      }

      // If not responding on GT7 port but MAC suggests PlayStation
      if (isPlayStation) {
        return PlayStationDevice(
          ipAddress: ip,
          macAddress: macAddress,
          vendor: vendor,
          isLikelyPlayStation: true,
          confidence: confidence,
        );
      }

      // If MAC doesn't suggest PlayStation and not responding on GT7 port
      return PlayStationDevice(
        ipAddress: ip,
        macAddress: macAddress,
        vendor: vendor,
        isLikelyPlayStation: false,
        confidence: confidence,
      );
    } catch (e) {
      print('Error checking device $ip with MAC $macAddress: $e');
      return null;
    }
  }

  /// Universal cross-platform scan using UDP port probing
  /// Works on all platforms but slower
  static Future<List<PlayStationDevice>> _universalScan() async {
    final devices = <PlayStationDevice>[];

    try {
      final subnet = await getLocalSubnet();
      if (subnet == null) {
        print('Could not determine local subnet');
        return devices;
      }

      print('Scanning subnet $subnet.x for GT7 telemetry port...');

      // Use network_discovery to find active devices in the subnet
      final stream = NetworkDiscovery.discoverAllPingableDevices(subnet);
      final activeIps = <String>[];

      // Collect all active IPs
      await for (final host in stream) {
        if (host.isActive) {
          activeIps.add(host.ip);
        }
      }

      // Check each active IP for GT7 telemetry port
      final futures = <Future<PlayStationDevice?>>[];
      for (final ip in activeIps) {
        futures.add(_probeGT7Port(ip));
      }

      // Wait for all probes with timeout
      final results = await Future.wait(futures, eagerError: false);

      // Collect successful probes
      for (final device in results) {
        if (device != null) {
          devices.add(device);
        }
      }
    } catch (e) {
      print('Universal scan error: $e');
    }

    return devices;
  }

  /// Probe if a host is running GT7 telemetry service
  static Future<PlayStationDevice?> _probeGT7Port(String ip) async {
    try {
      // Try to connect to GT7 receive port (33740)
      final socket =
          await Socket.connect(
            ip,
            gt7ReceivePort,
            timeout: const Duration(milliseconds: 1000),
          ).timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      // If we successfully connected, this might be a PlayStation
      socket.destroy();

      return PlayStationDevice(
        ipAddress: ip,
        macAddress: 'Unknown',
        vendor: 'Device responding on GT7 telemetry port',
        isLikelyPlayStation: true,
        confidence: 80, // High confidence if responding on GT7 port
      );
    } catch (e) {
      // Connection failed or timeout - not a GT7 device
      // On mobile platforms, we might get different types of errors
      // Let's log the error for debugging
      print('GT7 port probe failed for $ip: $e');
      return null;
    }
  }

  /// macOS/Linux ARP table scan
  /// On mobile platforms, this method is not available, so return empty list
  static Future<List<PlayStationDevice>> _scanUsingArp() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // ARP scanning is not available on mobile platforms
      return [];
    }

    final devices = <PlayStationDevice>[];

    try {
      // Run arp -a command to get ARP table
      final result = await Process.run('arp', ['-a']);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');

        for (final line in lines) {
          // Parse ARP output: ? (192.168.0.177) at e8:9e:b4:9f:85:3d on en0 ifscope [ethernet]
          final ipMatch = RegExp(r'\((\d+\.\d+\.\d+\.\d+)\)').firstMatch(line);
          final macMatch = RegExp(r'at ([0-9a-fA-F:]{17})').firstMatch(line);

          if (ipMatch != null && macMatch != null) {
            final ip = ipMatch.group(1)!;
            final mac = macMatch.group(1)!.toUpperCase();

            // Skip broadcast and multicast addresses
            if (ip.endsWith('.255') || ip.startsWith('224.')) {
              continue;
            }

            final vendor = _identifyVendor(mac);
            final isPlayStation = _isPlayStationMac(mac);

            final confidence = isPlayStation ? 95 : 20;
            devices.add(
              PlayStationDevice(
                ipAddress: ip,
                macAddress: mac,
                vendor: vendor,
                isLikelyPlayStation: isPlayStation,
                confidence: confidence,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error scanning network: $e');
    }

    // Sort devices: PlayStation devices first
    devices.sort((a, b) {
      if (a.isLikelyPlayStation && !b.isLikelyPlayStation) return -1;
      if (!a.isLikelyPlayStation && b.isLikelyPlayStation) return 1;
      return a.ipAddress.compareTo(b.ipAddress);
    });

    return devices;
  }

  /// Windows ARP table scan (using 'arp -a' with different output format)
  /// On mobile platforms, this method is not available, so return empty list
  static Future<List<PlayStationDevice>> _scanUsingArpWindows() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // ARP scanning is not available on mobile platforms
      return [];
    }

    final devices = <PlayStationDevice>[];

    try {
      final result = await Process.run('arp', ['-a']);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');

        for (final line in lines) {
          // Parse Windows ARP output: 192.168.0.177    e8-9e-b4-9f-85-3d     dynamic
          final match = RegExp(
            r'\s+(\d+\.\d+\.\d+\.\d+)\s+([0-9a-fA-F-]{17})\s+',
          ).firstMatch(line);

          if (match != null) {
            final ip = match.group(1)!;
            final mac = match.group(2)!.replaceAll('-', ':').toUpperCase();

            // Skip broadcast and multicast addresses
            if (ip.endsWith('.255') || ip.startsWith('224.')) {
              continue;
            }

            final vendor = _identifyVendor(mac);
            final isPlayStation = _isPlayStationMac(mac);
            final confidence = isPlayStation ? 95 : 20;

            devices.add(
              PlayStationDevice(
                ipAddress: ip,
                macAddress: mac,
                vendor: vendor,
                isLikelyPlayStation: isPlayStation,
                confidence: confidence,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Windows ARP scan error: $e');
    }

    // Sort devices: PlayStation devices first, then by confidence
    devices.sort((a, b) {
      if (a.isLikelyPlayStation && !b.isLikelyPlayStation) return -1;
      if (!a.isLikelyPlayStation && b.isLikelyPlayStation) return 1;
      return b.confidence.compareTo(a.confidence);
    });

    return devices;
  }

  /// Check if MAC address belongs to PlayStation
  static bool _isPlayStationMac(String mac) {
    final prefix = mac.substring(0, 8); // First 3 bytes (XX:XX:XX)
    return _playstationVendorPrefixes.any(
      (p) => prefix.toUpperCase().startsWith(p.toUpperCase()),
    );
  }

  /// Identify vendor from MAC address
  static String _identifyVendor(String mac) {
    final prefix = mac.substring(0, 8).toUpperCase();

    // Sony/PlayStation prefixes
    if (prefix.startsWith('00:D9:D1') ||
        prefix.startsWith('FC:0F:E6') ||
        prefix.startsWith('C0:56:27') ||
        prefix.startsWith('E4:A7:A0')) {
      return 'Sony Interactive Entertainment (PlayStation)';
    }

    // Foxconn prefixes (used in PS4/PS5)
    if (prefix.startsWith('E8:9E:B4') ||
        prefix.startsWith('04:33:C2') ||
        prefix.startsWith('90:60:F1')) {
      return 'Hon Hai Precision/Foxconn (likely PlayStation)';
    }

    // Additional PlayStation prefixes
    if (prefix.startsWith('00:04:1F') ||
        prefix.startsWith('00:19:C5') ||
        prefix.startsWith('00:1F:A7') ||
        prefix.startsWith('00:23:06') ||
        prefix.startsWith('00:26:5A') ||
        prefix.startsWith('00:02:C7') ||
        prefix.startsWith('00:1E:C2')) {
      return 'Sony/PlayStation (likely PlayStation)';
    }

    // Check for locally administered MAC (randomized)
    final secondByte = int.parse(mac.substring(3, 5), radix: 16);
    if ((secondByte & 0x02) != 0) {
      return 'Locally Administered Address (Phone/Laptop)';
    }

    return 'Unknown Device';
  }

  /// Get the local network subnet
  static Future<String?> getLocalSubnet() async {
    try {
      // On mobile platforms, NetworkInterface.list() might not work properly
      if (Platform.isAndroid || Platform.isIOS) {
        // Try to get the WiFi IP address using a different approach
        // First, try to connect to a remote host to determine the local IP
        try {
          final socket = await Socket.connect(
            '8.8.8.8',
            53,
            timeout: Duration(seconds: 5),
          );
          final localAddress = socket.address.address;
          socket.destroy();

          // Extract subnet from the local IP
          final parts = localAddress.split('.');
          if (parts.length == 4) {
            // Only return if it looks like a local IP (starts with 192.168, 10., or 172.)
            if (localAddress.startsWith('192.168.') ||
                localAddress.startsWith('10.') ||
                (localAddress.startsWith('172.') &&
                    int.tryParse(localAddress.split('.')[1]) != null &&
                    int.tryParse(localAddress.split('.')[1])! >= 16 &&
                    int.tryParse(localAddress.split('.')[1])! <= 31)) {
              return '${parts[0]}.${parts[1]}.${parts[2]}';
            }
          }
        } catch (e) {
          print('Could not determine local IP via socket connect: $e');
        }

        // If the above fails, try NetworkInterface.list() as fallback
        final interfaces = await NetworkInterface.list();
        for (final interface in interfaces) {
          // Look for WiFi or other active interfaces (not loopback)
          if (interface.name.contains('wlan') ||
              interface.name.contains('wifi') ||
              interface.name.contains('en') ||
              interface.name.startsWith('eth')) {
            for (final addr in interface.addresses) {
              if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
                // Extract subnet (e.g., 192.168.0.x -> 192.168.0)
                final parts = addr.address.split('.');
                if (parts.length == 4) {
                  // Only return if it looks like a local IP
                  if (addr.address.startsWith('192.168.') ||
                      addr.address.startsWith('10.') ||
                      (addr.address.startsWith('172.') &&
                          int.tryParse(addr.address.split('.')[1]) != null &&
                          int.tryParse(addr.address.split('.')[1])! >= 16 &&
                          int.tryParse(addr.address.split('.')[1])! <= 31)) {
                    return '${parts[0]}.${parts[1]}.${parts[2]}';
                  }
                }
              }
            }
          }
        }
      } else {
        // On desktop platforms, use the original approach
        final interfaces = await NetworkInterface.list();

        for (final interface in interfaces) {
          // Look for active interfaces (not loopback)
          if (interface.name.startsWith('en') ||
              interface.name.startsWith('eth')) {
            for (final addr in interface.addresses) {
              if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
                // Extract subnet (e.g., 192.168.0.x -> 192.168.0)
                final parts = addr.address.split('.');
                if (parts.length == 4) {
                  // Only return if it looks like a local IP
                  if (addr.address.startsWith('192.168.') ||
                      addr.address.startsWith('10.') ||
                      (addr.address.startsWith('172.') &&
                          int.tryParse(addr.address.split('.')[1]) != null &&
                          int.tryParse(addr.address.split('.')[1])! >= 16 &&
                          int.tryParse(addr.address.split('.')[1])! <= 31)) {
                    return '${parts[0]}.${parts[1]}.${parts[2]}';
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error getting local subnet: $e');
    }
    return null;
  }

  /// Deep scan using multiple methods
  static Future<List<PlayStationDevice>> deepScan() async {
    if (kIsWeb) return [];

    // On desktop platforms, try ARP scanning first (faster and provides MAC addresses)
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      List<PlayStationDevice> devices = [];

      if (Platform.isMacOS || Platform.isLinux) {
        // First ping subnet to populate ARP table
        final subnet = await getLocalSubnet();
        if (subnet != null) {
          await _pingSubnetUnix(subnet);
        }
        devices = await _scanUsingArp();
      } else if (Platform.isWindows) {
        // First ping subnet to populate ARP table
        final subnet = await getLocalSubnet();
        if (subnet != null) {
          await _pingSubnetWindows(subnet);
        }
        devices = await _scanUsingArpWindows();
      }

      // If ARP scan found PlayStation devices, return them
      if (devices.any((device) => device.isLikelyPlayStation)) {
        return devices;
      }
      // If ARP scan found devices but none are likely PlayStation,
      // we can still return them with updated confidence based on port check
      if (devices.isNotEmpty) {
        final updatedDevices = <PlayStationDevice>[];
        final futures = <Future<PlayStationDevice?>>[];
        for (final device in devices) {
          futures.add(
            _checkIfPlayStationDeviceWithMac(
              device.ipAddress,
              device.macAddress,
            ),
          );
        }
        final results = await Future.wait(futures);
        for (final result in results) {
          if (result != null) {
            updatedDevices.add(result);
          }
        }
        return updatedDevices;
      }
    }

    // For mobile platforms, use network_discovery
    if (Platform.isAndroid || Platform.isIOS) {
      final subnet = await getLocalSubnet();
      if (subnet == null) return [];

      print('Starting deep scan on subnet $subnet.x using network_discovery');

      // Use network_discovery to find active devices in the subnet
      final stream = NetworkDiscovery.discoverAllPingableDevices(subnet);
      final activeIps = <String>[];

      // Collect all active IPs
      await for (final host in stream) {
        if (host.isActive) {
          activeIps.add(host.ip);
          print('Found active device: ${host.ip}');
        }
      }

      // Now check each active IP for PlayStation characteristics
      final devices = <PlayStationDevice>[];
      final futures = <Future<PlayStationDevice?>>[];

      for (final ip in activeIps) {
        futures.add(_checkIfPlayStationDevice(ip));
      }

      final results = await Future.wait(futures);
      for (final device in results) {
        if (device != null) {
          devices.add(device);
        }
      }

      // Sort devices: PlayStation devices first
      devices.sort((a, b) {
        if (a.isLikelyPlayStation && !b.isLikelyPlayStation) return -1;
        if (!a.isLikelyPlayStation && b.isLikelyPlayStation) return 1;
        return b.confidence.compareTo(a.confidence);
      });

      return devices;
    }

    // Fall back to universal scan for desktop if ARP didn't find anything
    return await _universalScan();
  }

  /// Ping scan for Unix-like systems (macOS, Linux)
  static Future<void> _pingSubnetUnix(String subnet) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Ping command is not available on mobile platforms
      return;
    }

    final futures = <Future>[];
    for (int i = 1; i < 255; i++) {
      final ip = '$subnet.$i';
      futures.add(_pingHostUnix(ip));
    }
    await Future.wait(futures);
  }

  static Future<void> _pingHostUnix(String ip) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Ping command is not available on mobile platforms
      return;
    }

    try {
      await Process.run('ping', [
        '-c',
        '1',
        '-W',
        '1',
        ip,
      ]).timeout(const Duration(seconds: 2));
    } catch (e) {
      // Ignore errors
    }
  }

  /// Ping scan for Windows
  static Future<void> _pingSubnetWindows(String subnet) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Ping command is not available on mobile platforms
      return;
    }

    final futures = <Future>[];
    for (int i = 1; i < 255; i++) {
      final ip = '$subnet.$i';
      futures.add(_pingHostWindows(ip));
    }
    await Future.wait(futures);
  }

  static Future<void> _pingHostWindows(String ip) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Ping command is not available on mobile platforms
      return;
    }

    try {
      await Process.run('ping', [
        '-n',
        '1',
        '-w',
        '1000',
        ip,
      ]).timeout(const Duration(seconds: 2));
    } catch (e) {
      // Ignore errors
    }
  }
}
