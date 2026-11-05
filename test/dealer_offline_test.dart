import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/services/gtdb_service.dart';
import 'package:gt7_companion/services/gt7info_service.dart';
import 'package:gt7_companion/repositories/car_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> links;
  setUp(() async {
    links =
        jsonDecode(
              await rootBundle.loadString('assets/cars/dealer_car_links.json'),
            )
            as Map<String, dynamic>;
  });
  test(
    'live Used HTML fixture maps all rows, stock state, artwork and canonical IDs',
    () {
      final rows = GTDBService.parseUsed(
        File('test/fixtures/dealers/used.html').readAsStringSync(),
        links,
      );
      expect(rows.length, 48);
      final fiat = rows.firstWhere((r) => r.slug == '500-f-68');
      expect(fiat.price, 18800);
      expect(fiat.carIdFromDetails, isNotEmpty);
      expect(fiat.imageId, '2bb0b5f3-7981-4303-dfda-ee89cfe06600');
      expect(rows.any((r) => r.state == 'soldout'), isTrue);
      expect(rows.any((r) => r.state == 'limited'), isTrue);
      expect(rows.any((r) => r.imageId == null), isTrue);
      expect(
        () => GTDBService.parseUsed('<html>changed source</html>', links),
        throwsFormatException,
      );
    },
  );

  test(
    'cold offline repository retains both dealers and corrected fallback URLs',
    () async {
      final attempts = <Uri>[];
      http.Client offline() => MockClient((request) async {
        attempts.add(request.url);
        throw const SocketException('Offline verification');
      });
      final info = GT7InfoService(httpClient: offline());
      final gtdb = GTDBService(httpClient: offline());
      final repo = CarRepository(info, gtdb);
      await repo.fetchAllCars();
      expect(repo.getUsedCars(), isNotEmpty);
      expect(repo.getLegendCars(), isNotEmpty);
      expect(repo.dataDate, '2026-11-04');
      expect(repo.errorMessage, isNotEmpty);
      expect(repo.isLoading, isFalse);
      expect(
        repo.allCars.every((c) => !c.thumbnailUrl.contains('carcar')),
        isTrue,
      );
      expect(
        attempts.any((uri) => uri.host == 'api.playstationdb.com'),
        isFalse,
      );
      expect(
        attempts.any((uri) => uri.toString() == GTDBService.usedUrl),
        isTrue,
      );
      repo.dispose();
      info.dispose();
      gtdb.dispose();
    },
  );

  test(
    'bundled cards publish before slow refresh completes; failed refresh preserves them',
    () async {
      final pending = Completer<http.Response>();
      final info = GT7InfoService(
        httpClient: MockClient((_) => pending.future),
      );
      final gtdb = GTDBService(httpClient: MockClient((_) => pending.future));
      final repo = CarRepository(info, gtdb);
      final ready = Completer<void>();
      repo.addListener(() {
        if (repo.allCars.isNotEmpty && !ready.isCompleted) ready.complete();
      });
      final refresh = repo.fetchAllCars();
      await ready.future;
      final count = repo.allCars.length;
      expect(repo.isLoading, isFalse);
      expect(count, greaterThan(30));
      pending.complete(http.Response('', 503));
      await refresh;
      expect(repo.allCars.length, count);
      expect(repo.errorMessage, isNotEmpty);
      repo.dispose();
      info.dispose();
      gtdb.dispose();
    },
  );

  test(
    'one GTDB source failing does not prevent the other source refreshing',
    () async {
      final fixture = File(
        'test/fixtures/dealers/used.html',
      ).readAsStringSync();
      final visited = <String>[];
      final gtdb = GTDBService(
        httpClient: MockClient((request) async {
          visited.add(request.url.toString());
          return request.url.toString() == GTDBService.usedUrl
              ? http.Response(
                  fixture,
                  200,
                  headers: {'content-type': 'text/html; charset=utf-8'},
                )
              : http.Response('', 503);
        }),
      );
      await gtdb.fetchGTDBData();
      expect(gtdb.usedCars.length, 48);
      expect(gtdb.legendaryCars, isNotEmpty);
      expect(gtdb.errorMessage, contains('Legendary'));
      expect(
        visited,
        containsAll([GTDBService.usedUrl, GTDBService.legendUrl]),
      );
      gtdb.dispose();
    },
  );
  test(
    'a changed dealer slug still resolves an exact unambiguous catalogue name',
    () {
      final fixture = File('test/fixtures/dealers/used.html')
          .readAsStringSync()
          .replaceAll('/gt7/car/500-f-68/', '/gt7/car/new-slug-for-fiat/');
      final rows = GTDBService.parseUsed(fixture, links);
      expect(rows.length, 48);
      final fiat = rows.firstWhere((r) => r.slug == 'new-slug-for-fiat');
      expect(fiat.price, 18800);
      expect(fiat.carIdFromDetails, isNotEmpty);
    },
  );
}
