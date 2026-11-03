import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/telemetry/console_candidate.dart';

/// Short DDP discovery round. Closing the source cancels pending bind/replies.
/// Protocol facts only; no third-party implementation is copied.
class ConsoleDiscoveryService {
  static const request =
      'SRCH * HTTP/1.1\n'
      'device-discovery-protocol-version:00030010\n';
  final List<RawDatagramSocket> _sockets = [];
  Timer? _timer;
  Completer<List<ConsoleCandidate>>? _pending;
  int _generation = 0;
  bool get broadcastAvailable => !Platform.isIOS;

  static ConsoleCandidate? parseReply(List<int> bytes, String sender) {
    if (bytes.length > 8192 ||
        InternetAddress.tryParse(sender)?.type != InternetAddressType.IPv4)
      return null;
    final lines = utf8.decode(bytes, allowMalformed: true).split('\n');
    final status = RegExp(
      r'^HTTP/1\.1 (200|620)(?:\s|$)',
    ).firstMatch(lines.first.trim());
    if (status == null) return null;
    final fields = <String, String>{};
    for (final line in lines.skip(1)) {
      final split = line.indexOf(':');
      if (split > 0)
        fields[line.substring(0, split).trim().toLowerCase()] = line
            .substring(split + 1)
            .trim();
    }
    final type = fields['host-type'];
    final id = fields['host-id'];
    if ((type != 'PS4' && type != 'PS5') ||
        id == null ||
        id.isEmpty ||
        id.length > 128)
      return null;
    final name = fields['host-name'];
    return ConsoleCandidate(
      address: sender,
      id: id,
      name: name == null || name.isEmpty
          ? type!
          : name.substring(0, name.length.clamp(0, 128)),
      platform: type!,
      active: status.group(1) == '200',
    );
  }

  Future<List<ConsoleCandidate>> discover({
    Duration budget = const Duration(seconds: 3),
    InternetAddress? destination,
    List<int> ports = const [987, 9302],
  }) async {
    cancel();
    if (!broadcastAvailable && destination == null) return [];
    final generation = _generation;
    final pending = Completer<List<ConsoleCandidate>>();
    _pending = pending;
    final found = <String, ConsoleCandidate>{};
    _timer = Timer(budget, () => _finish(found.values.toList()));
    for (final port in ports) {
      try {
        final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        if (generation != _generation || pending.isCompleted) {
          socket.close();
          break;
        }
        _sockets.add(socket);
        socket.broadcastEnabled = true;
        socket.listen((event) {
          if (event != RawSocketEvent.read || generation != _generation) return;
          Datagram? packet;
          while ((packet = socket.receive()) != null) {
            final candidate = parseReply(packet!.data, packet.address.address);
            if (candidate != null && packet.port == port)
              found['${candidate.id}@${candidate.address}'] = candidate;
          }
        }, onError: (Object _) {});
        socket.send(
          utf8.encode(request),
          destination ?? InternetAddress('255.255.255.255'),
          port,
        );
      } on SocketException {
        // Restricted interfaces must leave manual/direct-IP connection available.
      }
    }
    return pending.future;
  }

  void _finish(List<ConsoleCandidate> result) {
    final pending = _pending;
    _pending = null;
    _timer?.cancel();
    for (final socket in _sockets) {
      socket.close();
    }
    _sockets.clear();
    if (pending != null && !pending.isCompleted) pending.complete(result);
  }

  void cancel() {
    _generation++;
    _finish([]);
  }

  void dispose() => cancel();
}
