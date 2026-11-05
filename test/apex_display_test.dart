import 'package:gt7_companion/services/app_settings_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gt7_companion/models/apex/apex_content.dart';
import 'package:gt7_companion/dependency_injection/app_scope.dart';
import 'package:gt7_companion/router/app_router.dart';
import 'package:gt7_companion/services/apex_service.dart';
import 'package:gt7_companion/widgets/apex/apex_display.dart';
import 'package:gt7_companion/widgets/apex/apex_theme.dart';
import 'package:gt7_companion/widgets/home/service_menu.dart';
import 'package:gt7_companion/pages/home_shell.dart';
import 'package:gt7_companion/widgets/adaptive_navbar.dart';
import 'package:gt7_companion/services/music_service.dart';
import 'package:gt7_companion/services/sound_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

String menuFixture() => File('test/fixtures/apex/menu.json').readAsStringSync();
http.Response response(String body) => http.Response(
  body,
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
http.Response articleResponse(String title) => response(
  jsonEncode({
    'html':
        '<div class="manual_detail"><h1>$title</h1><p>Проверенный текст статьи.</p><h2>Заголовок раздела</h2><p>Второй абзац.</p></div>',
  }),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      AppSettingsService.autoTelemetryKey: false,
    }),
  );
  Future<void> pumpReader(
    WidgetTester tester,
    ApexService service,
    double width, {
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: service),
          ChangeNotifierProvider(create: (_) => SoundService(enabled: false)),
          ChangeNotifierProvider(create: (_) => MusicService(enabled: false)),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const ApexDisplay(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'global language switches official content; reader has no local selector',
    (tester) async {
      final settings = AppSettingsService(systemLocales: const [Locale('ru')]);
      addTearDown(settings.dispose);
      await settings.load();
      final paths = <String>[];
      final service = ApexService(
        appSettings: settings,
        systemLocales: const [Locale('ru')],
        httpClient: MockClient((r) async {
          paths.add(r.url.path);
          if (r.url.path.endsWith('/apex/')) {
            return response(
              File(
                r.url.path.startsWith('/ru/')
                    ? 'test/fixtures/apex/menu.json'
                    : 'test/fixtures/apex/menu-en.json',
              ).readAsStringSync(),
            );
          }
          return articleResponse('Статья');
        }),
      );
      addTearDown(service.dispose);
      await pumpReader(tester, service, 390);
      expect(find.byKey(const ValueKey('apex-language')), findsNothing);
      await settings.setLanguage(AppLanguage.english);
      await tester.pumpAndSettle();
      expect(service.language.siteLocale, 'us');
      expect(service.chapters.first.title, startsWith('Chapter'));
      expect(paths.last, startsWith('/us/'));
      await settings.setLanguage(AppLanguage.system);
      await tester.pumpAndSettle();
      expect(service.language.siteLocale, 'ru');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('AppScope registers the Apex data source centrally', (
    tester,
  ) async {
    ApexService? resolved;
    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          child: Builder(
            builder: (context) {
              resolved = context.read<ApexService>();
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(resolved, isA<ApexService>());
    expect(resolved!.chapters, isEmpty);
  });

  for (final width in [320.0, 390.0, 600.0, 768.0, 1024.0, 1280.0, 1920.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('reader selects real article at $width scale $scale', (
        tester,
      ) async {
        final requested = <String>[];
        final service = ApexService(
          systemLocales: const [Locale('ru')],
          httpClient: MockClient((r) async {
            if (r.url.path.endsWith('/apex/')) return response(menuFixture());
            requested.add(r.url.queryParameters['u']!);
            return articleResponse('Статья');
          }),
        );
        addTearDown(service.dispose);
        await pumpReader(tester, service, width, scale: scale);
        if (width < 1000 || scale > 1.25) {
          expect(
            find.byKey(const ValueKey('apex-contents-button')),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const ValueKey('apex-contents-button')));
          await tester.pumpAndSettle();
        } else {
          expect(
            find.byKey(const ValueKey('apex-contents-button')),
            findsNothing,
          );
        }
        final chapter = find.byKey(const ValueKey('apex-chapter-0'));
        await tester.tap(chapter);
        await tester.pumpAndSettle();
        final first = service.chapters.first.sections.first.articles.first;
        final article = find.byKey(ValueKey('apex-article-${first.path}'));
        await tester.ensureVisible(article);
        await tester.tap(article);
        await tester.pumpAndSettle();
        expect(service.selected.path, first.path);
        expect(requested, contains(first.path));
        expect(find.text('Проверенный текст статьи.'), findsOneWidget);
        expect(find.byType(Drawer), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'a failed load shows retry and the real retry button restores reading',
    (tester) async {
      var fail = true;
      final service = ApexService(
        systemLocales: const [Locale('ru')],
        httpClient: MockClient(
          (r) async => fail
              ? http.Response('', 503)
              : r.url.path.endsWith('/apex/')
              ? response(menuFixture())
              : articleResponse('Статья'),
        ),
      );
      addTearDown(service.dispose);
      await pumpReader(tester, service, 390);
      expect(find.byKey(const ValueKey('apex-retry')), findsOneWidget);
      fail = false;
      await tester.tap(find.byKey(const ValueKey('apex-retry')));
      await tester.pumpAndSettle();
      expect(find.text('Проверенный текст статьи.'), findsOneWidget);
      expect(service.error, isNull);
    },
  );
  testWidgets('loading is visible until the network response arrives', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    final service = ApexService(
      systemLocales: const [Locale('ru')],
      httpClient: MockClient((r) => pending.future),
    );
    addTearDown(service.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: service),
          ChangeNotifierProvider(create: (_) => SoundService(enabled: false)),
          ChangeNotifierProvider(create: (_) => MusicService(enabled: false)),
        ],
        child: const MaterialApp(home: ApexDisplay()),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(http.Response('', 503));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('apex-retry')), findsOneWidget);
  });
  testWidgets(
    'GT menu opens Apex inside the shared shell and restores the previous section',
    (tester) async {
      final service = ApexService(
        systemLocales: const [Locale('ru')],
        httpClient: MockClient(
          (r) async => r.url.path.endsWith('/apex/')
              ? response(menuFixture())
              : articleResponse('Статья'),
        ),
      );
      addTearDown(service.dispose);
      late TabsRouter tabs;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: PageInfo.builder(
              'TestTabs',
              builder: (context, _) => AutoTabsRouter(
                routes: const [HomeShellRoute(), WishlistPageRoute()],
                builder: (context, child) {
                  tabs = AutoTabsRouter.of(context);
                  return Scaffold(appBar: const AdaptiveNavBar(), body: child);
                },
              ),
            ),
            children: [
              AutoRoute(
                page: HomeShellRoute.page,
                initial: true,
                children: [
                  AutoRoute(
                    initial: true,
                    page: PageInfo.builder(
                      'TestHome',
                      builder: (context, _) => ServiceMenu(
                        onBrandCentral: () {},
                        onUsed: () {},
                        onLegendary: () {},
                        onGTAuto: () {},
                      ),
                    ),
                  ),
                  AutoRoute(
                    page: PageInfo.builder(
                      'TestDealer',
                      builder: (context, _) =>
                          const Text('Dealer state retained'),
                    ),
                  ),
                  AutoRoute(page: ApexDisplayRoute.page, path: 'apex'),
                ],
              ),
              AutoRoute(
                page: PageInfo.builder(
                  WishlistPageRoute.name,
                  builder: (context, _) => const Text('Wishlist retained'),
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: service),
            ChangeNotifierProvider(create: (_) => SoundService(enabled: false)),
            ChangeNotifierProvider(create: (_) => MusicService(enabled: false)),
          ],
          child: MaterialApp.router(routerConfig: router.config()),
        ),
      );
      await tester.pumpAndSettle();
      final navbar = tester.element(find.byType(AdaptiveNavBar));
      final home = tabs.stackRouterOfIndex(0)!;
      for (final previousTab in [0, 1]) {
        if (previousTab == 1) {
          home.push(PageRouteInfo('TestDealer'));
          await tester.pumpAndSettle();
        }
        tabs.setActiveIndex(previousTab);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('gt-menu-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('gt-menu-apex')));
        await tester.pumpAndSettle();
        expect(find.byType(ApexDisplay), findsOneWidget);
        expect(
          router.stack.length,
          1,
          reason: 'Apex belongs to the home stack',
        );
        expect(home.current.name, ApexDisplayRoute.name);
        expect(tester.element(find.byType(AdaptiveNavBar)), same(navbar));
        expect(find.byType(AdaptiveNavBar), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('apex-close')));
        await tester.pumpAndSettle();
        expect(tabs.activeIndex, previousTab);
        expect(find.byType(ApexDisplay), findsNothing);
        expect(
          find.text(previousTab == 0 ? 'Brand Central' : 'Wishlist retained'),
          findsOneWidget,
        );
        if (previousTab == 1) {
          tabs.setActiveIndex(0);
          await tester.pumpAndSettle();
          expect(find.text('Dealer state retained'), findsOneWidget);
        }
      }
      final routes = AppRouter().routes;
      expect(routes.any((r) => r.page.name == ApexDisplayRoute.name), isFalse);
      final shell = routes
          .firstWhere((r) => r.page.name == NestedWidgetRoute.name)
          .children!
          .firstWhere((r) => r.page.name == HomeShellRoute.name);
      expect(
        shell.children!.any((r) => r.page.name == ApexDisplayRoute.name),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS, TargetPlatform.iOS}),
  );
  testWidgets('next and previous navigate actual article selections', (
    tester,
  ) async {
    final service = ApexService(
      systemLocales: const [Locale('ru')],
      httpClient: MockClient(
        (r) async => r.url.path.endsWith('/apex/')
            ? response(menuFixture())
            : articleResponse('Статья'),
      ),
    );
    addTearDown(service.dispose);
    await pumpReader(tester, service, 1024);
    await tester.tap(find.byKey(const ValueKey('apex-next')));
    await tester.pumpAndSettle();
    expect(service.selected.path, service.articles.first.path);
    await tester.tap(find.byKey(const ValueKey('apex-previous')));
    await tester.pumpAndSettle();
    expect(service.selected.path, ApexArticleRef.introduction.path);
  });
  testWidgets(
    'official cover leads the light magazine inside a dark application',
    (tester) async {
      final service = ApexService(
        systemLocales: const [Locale('ru')],
        httpClient: MockClient(
          (r) async => r.url.path.endsWith('/apex/')
              ? response(menuFixture())
              : response(
                  File(
                    'test/fixtures/apex/introduction.json',
                  ).readAsStringSync(),
                ),
        ),
      );
      addTearDown(service.dispose);
      await pumpReader(tester, service, 1280);
      final outerContext = tester.element(find.byType(ApexDisplay));
      final innerContext = tester.element(find.byType(Scaffold).last);
      expect(Theme.of(outerContext).brightness, Brightness.dark);
      expect(Theme.of(innerContext).colorScheme.brightness, Brightness.light);
      expect(Theme.of(innerContext).scaffoldBackgroundColor, apexPaper);
      expect(Theme.of(innerContext).appBarTheme.backgroundColor, apexInk);
      expect(
        Theme.of(innerContext).colorScheme.surfaceContainerLow,
        apexChapterSurface,
      );
      expect(
        find.byType(AdaptiveNavBar),
        findsNothing,
        reason: 'navigation belongs to the surrounding shell',
      );
      expect(find.byKey(const ValueKey('apex-close')), findsOneWidget);
      expect(find.byKey(const ValueKey('apex-contents-rail')), findsOneWidget);
      expect(
        find.text('Beyond the Apex'),
        findsOneWidget,
        reason:
            'the page header identifies the magazine below global navigation',
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is NetworkImage &&
              (w.image as NetworkImage).url.endsWith('/apex/main_apex.jpg'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
