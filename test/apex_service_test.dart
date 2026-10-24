import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gt7_companion/models/apex/apex_content.dart';
import 'package:gt7_companion/services/apex_service.dart';

String fixture(String name) =>
    File('test/fixtures/apex/$name.json').readAsStringSync();
http.Response jsonResponse(String body) => http.Response(
  body,
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
const force = ApexArticleRef(
  title: 'Понятия силы и момента',
  path: '/engineering_for_automotive/force_energy_vibration/01',
);
const engine = ApexArticleRef(
  title: 'Механизмы и принципы работы',
  path: '/review_mechanism/engine/01',
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'official fixtures expose five chapters and real ordered article content',
    () async {
      final service = ApexService(
        systemLocales: const [Locale('ru')],
        httpClient: MockClient(
          (r) async => jsonResponse(
            fixture(
              r.url.path.endsWith('/apex/')
                  ? 'menu'
                  : r.url.queryParameters['u'] == '/top'
                  ? 'introduction'
                  : 'force',
            ),
          ),
        ),
      );
      addTearDown(service.dispose);
      await service.load();
      expect(service.chapters, hasLength(5));
      expect(service.articles.length, 93);
      await service.selectArticle(force);
      final blocks = service.article!.blocks;
      expect(blocks.where((b) => b.kind == ApexBlockKind.image), hasLength(4));
      expect(
        blocks.where((b) => b.kind == ApexBlockKind.caption),
        hasLength(4),
      );
      expect(blocks.any((b) => b.text.contains('F = ma')), isTrue);
      expect(blocks.any((b) => b.text.contains('\n\n')), isTrue);
      expect(blocks.first.text, 'Сила, энергия и колебания');
      expect(
        blocks
            .where((b) => b.imageUrl != null)
            .every((b) => b.imageUrl!.host == 'www.gran-turismo.com'),
        isTrue,
      );
      expect(service.error, isNull);
    },
  );
  test('read articles are cached and explicit refresh fetches again', () async {
    var requests = 0;
    final service = ApexService(
      systemLocales: const [Locale('ru')],
      httpClient: MockClient((r) async {
        requests++;
        return jsonResponse(fixture('force'));
      }),
    );
    addTearDown(service.dispose);
    await service.selectArticle(force);
    await service.selectArticle(force);
    expect(requests, 1);
    await service.selectArticle(force, forceRefresh: true);
    expect(requests, 2);
  });
  test('menu failure is visible and retry restores real contents', () async {
    var fail = true;
    final service = ApexService(
      systemLocales: const [Locale('ru')],
      httpClient: MockClient(
        (r) async => fail
            ? http.Response('offline', 503)
            : jsonResponse(
                fixture(
                  r.url.path.endsWith('/apex/') ? 'menu' : 'introduction',
                ),
              ),
      ),
    );
    addTearDown(service.dispose);
    await service.load();
    expect(service.error, contains('оглавление'));
    expect(service.isLoading, isFalse);
    fail = false;
    await service.load(forceRefresh: true);
    expect(service.error, isNull);
    expect(service.chapters, hasLength(5));
    expect(service.article, isNotNull);
  });
  test('article retry clears a failed response and succeeds', () async {
    var fail = true;
    final service = ApexService(
      systemLocales: const [Locale('ru')],
      httpClient: MockClient(
        (r) async => fail
            ? jsonResponse('{"html":"unexpected"}')
            : jsonResponse(fixture('force')),
      ),
    );
    addTearDown(service.dispose);
    await service.selectArticle(force);
    expect(service.error, contains('статью'));
    expect(service.isLoading, isFalse);
    fail = false;
    await service.selectArticle(force, forceRefresh: true);
    expect(service.error, isNull);
    expect(service.article!.reference.path, force.path);
  });
  test('a late response cannot overwrite a newer selected article', () async {
    final slow = Completer<http.Response>();
    final service = ApexService(
      systemLocales: const [Locale('ru')],
      httpClient: MockClient(
        (r) => r.url.queryParameters['u'] == force.path
            ? slow.future
            : Future.value(jsonResponse(fixture('engine'))),
      ),
    );
    addTearDown(service.dispose);
    final first = service.selectArticle(force);
    await service.selectArticle(engine);
    slow.complete(jsonResponse(fixture('force')));
    await first;
    expect(service.selected.path, engine.path);
    expect(service.article!.reference.path, engine.path);
    expect(service.isLoading, isFalse);
  });
  test('dispose ignores an in-flight response', () async {
    final pending = Completer<http.Response>();
    final service = ApexService(
      systemLocales: const [Locale('ru')],
      httpClient: MockClient((r) => pending.future),
    );
    final load = service.selectArticle(force);
    service.dispose();
    pending.complete(jsonResponse(fixture('force')));
    await expectLater(load, completes);
  });
  test('request timeout becomes a recoverable error', () async {
    final service = ApexService(
      systemLocales: const [Locale('ru')],
      timeout: const Duration(milliseconds: 1),
      httpClient: MockClient((r) => Completer<http.Response>().future),
    );
    addTearDown(service.dispose);
    await service.selectArticle(force);
    expect(service.error, isNotNull);
    expect(service.isLoading, isFalse);
  });
  test('scripts and foreign images are not article content', () {
    final article = ApexService.parseArticle(
      force,
      '<div class="manual_detail"><script>bad()</script><p>Safe<br>text</p><img src="https://evil.test/a.jpg"><img src="javascript:bad()"><img src="/images/c/ok.jpg"></div>',
    );
    expect(article.blocks.map((b) => b.text).join(), 'Safe\ntext');
    expect(
      article.blocks.where((b) => b.kind == ApexBlockKind.image),
      hasLength(1),
    );
  });
  test('invalid article paths never issue a request', () async {
    var requests = 0;
    final service = ApexService(
      systemLocales: const [Locale('ru')],
      httpClient: MockClient((r) async {
        requests++;
        return jsonResponse('{}');
      }),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.selectArticle(
        const ApexArticleRef(title: 'Invalid', path: 'https://evil.test/'),
      ),
      throwsArgumentError,
    );
    expect(requests, 0);
  });
}
