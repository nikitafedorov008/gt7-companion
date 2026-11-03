import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/services/console_discovery_service.dart';

void main() {
  final reply = utf8.encode(
    'HTTP/1.1 200 Ok\r\nhost-type:PS5\r\nhost-id:abc\r\nhost-name:Living room\r\n',
  );
  test('DDP requires protocol status and console identity', () {
    final value = ConsoleDiscoveryService.parseReply(reply, '127.0.0.1')!;
    expect(value.platform, 'PS5');
    expect(value.active, isTrue);
    for (final invalid in [
      'hello',
      'HTTP/1.1 200 Ok\nhost-type:PS5',
      'HTTP/1.1 200 Ok\nhost-type:TV\nhost-id:abc',
    ]) {
      expect(
        ConsoleDiscoveryService.parseReply(utf8.encode(invalid), '127.0.0.1'),
        isNull,
      );
    }
    expect(ConsoleDiscoveryService.parseReply(reply, 'bad address'), isNull);
    final standby = ConsoleDiscoveryService.parseReply(
      utf8.encode('HTTP/1.1 620 Standby\nhost-type:PS4\nhost-id:abc'),
      '127.0.0.1',
    )!;
    expect(standby.active, isFalse);
  });
  test(
    'bounded loopback discovery requests DDP and deduplicates replies',
    () async {
      final server = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final service = ConsoleDiscoveryService();
      addTearDown(() {
        server.close();
        service.dispose();
      });
      server.listen((event) {
        if (event != RawSocketEvent.read) return;
        final packet = server.receive()!;
        expect(
          utf8.decode(packet.data),
          contains('device-discovery-protocol-version:00030010'),
        );
        server.send(reply, packet.address, packet.port);
        server.send(reply, packet.address, packet.port);
      });
      final found = await service.discover(
        destination: InternetAddress.loopbackIPv4,
        ports: [server.port],
        budget: const Duration(milliseconds: 150),
      );
      expect(found, hasLength(1));
      expect(found.single.name, 'Living room');
    },
  );
  test(
    'cancel completes pending discovery and permits another round',
    () async {
      final service = ConsoleDiscoveryService();
      addTearDown(service.dispose);
      final pending = service.discover(
        destination: InternetAddress.loopbackIPv4,
        ports: [9],
        budget: const Duration(seconds: 10),
      );
      service.cancel();
      expect(await pending, isEmpty);
      expect(
        await service.discover(
          destination: InternetAddress.loopbackIPv4,
          ports: [9],
          budget: const Duration(milliseconds: 10),
        ),
        isEmpty,
      );
    },
  );
}
