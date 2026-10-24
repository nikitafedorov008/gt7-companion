import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gt7_companion/models/gt_auto/gt_auto_data.dart';
import 'package:gt7_companion/repositories/car_catalog.dart';
import 'package:gt7_companion/repositories/gt_auto_repository.dart';
import 'package:gt7_companion/services/gt_auto_parts_service.dart';
import 'package:gt7_companion/services/gtplus_service.dart';

String gtPlusFixture() =>
    File('test/fixtures/gt_auto/gtplus.html').readAsStringSync();
String partsFixture() =>
    File('test/fixtures/gt_auto/special-parts.csv').readAsStringSync();

Future<GtAutoRepository> workshopRepository({
  http.Client? plusClient,
  http.Client? partsClient,
  CarCatalog? catalog,
}) async {
  final repo = GtAutoRepository(
    catalog ?? CarCatalog(),
    GtPlusService(
      httpClient:
          plusClient ??
          MockClient((_) async => http.Response(gtPlusFixture(), 200)),
    ),
    GtAutoPartsService(
      httpClient:
          partsClient ??
          MockClient(
            (_) async => http.Response(
              partsFixture(),
              200,
              headers: {'content-type': 'text/csv; charset=utf-8'},
            ),
          ),
    ),
  );
  await repo.load();
  return repo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final date = DateTime.utc(2026, 10, 25);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Flight parsing joins split scripts and resolves repeated car references',
    () {
      final data = GtPlusService.parse(gtPlusFixture(), fetchedAt: date);
      expect(data.swaps, hasLength(2));
      expect(data.swaps.every((swap) => swap.carId == 'car1448'), isTrue);
      expect(
        data.swaps.map((s) => s.engine),
        containsAll(['2JZ-GTE-Supra', 'VR38DETT-GT-R-NISMO']),
      );
      expect(data.swaps.last.powerHp, 591);
      expect(data.swaps.first.donor, contains('Supra'));
      expect(data.specs['car1448']!.engine, isNotEmpty);
      expect(data.source.fetchedAt, date);
    },
  );

  test('changed source is an error instead of an empty compatibility list', () {
    expect(
      () => GtPlusService.parse('<html>Maintenance</html>', fetchedAt: date),
      throwsFormatException,
    );
    expect(
      () => GtAutoPartsService.parse('<html>Login</html>', fetchedAt: date),
      throwsFormatException,
    );
  });

  test('real CSV preserves quoted multiline header and S15 compatibility', () {
    final data = GtAutoPartsService.parse(partsFixture(), fetchedAt: date);
    expect(data.cars.length, greaterThan(500));
    final s15 = data.cars.singleWhere(
      (c) => c.carName == "Nissan Silvia spec-R Aero (S15) '02",
    );
    expect(s15.compatibility['Titanium Connecting Rods and Pistons'], isTrue);
    expect(s15.compatibility['Carbon Propeller Shaft'], isTrue);
    expect(s15.compatibility['Ultra-High RPM Turbo'], isNull);
  });

  test('unknown and explicit no remain distinct, escaped names parse', () {
    final csv =
        'Car,${GtAutoPartsService.partNames.join(',')},Part Count\r\n'
        '"A ""Special"" Car",No,Yes,,,,,,,1';
    final data = GtAutoPartsService.parse(csv, fetchedAt: date);
    expect(data.cars.single.carName, 'A "Special" Car');
    expect(data.cars.single.compatibility.values.take(3), [false, true, null]);
  });

  test(
    'one failed source preserves official specs and successful swaps',
    () async {
      final repo = await workshopRepository(
        partsClient: MockClient((_) async => http.Response('unavailable', 503)),
      );
      expect(repo.selectedCar?.id, 'car1448');
      expect(repo.swaps, hasLength(2));
      expect(repo.parts, isNull);
      expect(repo.errors.keys, ['Special parts']);
      expect(repo.isLoading, isFalse);
      repo.dispose();
    },
  );

  test(
    'manual refresh retains last good source and recovers from failure',
    () async {
      var fail = false;
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(fail ? 'down' : gtPlusFixture(), fail ? 503 : 200);
      });
      final repo = await workshopRepository(plusClient: client);
      await repo.load();
      expect(requests, 1);
      fail = true;
      await repo.load(forceRefresh: true);
      expect(repo.swaps, hasLength(2));
      expect(repo.errors, contains('GTPlus'));
      fail = false;
      await repo.load(forceRefresh: true);
      expect(repo.errors, isEmpty);
      repo.dispose();
    },
  );

  test(
    'plans persist per car and rapid edits cannot overwrite newer snapshots',
    () async {
      final repo = await workshopRepository();
      final engine = repo.swaps.last.id;
      repo.selectSwap(engine);
      repo.setPart('Carbon Propeller Shaft', true);
      repo.setPart(
        'Ultra-High RPM Turbo',
        true,
      ); // unknown cannot be planned as confirmed
      repo.setNotes('Sprint setup');
      final secondCar = repo.cars.firstWhere((c) => c.id != 'car1448').id;
      repo.selectCar(secondCar);
      expect(repo.build.parts, isEmpty);
      repo.setNotes('Other car');
      await repo.flush();
      final restored = await workshopRepository();
      expect(restored.selectedCar!.id, secondCar);
      expect(restored.build.notes, 'Other car');
      restored.selectCar('car1448');
      expect(restored.build.swapId, engine);
      expect(restored.build.parts, ['Carbon Propeller Shaft']);
      expect(restored.build.notes, 'Sprint setup');
      await restored.flush();
      repo.dispose();
      restored.dispose();
    },
  );

  test('name normalization keeps tuning variants distinct', () {
    expect(
      GtAutoRepository.normalizeName(" Nissan  Silvia ’02 "),
      "nissan silvia '02",
    );
    expect(
      GtAutoRepository.normalizeName('Silvia (S15)'),
      isNot(GtAutoRepository.normalizeName('Silvia (S15) Touring Car')),
    );
  });

  test('unknown optional numbers remain null, never zero', () {
    final specs = GtAutoSpecs.fromJson({'code': 1448, 'modelFull': 'Silvia'});
    expect(specs.powerHp, isNull);
    expect(specs.torqueKgfm, isNull);
  });
}
