import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/sfx.dart';
import 'package:gt7_companion/services/sfx_player.dart';
import 'package:gt7_companion/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the service asked for instead of playing it, so these tests
/// assert the policy without a device and without touching a platform channel.
class _FakeSfxPlayer implements SfxPlayer {
  final List<Sfx> played = [];
  int preloadCount = 0;
  bool disposed = false;

  @override
  Future<void> preload(Iterable<Sfx> sounds) async => preloadCount++;

  @override
  Future<void> play(Sfx sound, {required double volume}) async =>
      played.add(sound);

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  late _FakeSfxPlayer player;

  setUp(() {
    player = _FakeSfxPlayer();
    SharedPreferences.setMockInitialValues({});
  });

  test('a service with sound switched off never calls the player', () {
    final service = SoundService(player: player, enabled: false);

    service.play(Sfx.tap);
    service.play(Sfx.error);

    expect(player.played, isEmpty);
  });

  test('an enabled service plays each effect it is asked for', () {
    final service = SoundService(player: player, enabled: true);

    service.play(Sfx.tap);
    service.play(Sfx.navigate);

    expect(player.played, [Sfx.tap, Sfx.navigate]);
  });

  test('a repeat inside the debounce window is dropped', () {
    final service = SoundService(player: player, enabled: true);

    service.play(Sfx.tap);
    service.play(Sfx.tap);

    expect(player.played, [Sfx.tap]);
  });

  test('switching sound off silences the next press and is remembered', () async {
    final service = SoundService(player: player, enabled: true);

    await service.setEnabled(false);
    service.play(Sfx.tap);

    expect(service.enabled, isFalse);
    expect(player.played, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SoundService.prefsKey), isFalse);
  });

  test('every effect maps to its own asset', () {
    final assets = Sfx.values.map((sound) => sound.asset).toSet();

    expect(assets, hasLength(Sfx.values.length));
    expect(assets.every((asset) => asset.startsWith('assets/sfx/')), isTrue);
  });
}
