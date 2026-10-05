import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/services/music_player.dart';
import 'package:gt7_companion/services/music_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the audio engine: records what the service asked for and lets a
/// test declare "the track ended", so the rotation can be checked without a device.
class _FakeMusicPlayer implements MusicPlayer {
  final List<String> played = [];
  final List<double> volumes = [];
  int stopCount = 0;
  bool disposed = false;
  void Function()? _onComplete;

  @override
  void onComplete(void Function() callback) => _onComplete = callback;

  @override
  Future<void> play(String asset, {required double volume}) async {
    played.add(asset);
    volumes.add(volume);
  }

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> dispose() async => disposed = true;

  /// Simulates the current track reaching its end.
  void finishTrack() => _onComplete?.call();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeMusicPlayer player;

  setUp(() {
    player = _FakeMusicPlayer();
    SharedPreferences.setMockInitialValues({});
  });

  /// A service whose fade takes no time, so the tests never wait.
  MusicService buildService({bool enabled = true}) => MusicService(
        player: player,
        enabled: enabled,
        fadeDuration: Duration.zero,
      );

  test('music switched off never starts a track', () async {
    final music = buildService(enabled: false);
    addTearDown(music.dispose);

    await music.load();

    expect(player.played, isEmpty);
  });

  test('music switched on starts the first track when it loads', () async {
    final music = buildService();
    addTearDown(music.dispose);

    await music.load();

    expect(player.played, [MusicService.tracks.first]);
  });

  test('switching music off stops playback and is remembered', () async {
    final music = buildService();
    addTearDown(music.dispose);

    await music.load();
    await music.setEnabled(false);

    expect(music.enabled, isFalse);
    expect(player.stopCount, greaterThan(0));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(MusicService.prefsKey), isFalse);
  });

  test('a finished track advances to the next one and wraps around', () async {
    final music = buildService();
    addTearDown(music.dispose);

    await music.load();
    expect(music.currentTrack, MusicService.tracks.first);

    player.finishTrack();
    await Future<void>.delayed(Duration.zero);
    expect(player.played.last, MusicService.tracks[1]);

    player.finishTrack();
    await Future<void>.delayed(Duration.zero);
    expect(player.played.last, MusicService.tracks.first);
  });

  test('a finished track does nothing while music is off', () async {
    final music = buildService(enabled: false);
    addTearDown(music.dispose);

    await music.load();
    player.finishTrack();

    expect(player.played, isEmpty);
  });
}
