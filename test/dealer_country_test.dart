import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gt7_companion/repositories/car_repository.dart';
import 'package:gt7_companion/repositories/dealer_catalog_repository.dart';
import 'package:gt7_companion/services/brand_central_service.dart';
import 'package:gt7_companion/services/gt7info_service.dart';
import 'package:gt7_companion/services/gtdb_service.dart';
import 'package:gt7_companion/services/card_artwork_service.dart';
import 'package:gt7_companion/models/car_dealer/dealer_car_details.dart';
import 'dealer_gt7_data_test.dart' show sample;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'exact official IDs resolve countries; unknown and similar names stay unknown',
    () async {
      final source = BrandCentralService();
      final catalog = DealerCatalogRepository(source);
      addTearDown(source.dispose);
      addTearDown(catalog.dispose);
      await catalog.load();
      for (final id in ['3551', 'car3551', '#CAR3551']) {
        expect(catalog.countryCodeFor(id), 'de');
      }
      expect(catalog.countryCodeFor('car3432'), 'jp');
      expect(catalog.countryCodeFor('car3549'), 'se');
      expect(catalog.countryCodeFor('car3570'), 'us');
      final official =
          jsonDecode(
                await rootBundle.loadString('assets/cars/brand_central.json'),
              )
              as Map<String, dynamic>;
      final countries = <String>{};
      for (final id
          in (official['editions']['en'] as Map).keys.cast<String>()) {
        final code = catalog.countryCodeFor(id);
        if (code.isNotEmpty) countries.add(code);
      }
      expect(
        countries,
        containsAll(['de', 'jp', 'se', 'us', 'gb', 'kr', 'at', 'cz', 'cn']),
      );
      for (final code in countries) {
        final asset = const CardArtworkService().assetFor(
          'https://flagcdn.com/h24/$code.png',
        );
        expect(asset, isNotNull, reason: code);
        expect((await rootBundle.load(asset!)).lengthInBytes, greaterThan(0));
      }
      expect(catalog.countryCodeFor('car999999'), isEmpty);
      expect(catalog.countryCodeFor('BMW M3'), isEmpty);
      final saved = catalog.savedCar('car3551', [])!;
      expect(saved.region, 'de');
      expect(saved.flagUrl, endsWith('/de.png'));
      expect(saved.state, 'unknown');
      expect(saved.credits, 0);
    },
  );

  test(
    'offline merge enriches GTDB-only countries without changing inventory or known countries',
    () async {
      final snapshot =
          jsonDecode(
                await rootBundle.loadString('assets/cars/dealer_snapshot.json'),
              )
              as Map<String, dynamic>;
      final originalRegions = <String, String>{
        for (final section in ['used', 'legend'])
          for (final row in snapshot['gt7info'][section]['cars'])
            DealerCarDetails.canonicalId(row['carid'] as String):
                row['region'] as String,
      };
      http.Client offline() => MockClient((_) async => http.Response('', 503));
      final info = GT7InfoService(httpClient: offline());
      final db = GTDBService(httpClient: offline());
      final source = BrandCentralService();
      final catalog = DealerCatalogRepository(source);
      final repo = CarRepository(info, db, catalog: catalog);
      addTearDown(info.dispose);
      addTearDown(db.dispose);
      addTearDown(source.dispose);
      addTearDown(catalog.dispose);
      addTearDown(repo.dispose);
      await repo.fetchAllCars();
      expect(repo.errorMessage, isNotEmpty);
      final ids = repo.allCars.map((c) => DealerCarDetails.canonicalId(c.id));
      expect(ids.toSet().length, repo.allCars.length);
      final onlyDb = repo.allCars.where((c) => c.source == 'gtdb_used');
      expect(onlyDb, isNotEmpty);
      for (final car in repo.allCars) {
        final id = DealerCarDetails.canonicalId(car.id);
        expect(
          car.region,
          originalRegions[id] ?? catalog.countryCodeFor(id),
          reason: car.name,
        );
        expect(car.flagUrl, isNotEmpty, reason: car.name);
      }
      expect(
        repo.allCars
            .firstWhere((c) => DealerCarDetails.canonicalId(c.id) == 'car3551')
            .region,
        'de',
      );
      expect(
        repo.allCars
            .firstWhere((c) => DealerCarDetails.canonicalId(c.id) == 'car3432')
            .region,
        'jp',
      );
      final fromDb = onlyDb.first;
      final copied = fromDb.withRegion('xx');
      expect(copied.name, fromDb.name);
      expect(copied.carImageUrl, fromDb.carImageUrl);
      expect(copied.credits, fromDb.credits);
      expect(copied.state, fromDb.state);
      expect(copied.source, fromDb.source);
      expect(copied.sort, fromDb.sort);
    },
  );

  test(
    'missing catalogue does not invent a country or lose dealer rows',
    () async {
      http.Client offline() => MockClient((_) async => http.Response('', 503));
      final source = BrandCentralService(bundle: _UnavailableBundle());
      final catalog = DealerCatalogRepository(source);
      final info = GT7InfoService(httpClient: offline());
      final db = GTDBService(httpClient: offline());
      final repo = CarRepository(info, db, catalog: catalog);
      addTearDown(source.dispose);
      addTearDown(catalog.dispose);
      addTearDown(info.dispose);
      addTearDown(db.dispose);
      addTearDown(repo.dispose);
      await repo.fetchAllCars();
      expect(catalog.error, isNotNull);
      expect(repo.getUsedCars(), isNotEmpty);
      expect(repo.getLegendCars(), isNotEmpty);
      expect(
        repo.allCars
            .where((c) => c.source == 'gtdb_used')
            .every((c) => c.region == 'xx'),
        isTrue,
      );
      expect(catalog.countryCodeFor(sample().id), isEmpty);
    },
  );
}

class _UnavailableBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      Future.error(StateError('Catalogue unavailable'));
}
