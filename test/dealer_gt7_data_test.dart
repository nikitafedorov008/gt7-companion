import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/car_dealer/car.dart';
import 'package:gt7_companion/repositories/dealer_catalog_repository.dart';
import 'package:gt7_companion/services/brand_central_service.dart';

Car sample({
  String id = 'car1523',
  String name = "500 F '68",
  String state = 'normal',
}) => Car(
  id: id,
  name: name,
  shortName: name,
  manufacturer: 'FIAT',
  region: 'it',
  credits: 18800,
  state: state,
  estimateDays: 12,
  maxEstimateDays: 20,
  isNew: false,
  sort: 999,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'exact official join supplies localized specs, never sort as PP',
    () async {
      final source = BrandCentralService();
      final repo = DealerCatalogRepository(source);
      addTearDown(source.dispose);
      addTearDown(repo.dispose);
      await repo.load();
      final ru = repo.details(sample(), 'ru');
      final en = repo.details(sample(), 'en');
      expect(ru.id, 'car1523');
      expect(ru.pp, '112.13');
      expect(ru.pp, isNot('999'));
      expect(ru.specifications['Weight'], '520 кг');
      expect(en.specifications['Weight'], contains('lbs'));
      expect(ru.history, isNotEmpty);
      expect(ru.drive, 'RR');
      expect(en.aspiration, 'NA');
      expect(ru.aspiration, isNot('—'));
      expect(ru.year, '1968');
      expect(repo.details(sample(id: '#CAR1523'), 'ru').pp, ru.pp);
      final unknown = repo.details(sample(id: 'car999999'), 'ru');
      expect(unknown.pp, '—');
      expect(unknown.specifications, isEmpty);
      expect(unknown.history, isEmpty);
    },
  );
  test(
    'rotated-out wishlist car keeps specs but has no invented stock or price',
    () async {
      final source = BrandCentralService();
      final repo = DealerCatalogRepository(source);
      addTearDown(source.dispose);
      addTearDown(repo.dispose);
      await repo.load();
      final car = repo.savedCar('car1523', []);
      expect(car, isNotNull);
      final details = repo.details(car!, 'en');
      expect(details.hasPrice, isFalse);
      expect(details.hasStock, isFalse);
      expect(repo.savedCar('car999999', []), isNull);
    },
  );
}
