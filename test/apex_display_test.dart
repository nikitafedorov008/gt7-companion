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
import 'package:gt7_companion/widgets/home/service_menu.dart';
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
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
      ChangeNotifierProvider.value(
        value: service,
        child: MaterialApp(
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
        if (width < 880) {
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
        final chapter = find.text('Глава 1: Автомобильная инженерия');
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
      ChangeNotifierProvider.value(
        value: service,
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
    'Apex card pushes the generated reader route and back returns to services',
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
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: PageInfo.builder(
              'TestHome',
              builder: (context, _) => Scaffold(
                body: ServiceMenu(
                  onBrandCentral: () {},
                  onUsed: () {},
                  onLegendary: () {},
                  onGTAuto: () {},
                  onApex: () => context.router.push(const ApexDisplayRoute()),
                ),
              ),
            ),
          ),
          AutoRoute(page: ApexDisplayRoute.page, path: '/apex'),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: MaterialApp.router(routerConfig: router.config()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('service-apex')));
      await tester.pumpAndSettle();
      expect(find.byType(ApexDisplay), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceMenu), findsOneWidget);
      expect(find.byType(ApexDisplay), findsNothing);
      expect(
        AppRouter().routes
            .firstWhere((route) => route.children != null)
            .children!
            .first
            .children!
            .any((r) => r.page.name == ApexDisplayRoute.name),
        isTrue,
      );
    },
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
}
