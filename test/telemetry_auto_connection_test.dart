import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:gt7_companion/services/udp_service.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gt7_companion/models/telemetry/console_candidate.dart';
import 'package:gt7_companion/models/telemetry/telemetry_data.dart';
import 'package:gt7_companion/services/console_discovery_service.dart';
import 'package:gt7_companion/services/app_settings_service.dart';
import 'package:gt7_companion/services/telemetry_service.dart';
import 'package:gt7_companion/repositories/telemetry_connection_repository.dart';

const ps5 = ConsoleCandidate(
  address: '127.0.0.1',
  id: 'one',
  name: 'PS5',
  platform: 'PS5',
  active: true,
);

class FakeDiscovery extends ConsoleDiscoveryService {
  List<ConsoleCandidate> result = [ps5];
  Completer<List<ConsoleCandidate>>? pending;
  int rounds = 0;
  @override
  bool get broadcastAvailable => true;
  @override
  Future<List<ConsoleCandidate>> discover({
    Duration budget = const Duration(seconds: 3),
    dynamic destination,
    List<int> ports = const [987, 9302],
  }) async {
    rounds++;
    return pending == null ? result : pending!.future;
  }
}

class FakeTelemetry extends TelemetryService {
  bool connected = false, demo = false;
  TelemetryData? data;
  int attempts = 0;
  @override
  bool get isConnected => connected;
  @override
  bool get isDemo => demo;
  @override
  TelemetryData? get telemetry => data;
  @override
  Future<void> connectToGT7(String address) async {
    attempts++;
    connected = true;
    connectedAddress = address;
    receivedAt = null;
    data = null;
    notifyListeners();
  }

  void packet() {
    receivedAt = DateTime.now();
    data = TelemetryData()..carId = 3418;
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    connected = false;
    demo = false;
    data = null;
    receivedAt = null;
    notifyListeners();
  }

  @override
  Future<void> startDemoTelemetry() async {
    demo = true;
    connected = true;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class PacketUdp extends UdpService {
  @override
  Future<void> startListening(String address) async {}
  @override
  Future<void> stopListening() async {}
}

Uint8List encryptedPacket(int id) {
  final plain = Uint8List(368);
  final data = ByteData.sublistView(plain);
  data.setUint32(0, 0x47375330, Endian.little);
  data.setUint32(0x70, id, Endian.little);
  data.setInt32(0x124, 3418, Endian.little);
  const seed = 0x12345678;
  final iv = Uint8List(8);
  final ivData = ByteData.sublistView(iv);
  ivData.setUint32(0, seed ^ 0xDEADBEEF, Endian.little);
  ivData.setUint32(4, seed, Endian.little);
  final cipher = Salsa20Engine()
    ..init(
      true,
      ParametersWithIV(
        KeyParameter(
          Uint8List.fromList(
            utf8
                .encode('Simulator Interface Packet GT7 ver 0.0')
                .sublist(0, 32),
          ),
        ),
        iv,
      ),
    );
  final encrypted = cipher.process(plain);
  ByteData.sublistView(encrypted).setUint32(0x40, seed, Endian.little);
  return encrypted;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppSettingsService settings;
  late FakeDiscovery discovery;
  late FakeTelemetry telemetry;
  late TelemetryConnectionRepository repo;
  Future<void> setup(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    settings = AppSettingsService();
    await settings.load();
    discovery = FakeDiscovery();
    telemetry = FakeTelemetry();
    repo = TelemetryConnectionRepository(
      settings,
      telemetry,
      discovery,
      waitBudget: const Duration(milliseconds: 100),
    );
    await tester.pump();
  }

  void cleanup() {
    repo.dispose();
    telemetry.dispose();
    settings.dispose();
    discovery.dispose();
  }

  test(
    'real decoder ignores invalid packets, records freshness and resets on reconnect',
    () async {
      final udp = PacketUdp();
      final service = TelemetryService(udpService: udp);
      await service.connectToGT7('127.0.0.1');
      expect(service.receivedAt, isNull);
      udp.onDataReceived!(Uint8List(8));
      expect(service.telemetry, isNull);
      udp.onDataReceived!(encryptedPacket(0));
      expect(service.telemetry?.carId, 3418);
      expect(service.receivedAt, isNotNull);
      await service.disconnect();
      expect(service.receivedAt, isNull);
      await service.connectToGT7('127.0.0.2');
      expect(service.telemetry, isNull);
      udp.onDataReceived!(encryptedPacket(1));
      expect(service.telemetry?.packetId, 1);
      service.dispose();
    },
  );
  testWidgets(
    'default searches; socket is waiting; only packet confirms address; expiry hides live',
    (tester) async {
      await setup(tester);
      expect(repo.phase, ConnectionPhase.waiting);
      expect(settings.confirmedConsole, isNull);
      telemetry.packet();
      await tester.pump();
      expect(repo.phase, ConnectionPhase.live);
      expect(settings.confirmedConsole, '127.0.0.1');
      telemetry.receivedAt = DateTime.now().subtract(
        const Duration(seconds: 6),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(repo.phase, ConnectionPhase.lost);
      await repo.disconnect();
      await tester.pump(const Duration(seconds: 40));
      expect(telemetry.attempts, 1);
      cleanup();
    },
  );
  testWidgets('disabled setting persists and re-enable starts discovery', (
    tester,
  ) async {
    await setup(tester, prefs: {AppSettingsService.autoTelemetryKey: false});
    expect(discovery.rounds, 0);
    await settings.setAutoTelemetry(true);
    await tester.pump();
    expect(discovery.rounds, 1);
    await settings.setAutoTelemetry(false);
    await tester.pump();
    expect(
      (await SharedPreferences.getInstance()).getBool(
        AppSettingsService.autoTelemetryKey,
      ),
      false,
    );
    expect(telemetry.connected, false);
    cleanup();
  });
  testWidgets(
    'multiple candidates require selection, never arbitrary automatic connection',
    (tester) async {
      await setup(tester, prefs: {AppSettingsService.autoTelemetryKey: false});
      discovery.result = [
        ps5,
        const ConsoleCandidate(
          address: '127.0.0.2',
          id: 'two',
          name: 'PS4',
          platform: 'PS4',
          active: true,
        ),
      ];
      await repo.search(explicit: true);
      expect(repo.phase, ConnectionPhase.choose);
      expect(telemetry.attempts, 0);
      await repo.connectManual('127.0.0.2');
      expect(telemetry.connectedAddress, '127.0.0.2');
      cleanup();
    },
  );
  testWidgets(
    'late discovery cannot override manual connection or restart after background',
    (tester) async {
      await setup(tester, prefs: {AppSettingsService.autoTelemetryKey: false});
      discovery.pending = Completer();
      final search = repo.search(explicit: true);
      await tester.pump();
      await repo.connectManual('127.0.0.3');
      discovery.pending!.complete([ps5]);
      await search;
      expect(telemetry.connectedAddress, '127.0.0.3');
      expect(telemetry.attempts, 1);
      repo.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 40));
      expect(telemetry.attempts, 1);
      cleanup();
    },
  );
  testWidgets(
    'turning auto off preserves live connection and demo prevents automatic attempts',
    (tester) async {
      await setup(tester);
      telemetry.packet();
      await tester.pump();
      await settings.setAutoTelemetry(false);
      expect(telemetry.connected, true);
      expect(repo.phase, ConnectionPhase.live);
      await repo.startDemo();
      await settings.setAutoTelemetry(true);
      await tester.pump();
      expect(repo.phase, ConnectionPhase.demo);
      expect(telemetry.attempts, 1);
      cleanup();
    },
  );
  testWidgets('background cancels a pending automatic attempt and late reply', (
    tester,
  ) async {
    await setup(tester, prefs: {AppSettingsService.autoTelemetryKey: false});
    discovery.pending = Completer();
    await settings.setAutoTelemetry(true);
    await tester.pump();
    repo.didChangeAppLifecycleState(AppLifecycleState.paused);
    discovery.pending!.complete([ps5]);
    await tester.pump();
    expect(telemetry.attempts, 0);
    await tester.pump(const Duration(seconds: 40));
    expect(telemetry.attempts, 0);
    cleanup();
  });
  testWidgets(
    'no telemetry times out without confirming address; retry is bounded',
    (tester) async {
      await setup(tester);
      await tester.pump(const Duration(milliseconds: 101));
      await tester.pump();
      expect(settings.confirmedConsole, isNull);
      expect(repo.phase, ConnectionPhase.lost);
      expect(telemetry.connected, false);
      await tester.pump(const Duration(seconds: 29));
      expect(telemetry.attempts, 1);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(telemetry.attempts, 2);
      cleanup();
    },
  );
  testWidgets('late results after disabling automatic connection are ignored', (
    tester,
  ) async {
    await setup(tester, prefs: {AppSettingsService.autoTelemetryKey: false});
    discovery.pending = Completer();
    await settings.setAutoTelemetry(true);
    await tester.pump();
    await settings.setAutoTelemetry(false);
    discovery.pending!.complete([ps5]);
    await tester.pump();
    expect(telemetry.attempts, 0);
    expect(repo.phase, ConnectionPhase.manual);
    cleanup();
  });
}
