import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gt7_companion/repositories/wishlist_repository.dart';

class RejectingPreferences extends Fake implements SharedPreferences {
  bool reject = true;
  @override
  List<String>? getStringList(String key) => ['car1523'];
  @override
  Future<bool> setStringList(String key, List<String> value) async => !reject;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('membership persists across fresh repository and removal', () async {
    final first = WishlistRepository();
    addTearDown(first.dispose);
    await first.load();
    expect(await first.toggle('car1523'), isTrue);
    final restored = WishlistRepository();
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.ids, ['car1523']);
    await restored.toggle('car1523');
    final empty = WishlistRepository();
    addTearDown(empty.dispose);
    await empty.load();
    expect(empty.ids, isEmpty);
  });
  test(
    'queued rapid toggles do not lose updates or corrupt saved IDs',
    () async {
      final repo = WishlistRepository();
      addTearDown(repo.dispose);
      await Future.wait([
        repo.toggle('car1523'),
        repo.toggle('car102'),
        repo.toggle('car1523'),
      ]);
      expect(repo.ids, ['car102']);
      expect(await repo.toggle('../bad'), isFalse);
      final restored = WishlistRepository();
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.ids, ['car102']);
    },
  );
  test(
    'rejected write preserves previous state and retry can recover',
    () async {
      final prefs = RejectingPreferences();
      final repo = WishlistRepository(preferences: () async => prefs);
      addTearDown(repo.dispose);
      await repo.load();
      expect(await repo.toggle('car102'), isFalse);
      expect(repo.ids, ['car1523']);
      expect(repo.error, isNotNull);
      prefs.reject = false;
      expect(await repo.toggle('car102'), isTrue);
      expect(repo.ids, ['car1523', 'car102']);
      expect(repo.error, isNull);
    },
  );
  test('restore removes malformed and duplicate identifiers', () async {
    SharedPreferences.setMockInitialValues({
      WishlistRepository.storageKey: ['car102', 'car102', 'not-a-car'],
    });
    final repo = WishlistRepository();
    addTearDown(repo.dispose);
    await repo.load();
    expect(repo.ids, ['car102']);
  });
}
