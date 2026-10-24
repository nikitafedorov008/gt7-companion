import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/apex/apex_language.dart';
import 'package:gt7_companion/models/apex/apex_content.dart';
import 'package:gt7_companion/services/apex_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

String fixture(String name) =>
    File('test/fixtures/apex/$name.json').readAsStringSync();
http.Response response(String body) => http.Response(
  body,
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
http.Response localized(http.Request request) => response(
  fixture(
    request.url.path.endsWith('/apex/')
        ? request.url.path.startsWith('/ru/')
              ? 'menu'
              : 'menu-en'
        : request.url.path.startsWith('/ru/')
        ? 'force'
        : 'force-en',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final entry in <Locale, String>{
    const Locale('ru', 'RU'): 'ru',
    const Locale('en', 'US'): 'us',
    const Locale('en', 'GB'): 'gb',
    const Locale('de', 'AT'): 'de',
    const Locale('pt', 'BR'): 'br',
    const Locale('es', 'MX'): 'mx',
    const Locale('ja', 'JP'): 'jp',
    const Locale('ar', 'SA'): 'sa',
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'): 'tw',
    const Locale('zh', 'HK'): 'tw',
    const Locale('zh', 'CN'): 'cn',
    const Locale('xx'): 'gb',
  }.entries) {
    test(
      'system locale ${entry.key} resolves to ${entry.value}',
      () =>
          expect(ApexLanguage.fromSystem([entry.key]).siteLocale, entry.value),
    );
  }
  test(
    'unsupported preferred locale uses the next supported system language',
    () {
      expect(
        ApexLanguage.fromSystem([
          const Locale('xx'),
          const Locale('ru'),
        ]).siteLocale,
        'ru',
      );
    },
  );
  test('system default drives official API and source links', () async {
    final requested = <Uri>[];
    final service = ApexService(
      systemLocales: const [Locale('en', 'GB')],
      httpClient: MockClient((r) async {
        requested.add(r.url);
        return localized(r);
      }),
    );
    addTearDown(service.dispose);
    await service.load();
    expect(requested.every((uri) => uri.path.startsWith('/gb/')), isTrue);
    expect(service.chapters.first.title, startsWith('Chapter'));
    expect(service.sourceUrl.path, '/gb/gt7/apex/');
    expect(service.followsSystem, isTrue);
  });
  test(
    'language change reloads the same article and its localized title',
    () async {
      final service = ApexService(
        systemLocales: const [Locale('ru')],
        httpClient: MockClient((r) async => localized(r)),
      );
      addTearDown(service.dispose);
      await service.load();
      final force = service.articles.firstWhere(
        (a) => a.path.contains('force_energy_vibration/01'),
      );
      await service.selectArticle(force);
      expect(
        service.article!.blocks.any((b) => b.text.contains('Определение силы')),
        isTrue,
      );
      await service.setLanguage(ApexLanguage.fromSiteLocale('gb'));
      expect(service.selected.path, force.path);
      expect(service.selected.title, isNot(force.title));
      expect(
        service.article!.blocks.any((b) => b.text.contains('Определение силы')),
        isFalse,
      );
      expect(
        service.article!.blocks.any((b) => b.text.contains('force')),
        isTrue,
      );
      expect(service.followsSystem, isFalse);
    },
  );
  test(
    'manual language persists and automatic selection can be restored',
    () async {
      final client = MockClient((r) async => localized(r));
      final service = ApexService(
        systemLocales: const [Locale('ru')],
        httpClient: client,
      );
      addTearDown(service.dispose);
      await service.setLanguage(ApexLanguage.fromSiteLocale('gb'));
      final restored = ApexService(
        systemLocales: const [Locale('ru')],
        httpClient: client,
      );
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.language.siteLocale, 'gb');
      await restored.setLanguage(null);
      expect(restored.language.siteLocale, 'ru');
      expect(restored.followsSystem, isTrue);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          ApexService.languagePrefsKey,
        ),
        isFalse,
      );
    },
  );
  test(
    'system changes update automatic content but preserve a manual override',
    () async {
      final service = ApexService(
        systemLocales: const [Locale('ru')],
        httpClient: MockClient((r) async => localized(r)),
      );
      addTearDown(service.dispose);
      await service.load();
      await service.updateSystemLocales(const [Locale('en', 'GB')]);
      expect(service.language.siteLocale, 'gb');
      await service.setLanguage(ApexLanguage.fromSiteLocale('ru'));
      await service.updateSystemLocales(const [Locale('ja')]);
      expect(service.language.siteLocale, 'ru');
      expect(service.followsSystem, isFalse);
    },
  );
  test(
    'a late response from a previous language never contaminates the new cache',
    () async {
      final slow = Completer<http.Response>();
      var delayRu = false;
      final service = ApexService(
        systemLocales: const [Locale('ru')],
        httpClient: MockClient((r) {
          if (delayRu &&
              r.url.path.contains('/ru/') &&
              r.url.path.contains('apex_v2')) {
            return slow.future;
          }
          return Future.value(localized(r));
        }),
      );
      addTearDown(service.dispose);
      await service.load();
      final ref = service.articles.firstWhere(
        (a) => a.path.contains('force_energy_vibration/01'),
      );
      delayRu = true;
      final pending = service.selectArticle(ref);
      await service.setLanguage(ApexLanguage.fromSiteLocale('gb'));
      slow.complete(response(fixture('force')));
      await pending;
      await service.selectArticle(
        ApexArticleRef(title: 'English', path: ref.path),
      );
      expect(
        service.article!.blocks.any((b) => b.text.contains('Определение силы')),
        isFalse,
      );
      expect(service.language.siteLocale, 'gb');
    },
  );
  test('invalid saved edition falls back to the system', () async {
    SharedPreferences.setMockInitialValues({
      ApexService.languagePrefsKey: 'invalid',
    });
    final service = ApexService(
      systemLocales: const [Locale('ru')],
      httpClient: MockClient((r) async => localized(r)),
    );
    addTearDown(service.dispose);
    await service.load();
    expect(service.language.siteLocale, 'ru');
    expect(service.followsSystem, isTrue);
  });
}
