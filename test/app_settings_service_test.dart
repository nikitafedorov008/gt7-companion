import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gt7_companion/services/app_settings_service.dart';
import 'package:gt7_companion/widgets/settings/settings_display.dart';
import 'package:gt7_companion/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'auto defaults on; rapid preference updates and confirmed target restore',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettingsService();
      await settings.load();
      expect(settings.autoTelemetry, true);
      expect(settings.confirmedConsole, isNull);
      await Future.wait([
        settings.setAutoTelemetry(false),
        settings.setAutoTelemetry(true),
        settings.setAutoTelemetry(false),
      ]);
      await settings.confirmConsole('192.168.1.5');
      final restored = AppSettingsService();
      await restored.load();
      expect(restored.autoTelemetry, false);
      expect(restored.confirmedConsole, '192.168.1.5');
      settings.dispose();
      restored.dispose();
    },
  );
  testWidgets('global Telemetry category exposes persisted auto switch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettingsService();
    await settings.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsDisplay(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-telemetry-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-telemetry-auto')));
    await tester.pumpAndSettle();
    expect(settings.autoTelemetry, false);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        AppSettingsService.autoTelemetryKey,
      ),
      false,
    );
    await tester.tap(find.byKey(const ValueKey('settings-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-telemetry-card')),
      findsOneWidget,
    );
    settings.dispose();
  });
}
