@Tags(['network'])
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gt7_companion/services/gt7info_service.dart';
import 'package:gt7_companion/services/gtdb_service.dart';
import 'package:gt7_companion/services/gtplus_service.dart';
import 'package:gt7_companion/services/gt_auto_parts_service.dart';
import 'package:gt7_companion/services/apex_service.dart';
import 'package:gt7_companion/services/brand_central_service.dart';

class LiveHttpOverrides extends HttpOverrides {}

void liveTest(String name, Future<void> Function() body) => test(
  name,
  () => HttpOverrides.runWithHttpOverrides(body, LiveHttpOverrides()),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  liveTest('live dealership sources update bundled inventory', () async {
    final info = GT7InfoService();
    final db = GTDBService();
    addTearDown(info.dispose);
    addTearDown(db.dispose);
    await Future.wait([info.loadBundled(), db.loadBundled()]);
    await Future.wait([
      info.fetchGT7InfoData(forceRefresh: true),
      db.fetchGTDBData(forceRefresh: true),
    ]);
    expect(info.errorMessage, isNull);
    expect(info.lastUpdated, isNotNull);
    expect(info.data!.used.cars, isNotEmpty);
    expect(info.data!.legend.cars, isNotEmpty);
    expect(db.errorMessage, isNull);
    expect(db.lastUpdated, isNotNull);
    expect(db.usedCars, isNotEmpty);
    expect(db.legendaryCars, isNotEmpty);
  });
  liveTest('live workshop specs and swaps parse', () async {
    final source = GtPlusService();
    addTearDown(source.dispose);
    final data = await source.fetch();
    expect(data.specs, isNotEmpty);
    expect(data.swaps, isNotEmpty);
  });
  liveTest('live workshop parts parse', () async {
    final source = GtAutoPartsService();
    addTearDown(source.dispose);
    final data = await source.fetch();
    expect(data.cars, isNotEmpty);
  });
  liveTest('live Apex contents and introduction load', () async {
    final source = ApexService();
    addTearDown(source.dispose);
    await source.load(forceRefresh: true);
    expect(source.error, isNull);
    expect(source.chapters, isNotEmpty);
    expect(source.article, isNotNull);
  });
  liveTest(
    'Brand Central bundled catalogue and selected live gallery resolve',
    () async {
      final source = BrandCentralService();
      addTearDown(source.dispose);
      final data = await source.load();
      expect(data.editions['en'], isNotEmpty);
      // The service resolves only selected frames, never downloads a whole gallery catalogue.
      final modules = data.gallery.values.firstWhere((m) => m.isNotEmpty);
      expect(await source.gallery(modules.take(1).toList()), isNotEmpty);
    },
  );
}
