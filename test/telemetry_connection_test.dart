import 'package:flutter/material.dart';
import 'package:gt7_companion/models/telemetry/telemetry_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gt7_companion/services/app_settings_service.dart';
import 'package:gt7_companion/services/console_discovery_service.dart';
import 'package:gt7_companion/repositories/telemetry_connection_repository.dart';
import 'package:gt7_companion/repositories/car_catalog.dart';
import 'package:gt7_companion/l10n/generated/app_localizations.dart';
import 'package:gt7_companion/services/telemetry_service.dart';
import 'package:gt7_companion/services/udp_service.dart';
import 'package:gt7_companion/widgets/telemetry/telemetry_panel.dart';

class _Console extends TelemetryService {
  String? address;
  String? requestedFormat;
  bool connected = false;
  TelemetryData? data;
  @override
  TelemetryData? get telemetry => data;
  void packet(int carId) {
    connected = true;
    receivedAt = DateTime.now();
    data = TelemetryData()
      ..carId = carId
      ..packetType = 'C';
    notifyListeners();
  }

  @override
  bool get isConnected => connected;
  @override
  Future<void> connectToGT7(String ipAddress) async {
    address = ipAddress;
    requestedFormat = packetType;
    connected = true;
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    connected = false;
    notifyListeners();
  }
}

void main() {
  Future<_Console> pump(
    WidgetTester tester, {
    double width = 1440,
    String locale = 'en',
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      AppSettingsService.autoTelemetryKey: false,
    });
    final settings = AppSettingsService();
    await settings.load();
    final service = _Console();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TelemetryService>(create: (_) => service),
          ChangeNotifierProvider<AppSettingsService>(create: (_) => settings),
          ChangeNotifierProvider(create: (_) => CarCatalog()),
          ChangeNotifierProvider(
            create: (_) => TelemetryConnectionRepository(
              settings,
              service,
              ConsoleDiscoveryService(),
            ),
          ),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: TelemetryPanel(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return service;
  }

  test('new listener requests C; manual formats still work', () {
    final udp = UdpService();
    expect(udp.packetType, 'C');
    for (final type in ['A', 'B', '~', 'C']) {
      udp.packetType = type;
      expect(udp.packetType, type);
    }
    udp.packetType = 'invalid';
    expect(udp.packetType, 'C');
  });

  for (final locale in ['en', 'ru']) {
    for (final width in [320.0, 390.0, 800.0, 1280.0, 1440.0]) {
      testWidgets('$locale home and settings fit $width at 1.5 text scale', (
        tester,
      ) async {
        await pump(tester, width: width, locale: locale, scale: 1.5);
        expect(find.byType(TextFormField), findsNothing);
        expect(find.byType(ChoiceChip), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey('telemetry-settings')),
        );
        await tester.tap(find.byKey(const ValueKey('telemetry-settings')));
        await tester.pumpAndSettle();
        expect(find.byType(ChoiceChip), findsNWidgets(4));
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const ValueKey('telemetry-packet-C')),
              )
              .selected,
          isTrue,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('telemetry-settings-submit')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('telemetry-ip')),
          '192.168.1.123',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('telemetry-settings-submit')),
        );
        await tester.tap(
          find.byKey(const ValueKey('telemetry-settings-submit')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'primary button validates IP and passes edited address and format to service',
    (tester) async {
      final service = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('telemetry-connect')));
      await tester.pumpAndSettle();
      final ip = find.byKey(const ValueKey('telemetry-ip'));
      final submit = find.byKey(const ValueKey('telemetry-settings-submit'));
      for (final invalid in [
        '',
        '999.1.1.1',
        'host.local',
        '1.2.3',
        '-1.2.3.4',
      ]) {
        await tester.enterText(ip, invalid);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(service.address, isNull);
        expect(find.byType(Dialog), findsOneWidget);
      }
      await tester.enterText(ip, ' 192.168.0.42 ');
      await tester.tap(find.byKey(const ValueKey('telemetry-packet-~')));
      await tester.pumpAndSettle();
      expect(find.textContaining('344 bytes'), findsOneWidget);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(service.address, '192.168.0.42');
      expect(service.requestedFormat, '~');
      expect(find.text('Waiting for GT7'), findsOneWidget);
      expect(find.text('Open telemetry'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('telemetry-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disconnect').last);
      await tester.pumpAndSettle();
      expect(service.connected, isFalse);
      expect(find.text('Manual'), findsWidgets);
    },
  );

  for (final locale in ['en', 'ru']) {
    for (final width in [320.0, 390.0, 1100.0, 1280.0, 1440.0]) {
      testWidgets('$locale connected and disconnected panel fit $width', (
        tester,
      ) async {
        final service = await pump(tester, width: width, locale: locale);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('telemetry-connect')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('telemetry-ip')),
          '192.168.1.123',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('telemetry-settings-submit')),
        );
        await tester.tap(
          find.byKey(const ValueKey('telemetry-settings-submit')),
        );
        await tester.pumpAndSettle();
        expect(service.requestedFormat, 'C');
        expect(service.address, '192.168.1.123');
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('telemetry-more')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('telemetry-menu-disconnect')),
        );
        await tester.pumpAndSettle();
        expect(service.isConnected, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('cancel discards draft; save applies without opening a socket', (
    tester,
  ) async {
    final service = await pump(tester);
    Future<void> open() async {
      await tester.tap(find.byKey(const ValueKey('telemetry-settings')));
      await tester.pumpAndSettle();
    }

    await open();
    await tester.enterText(
      find.byKey(const ValueKey('telemetry-ip')),
      '10.0.0.12',
    );
    await tester.tap(find.byKey(const ValueKey('telemetry-packet-A')));
    await tester.tap(find.byKey(const ValueKey('telemetry-settings-close')));
    await tester.pumpAndSettle();
    expect(service.packetType, 'C');
    await open();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('telemetry-ip')))
          .controller!
          .text,
      '',
    );
    await tester.enterText(
      find.byKey(const ValueKey('telemetry-ip')),
      '10.0.0.12',
    );
    await tester.tap(find.byKey(const ValueKey('telemetry-packet-B')));
    await tester.tap(find.byKey(const ValueKey('telemetry-settings-submit')));
    await tester.pumpAndSettle();
    expect(service.packetType, 'B');
    expect(service.address, isNull);
    await open();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('telemetry-packet-B')))
          .selected,
      isTrue,
    );
  });

  testWidgets(
    'phone keyboard leaves settings scrollable and submit reachable',
    (tester) async {
      await pump(tester, width: 320, locale: 'ru');
      await tester.tap(find.byKey(const ValueKey('telemetry-connect')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('telemetry-ip')),
        '192.168.1.123',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('telemetry-settings-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('telemetry-settings-submit')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'validated car resolves manufacturer logo; stale and unknown data have honest fallbacks',
    (tester) async {
      final service = await pump(tester, width: 390);
      final context = tester.element(find.byType(TelemetryPanel));
      await tester.runAsync(() => context.read<CarCatalog>().load());
      service.packet(3418);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('telemetry-brand-tnr43')),
        findsOneWidget,
      );
      expect(find.text("Toyota GR Supra RZ '20"), findsWidgets);
      expect(tester.takeException(), isNull);
      service.receivedAt = DateTime.now().subtract(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('telemetry-brand-tnr43')), findsNothing);
      expect(find.text("Toyota GR Supra RZ '20"), findsNothing);
      service.packet(999999);
      await tester.pumpAndSettle();
      expect(find.text('Unknown car · 999999'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('telemetry-connection-art')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
