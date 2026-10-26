import 'dart:convert';
import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/l10n/ui_messages.dart';
import 'package:gt7_companion/router/app_router.dart';
import 'package:gt7_companion/services/app_settings_service.dart';
import 'package:gt7_companion/services/sound_service.dart';
import 'package:gt7_companion/services/music_service.dart';
import 'package:gt7_companion/widgets/adaptive_navbar.dart';
import 'package:gt7_companion/widgets/settings/settings_display.dart';
import 'package:gt7_companion/theme/gt7_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => Intl.defaultLocale = null);
  test('system default, unsupported fallback and live OS changes', () async {
    final settings = AppSettingsService(
      systemLocales: const [Locale('ru', 'RU')],
    );
    addTearDown(settings.dispose);
    await settings.load();
    expect(settings.language, AppLanguage.system);
    expect(settings.locale, isNull);
    expect(settings.effectiveLocale.languageCode, 'ru');
    settings.didChangeLocales(const [Locale('de')]);
    expect(settings.effectiveLocale.languageCode, 'en');
    settings.didChangeLocales(const [Locale('fr'), Locale('ru')]);
    expect(settings.effectiveLocale.languageCode, 'ru');
    await settings.setLanguage(AppLanguage.english);
    settings.didChangeLocales(const [Locale('ru')]);
    expect(settings.effectiveLocale.languageCode, 'en');
    await settings.setLanguage(AppLanguage.system);
    expect(settings.effectiveLocale.languageCode, 'ru');
  });
  test('rapid choices persist in order and restore on a new service', () async {
    final settings = AppSettingsService();
    addTearDown(settings.dispose);
    await settings.load();
    await Future.wait([
      settings.setLanguage(AppLanguage.russian),
      settings.setLanguage(AppLanguage.english),
      settings.setLanguage(AppLanguage.russian),
    ]);
    final restored = AppSettingsService(systemLocales: const [Locale('en')]);
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.language, AppLanguage.russian);
    expect(restored.effectiveLocale.languageCode, 'ru');
    expect(Intl.defaultLocale, 'ru');
  });
  test('obsolete or invalid preference falls back to System', () async {
    SharedPreferences.setMockInitialValues({
      AppSettingsService.languageKey: 'deleted',
      'apex_content_language': 'de',
    });
    final settings = AppSettingsService(systemLocales: const [Locale('ru')]);
    addTearDown(settings.dispose);
    await settings.load();
    expect(settings.language, AppLanguage.system);
    expect(settings.effectiveLocale.languageCode, 'ru');
  });
  test(
    'resources have matching keys/placeholders and real Russian plurals',
    () {
      final en =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
      final ru =
          jsonDecode(File('lib/l10n/app_ru.arb').readAsStringSync()) as Map;
      expect(ru.keys.toSet(), en.keys.toSet());
      for (final key in en.keys.where((k) => !k.startsWith('@'))) {
        expect((ru[key] as String).trim(), isNotEmpty, reason: key);
        expect(ru['@$key'], en['@$key'], reason: 'placeholder schema $key');
      }
      final l = lookupAppLocalizations(const Locale('ru'));
      expect(l.carCount(1), '1 автомобиль');
      expect(l.carCount(2), '2 автомобиля');
      expect(l.carCount(5), '5 автомобилей');
      expect(l.uiText('BRAKING'), 'ТОРМОЖЕНИЕ');
      expect(l.uiText('TOP SPEED EST. 300 KM/H'), contains('300'));
      expect(l.uiText('Ferrari F40 ’92'), 'Ferrari F40 ’92');
    },
  );

  Future<void> show(
    WidgetTester tester,
    AppSettingsService settings,
    Widget home, {
    RootStackRouter? router,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sound = SoundService(enabled: false);
    final music = MusicService(enabled: false);
    addTearDown(sound.dispose);
    addTearDown(music.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: sound),
          ChangeNotifierProvider.value(value: music),
        ],
        child: Consumer<AppSettingsService>(
          builder: (context, value, _) {
            Widget builder(BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.5)),
              child: child!,
            );
            return router == null
                ? MaterialApp(
                    theme: gt7Theme(),
                    locale: value.effectiveLocale,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    builder: builder,
                    home: home,
                  )
                : MaterialApp.router(
                    theme: gt7Theme(),
                    locale: value.effectiveLocale,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    builder: builder,
                    routerConfig: router.config(),
                  );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 390.0, 600.0, 820.0, 1280.0, 1920.0]) {
    for (final locale in ['ru', 'en']) {
      testWidgets(
        'settings $locale fits $width at scale 1.5 and changes language',
        (tester) async {
          final settings = AppSettingsService(systemLocales: [Locale(locale)]);
          addTearDown(settings.dispose);
          await settings.load();
          await show(tester, settings, const SettingsDisplay(), width: width);
          await tester.tap(
            find.byKey(const ValueKey('settings-language-card')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('settings-language-system')),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(const ValueKey('settings-language-russian')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Настройки'), findsOneWidget);
          for (final tab in [1, 2, 0]) {
            await tester.tap(find.byKey(ValueKey('settings-tab-$tab')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.tap(
            find.byKey(const ValueKey('settings-language-card')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('settings-language-english')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Settings'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets(
    'GT menu opens settings and close restores route and entered text',
    (tester) async {
      final settings = AppSettingsService(systemLocales: const [Locale('en')]);
      addTearDown(settings.dispose);
      await settings.load();
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: PageInfo.builder(
              'Original',
              builder: (_, _) => const Scaffold(
                appBar: AdaptiveNavBar(),
                body: TextField(key: ValueKey('retained-field')),
              ),
            ),
          ),
          AutoRoute(page: SettingsDisplayRoute.page, path: '/settings'),
        ],
      );
      addTearDown(router.dispose);
      await show(
        tester,
        settings,
        const SizedBox(),
        router: router,
        width: 1000,
      );
      await tester.enterText(
        find.byKey(const ValueKey('retained-field')),
        'F40 build',
      );
      await tester.tap(find.byKey(const ValueKey('gt-menu-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('gt-menu-settings')));
      await tester.pumpAndSettle();
      expect(router.current.name, SettingsDisplayRoute.name);
      await tester.tap(find.byKey(const ValueKey('settings-language-card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-language-russian')));
      await tester.pumpAndSettle();
      expect(router.current.name, SettingsDisplayRoute.name);
      await tester.tap(find.byKey(const ValueKey('settings-close')));
      await tester.pumpAndSettle();
      expect(router.current.name, 'Original');
      expect(find.text('F40 build'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('gt-menu-button')));
      await tester.pumpAndSettle();
      expect(find.text('Настройки'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('gt-menu-close')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS, TargetPlatform.iOS}),
  );
}
