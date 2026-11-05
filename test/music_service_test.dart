import 'dart:async';

import 'package:flutter/widgets.dart';
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
  int pauseCount = 0;
  int resumeCount = 0;
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
  Future<void> pause() async => pauseCount++;

  @override
  Future<void> resume() async => resumeCount++;

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> dispose() async => disposed = true;

  /// Simulates the current track reaching its end.
  void finishTrack() => _onComplete?.call();
}

class _DelayedMusicPlayer extends _FakeMusicPlayer {
  final ready = Completer<void>();
  bool audible = false;
  @override
  Future<void> play(String asset, {required double volume}) async {
    await ready.future;
    await super.play(asset, volume: volume);
    audible = true;
  }

  @override
  Future<void> pause() async {
    audible = false;
    await super.pause();
  }
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

    for (var i = 1; i <= MusicService.tracks.length; i++) {
      player.finishTrack();
      await Future<void>.delayed(Duration.zero);
      expect(
        player.played.last,
        MusicService.tracks[i % MusicService.tracks.length],
      );
    }
  });

  test('a finished track does nothing while music is off', () async {
    final music = buildService(enabled: false);
    addTearDown(music.dispose);

    await music.load();
    player.finishTrack();

    expect(player.played, isEmpty);
  });

  test('two overlapping starts ask for one player on one track', () async {
    final music = buildService();
    addTearDown(music.dispose);

    // The real sequence: load() starts the track, and the observer's first
    // resumed notification lands while that start is still in flight. Before the
    // guard this asked for two players and the track played in two voices.
    unawaited(music.load());
    music.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(player.played, [MusicService.tracks.first]);
  });

  test('returning to the foreground does not restart the track', () async {
    final music = buildService();
    addTearDown(music.dispose);

    await music.load();
    expect(player.played, hasLength(1));

    music.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    music.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(player.played, hasLength(1), reason: 'no second start');
    expect(player.pauseCount, 1);
    expect(player.resumeCount, 1);
  });
  test(
    'late player load cannot start music after window becomes hidden',
    () async {
      final delayed = _DelayedMusicPlayer();
      final music = MusicService(player: delayed, fadeDuration: Duration.zero);
      addTearDown(music.dispose);
      final load = music.load();
      await Future<void>.delayed(Duration.zero);
      music.didChangeAppLifecycleState(AppLifecycleState.hidden);
      delayed.ready.complete();
      await load;
      await music.flush();
      expect(delayed.audible, isFalse);
      expect(delayed.volumes.every((v) => v == 0), isTrue);
    },
  );

  test(
    'loading preferences while already hidden never starts playback',
    () async {
      final music = buildService();
      addTearDown(music.dispose);
      music.didChangeAppLifecycleState(AppLifecycleState.hidden);
      await music.load();
      await music.flush();
      expect(player.played, isEmpty);
    },
  );

  test('late resume followed by hide ends with paused player', () async {
    final music = buildService();
    addTearDown(music.dispose);
    await music.load();
    music.didChangeAppLifecycleState(AppLifecycleState.resumed);
    music.didChangeAppLifecycleState(AppLifecycleState.hidden);
    await music.flush();
    expect(player.pauseCount, greaterThan(0));
    expect(player.resumeCount, 0);
  });
}
