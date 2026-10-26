import 'package:gt7_companion/l10n/ui_messages.dart';
import 'package:gt7_companion/services/app_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:gt7_companion/router/app_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gt7_companion/models/brand_central/brand_central_data.dart';
import 'package:gt7_companion/services/brand_central_service.dart';
import 'package:gt7_companion/repositories/brand_central_repository.dart';
import 'package:gt7_companion/widgets/brand_central/brand_central_display.dart';
import 'package:gt7_companion/widgets/brand_central/brand_central_background.dart';

class _Source extends BrandCentralService {
  _Source(this.data);
  final BrandCentralData data;
  bool fail = false;
  final pending = <Completer<List<String>>>[];
  bool deferred = false;
  @override
  Future<BrandCentralData> load() async => data;
  @override
  Future<List<String>> gallery(List<String> modules) async {
    if (fail) throw StateError('offline');
    if (deferred) {
      final future = Completer<List<String>>();
      pending.add(future);
      return future.future;
    }
    return List.generate(
      modules.length,
      (i) => 'https://www.gran-turismo.com/photo-$i.jpg',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BrandCentralData data;
  setUpAll(() async {
    data = await BrandCentralService().load();
  });

  test('official joins, coverage, regions and language units', () async {
    expect(data.brands.length, 77);
    expect(data.editions['en']!.length, greaterThanOrEqualTo(580));
    expect(data.brands['tnr28']!.region, 'Asia-Pacific');
    expect(
      data.brands.values
          .where((b) => b.country == 'U.S.')
          .every((b) => b.region == 'North America'),
      isTrue,
    );
    for (final language in ['en', 'ru']) {
      for (final car in data.editions[language]!.values) {
        expect(car.history, isNotEmpty);
        expect(data.gallery[car.id]!.length, inInclusiveRange(3, 6));
      }
    }
    expect(data.editions['ru']!['car102']!.text('weight'), contains('кг'));
    expect(data.editions['en']!['car102']!.text('weight'), contains('lbs'));
  });

  test('search, regions, sort and preserved back navigation', () async {
    final repository = BrandCentralRepository(_Source(data));
    addTearDown(repository.dispose);
    await repository.load();
    repository.search('silvia');
    expect(repository.brands.any((brand) => brand.name == 'Nissan'), isTrue);
    repository.openBrand('tnr28');
    expect(
      repository.cars.every(
        (car) =>
            car.brandId == 'tnr28' && car.name.toLowerCase().contains('silvia'),
      ),
      isTrue,
    );
    final id = repository.cars.first.id;
    await repository.selectCar(id);
    repository.setSystemLanguage('ru');
    expect(repository.selectedCar!.text('weight'), contains('кг'));
    repository.setLanguage('en');
    expect(repository.selectedCar!.text('weight'), contains('lbs'));
    expect(repository.back(), isTrue);
    expect(repository.brandId, 'tnr28');
    expect(repository.query, 'silvia');
    repository.back();
    repository.search('');
    repository.setRegion('North America');
    expect(repository.brands, isNotEmpty);
    expect(repository.brands.every((b) => b.region == 'North America'), isTrue);
    repository.openBrand(null);
    repository.setSort(ShowroomSort.performance);
    expect(
      repository.cars.first.pp,
      greaterThanOrEqualTo(repository.cars.last.pp),
    );
    repository.search('no-such-vehicle-xyz');
    expect(repository.cars, isEmpty);
  });

  test('stale gallery cannot overwrite newer car or back navigation', () async {
    final source = _Source(data)..deferred = true;
    final repository = BrandCentralRepository(source);
    addTearDown(repository.dispose);
    await repository.load();
    final first = repository.selectCar('car102');
    final second = repository.selectCar('car1448');
    source.pending[1].complete(['new']);
    await second;
    source.pending[0].complete(['old']);
    await first;
    expect(repository.carId, 'car1448');
    expect(repository.photos, ['new']);
    final third = repository.selectCar('car102');
    repository.back();
    source.pending[2].complete(['stale']);
    await third;
    expect(repository.carId, isNull);
    expect(repository.photos, isEmpty);
    expect(repository.galleryLoading, isFalse);
  });

  test('gallery failure preserves history and retry recovers', () async {
    final source = _Source(data)..fail = true;
    final repository = BrandCentralRepository(source);
    addTearDown(repository.dispose);
    await repository.load();
    await repository.selectCar('car1448');
    expect(repository.galleryError, isNotNull);
    expect(repository.selectedCar!.history, isNotEmpty);
    source.fail = false;
    await repository.retryGallery();
    expect(repository.galleryError, isNull);
    expect(repository.photos, hasLength(4));
  });

  test(
    'gallery service validates source, caches modules and rejects foreign paths',
    () async {
      var calls = 0;
      final service = BrandCentralService(
        httpClient: MockClient((request) async {
          calls++;
          expect(request.url.host, 'www.gran-turismo.com');
          return http.Response(
            'var x=`/common/dist/gt7/carlist/assets/car1448_1_01-AbC.jpg`;export{x as default}',
            200,
          );
        }),
      );
      addTearDown(service.dispose);
      final modules = ['car1448_1_01-abc.js'];
      expect(await service.gallery(modules), [
        'https://www.gran-turismo.com/common/dist/gt7/carlist/assets/car1448_1_01-AbC.jpg',
      ]);
      await service.gallery(modules);
      expect(calls, 1);
      await expectLater(
        service.gallery(['../../evil.js']),
        throwsFormatException,
      );
      expect(
        () => BrandCentralService.photoUrl('var x=`https://evil.com/car.jpg`'),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'GT7 region step precedes country-grouped manufacturers and back returns to map',
    (tester) async {
      final repository = BrandCentralRepository(_Source(data));
      await repository.load();
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: repository,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const BrandCentralDisplay(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('brand-region-america')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('brand-region-europe')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('brand-region-asia-pacific')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('brand-search')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('brand-region-asia-pacific')));
      await tester.pumpAndSettle();
      expect(find.text('Select a manufacturer'), findsOneWidget);
      expect(
        repository.brands.every((b) => b.region == 'Asia-Pacific'),
        isTrue,
      );
      await tester.enterText(
        find.byKey(const ValueKey('brand-search')),
        'Nissan',
      );
      await tester.pumpAndSettle();
      expect(find.text('JAPAN'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('brand-tnr28')));
      await tester.pumpAndSettle();
      expect(repository.brandId, 'tnr28');
      await tester.tap(find.byKey(const ValueKey('brand-back')));
      await tester.pumpAndSettle();
      expect(repository.regionChosen, isTrue);
      await tester.tap(find.byKey(const ValueKey('brand-back')));
      await tester.pumpAndSettle();
      expect(find.text('Select a region'), findsOneWidget);
      expect(repository.regionChosen, isFalse);
    },
  );

  testWidgets(
    'global language preserves selected manufacturer without local language controls',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettingsService(systemLocales: const [Locale('en')]);
      await settings.load();
      addTearDown(settings.dispose);
      final repository = BrandCentralRepository(
        _Source(data),
        appSettings: settings,
      );
      await repository.load();
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: repository,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const BrandCentralDisplay(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('brand-language')), findsNothing);
      repository.chooseRegion('Europe');
      repository.openBrand(data.brands.values.first.id);
      final brand = repository.brandId;
      for (final language in AppLanguage.values) {
        await settings.setLanguage(language);
        await tester.pumpAndSettle();
        expect(repository.brandId, brand);
        expect(repository.region, 'Europe');
        expect(
          repository.language,
          language == AppLanguage.russian ? 'ru' : 'en',
        );
      }
    },
  );

  testWidgets(
    'ambient lighting respects reduced motion and background lifecycle',
    (tester) async {
      Future<void> show(bool reduced) => tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const BrandCentralBackground(
              child: Center(child: Text('Showroom')),
            ),
          ),
        ),
      );
      await show(false);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await show(true);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.text('Showroom'), findsOneWidget);
    },
  );

  testWidgets(
    'close leaves the entire section from a nested screen without an AppBar',
    (tester) async {
      final repository = BrandCentralRepository(_Source(data));
      await repository.load();
      addTearDown(repository.dispose);
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: PageInfo.builder(
              'TestHome',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  key: const ValueKey('open-brand-central'),
                  onPressed: () =>
                      context.router.push(const BrandCentralDisplayRoute()),
                  child: const Text('Home'),
                ),
              ),
            ),
          ),
          AutoRoute(
            page: BrandCentralDisplayRoute.page,
            path: '/brand-central',
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: repository,
          child: MaterialApp.router(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            routerConfig: router.config(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-brand-central')));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const ValueKey('brand-back')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('brand-region-europe')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('brand-back')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('brand-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('open-brand-central')), findsOneWidget);
      expect(find.byType(BrandCentralDisplay), findsNothing);
    },
  );

  for (final locale in ['en', 'ru']) {
    for (final width in [320.0, 390.0, 600.0, 820.0, 1024.0, 1280.0, 1920.0]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('brands/showroom $locale fit $width with text $scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = BrandCentralRepository(_Source(data));
          await repository.load();
          repository.setLanguage(locale);
          addTearDown(repository.dispose);
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: repository,
              child: MaterialApp(
                locale: Locale(locale),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: ThemeData.dark(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: const BrandCentralDisplay(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(
              lookupAppLocalizations(Locale(locale)).uiText('Select a region'),
            ),
            findsOneWidget,
          );
          expect(
            find.byKey(
              ValueKey(
                width < 888
                    ? 'brand-atrium-portrait'
                    : 'brand-atrium-landscape',
              ),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(
            find.byKey(const ValueKey('brand-all-cars')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('brand-all-cars')));
          await tester.pumpAndSettle();
          expect(
            find.text(
              lookupAppLocalizations(Locale(locale)).uiText('All GT7 cars'),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.enterText(
            find.byKey(const ValueKey('brand-search')),
            'Silvia spec-R',
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('showroom-car1448')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('showroom-car1448')));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Silvia spec-R', findRichText: true),
            findsWidgets,
          );
          expect(tester.takeException(), isNull);
          for (final section in ['Specifications', 'Gallery', 'History']) {
            final tab = find.byKey(ValueKey('showroom-tab-$section'));
            await tester.ensureVisible(tab);
            await tester.tap(tab);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.tap(find.byKey(const ValueKey('brand-back')));
          await tester.pumpAndSettle();
          expect(repository.allCars, isTrue);
          expect(repository.carId, isNull);
          expect(repository.query, 'Silvia spec-R');
          expect(find.byType(CustomScrollView), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
