import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/telemetry/telemetry_data.dart';
import 'package:gt7_companion/repositories/car_catalog.dart';
import 'package:gt7_companion/widgets/telemetry/car_plate.dart';
import 'package:provider/provider.dart';

/// The packet reports a bare car id, so the HUD depends on the bundled
/// catalogue to name the car and find its picture. These tests pin that
/// contract: the assets load, ids resolve the way the packet means them, and
/// the plate shows up only when there is a car to show.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CarCatalog', () {
    test('loads the bundled catalogue', () async {
      final catalog = CarCatalog();
      expect(catalog.isLoaded, isFalse);

      await catalog.load();

      expect(catalog.isLoaded, isTrue);
      expect(catalog.carCount, greaterThan(500));
    });

    test('resolves the packet car id to the official name and photo', () async {
      final catalog = CarCatalog();
      await catalog.load();

      // 1027 is the DMC DeLorean S2 '04 (the demo telemetry uses it).
      final car = catalog.byPacketId(1027);
      expect(car, isNotNull);
      expect(car!.name, 'DMC DeLorean S2 \'04');
      expect(car.shortName, isNotEmpty);
      expect(car.carClass, isNotEmpty);

      // The plate shows the light official thumbnail; the 4K photo is only a
      // fallback for when that one is unavailable.
      expect(
        catalog.thumbnailUrl(1027),
        'https://www.gran-turismo.com/common/dist/gt7/carlist/'
        'car_thumbnails/car1027.png',
      );

      final url = catalog.photoUrl(1027);
      expect(url, isNotNull);
      expect(url, startsWith('https://www.gran-turismo.com/common/'));
      expect(url, endsWith('.jpg'));
    });

    test('unknown ids answer null instead of throwing', () async {
      final catalog = CarCatalog();
      await catalog.load();

      expect(catalog.byPacketId(0), isNull);
      expect(catalog.byPacketId(999999), isNull);
      expect(catalog.photoUrl(0), isNull);
    });
  });

  _catalogueExtras();

  group('CarPlate', () {
    Future<void> pumpPlate(
      WidgetTester tester,
      CarCatalog catalog,
      int carId,
    ) async {
      final telemetry = TelemetryData()..carId = carId;

      await tester.pumpWidget(
        ChangeNotifierProvider<CarCatalog>.value(
          value: catalog,
          child: MaterialApp(
            home: Scaffold(body: Center(child: CarPlate(telemetry: telemetry))),
          ),
        ),
      );
      await tester.pump();
    }

    /// The catalogue reads bundled assets, which needs real async while the
    /// test binding is faking time.
    Future<CarCatalog> loadedCatalog(WidgetTester tester) async {
      final catalog = CarCatalog();
      await tester.runAsync(catalog.load);
      return catalog;
    }

    testWidgets('names the car the packet reports', (tester) async {
      final catalog = await loadedCatalog(tester);

      await pumpPlate(tester, catalog, 1027);

      expect(find.text('DeLorean S2 \'04'), findsOneWidget);
      expect(find.text('DMC DeLorean S2 \'04'), findsOneWidget);
      expect(find.textContaining('Gr.N'), findsOneWidget);
      // The performance point the game prints comes from the same catalogue.
      expect(find.textContaining('PP '), findsOneWidget);
    });

    testWidgets('stays hidden while the packet carries no car', (tester) async {
      final catalog = await loadedCatalog(tester);

      await pumpPlate(tester, catalog, 0);

      expect(find.textContaining('DeLorean'), findsNothing);
      // A hidden plate draws no panel at all.
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('says so when the id is not in the catalogue', (tester) async {
      final catalog = await loadedCatalog(tester);

      await pumpPlate(tester, catalog, 999999);

      expect(
        find.text('CAR ID 999999 IS NOT IN THE CATALOGUE'),
        findsOneWidget,
      );
    });
  });
}

/// The official catalogue carries more than the name: the performance point the
/// game prints, the drivetrain and the induction. These come from the same
/// hashed module, so they are pinned here too.
void _catalogueExtras() {
  group('car catalogue extras', () {
    test('keeps PP, drivetrain and aspiration', () async {
      final catalog = CarCatalog();
      await catalog.load();

      final car = catalog.byPacketId(1027); // DMC DeLorean S2 '04
      expect(car, isNotNull);
      expect(car!.performancePoints, isNotEmpty);
      expect(double.tryParse(car.performancePoints), isNotNull);
      expect(car.driveTrain, 'RR');
      expect(car.aspiration, 'NA');

      // Every car in the asset should carry a PP, not just this one.
      final withPp = [
        for (final id in [24, 102, 1027, 2054, 3409])
          catalog.byPacketId(id)?.performancePoints ?? '',
      ];
      expect(withPp.where((value) => value.isNotEmpty).length, greaterThan(2));
    });
  });
}
