// FILE: lib/services/music_player.dart
// VERSION: 1.0.0
// START_MODULE_CONTRACT
//   PURPOSE: Play the ambient music channel, with the audio engine kept behind an interface tests can replace.
//   SCOPE: Preparing a track, starting it, changing volume, stopping, releasing, and reporting that a track ended.
//   DEPENDS: none
//   LINKS: M-SOUND, V-M-SOUND
//   ROLE: RUNTIME
//   MAP_MODE: EXPORTS
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   MusicPlayer - the ambient music seam the service depends on.
//   AudioPlayersMusicPlayer - the audioplayers-backed implementation.
// END_MODULE_MAP

import 'package:audioplayers/audioplayers.dart';

/// The music playback seam.
///
/// One track plays at a time and is allowed to finish on its own: rotation is
/// the service's job, so this seam reports completion instead of looping a
/// single file forever.
abstract class MusicPlayer {
  /// Registers the callback fired when the current track reaches its end.
  void onComplete(void Function() callback);

  /// Starts [asset] from the beginning, replacing whatever was playing.
  Future<void> play(String asset, {required double volume});

  /// Changes the volume of whatever is playing.
  Future<void> setVolume(double volume);

  /// Stops the current track.
  Future<void> stop();

  /// Releases every player this instance created.
  Future<void> dispose();
}

/// The [MusicPlayer] backed by the audioplayers plugin.
///
/// A player exists per track and its source is set once, so returning to a track
/// later is a stop-then-resume rather than a reload. The release mode is `stop`
/// rather than `loop` on purpose — a single looping player could never report
/// completion, and without that the service could not rotate through tracks.
///
/// Failures degrade to silence: music is never worth an exception in the UI.
class AudioPlayersMusicPlayer implements MusicPlayer {
  /// audioplayers prepends this itself (`AudioCache.prefix`), while the service
  /// names assets by their full bundle key. Trimmed here, at the engine edge.
  static const String _enginePrefix = 'assets/';

  final Map<String, AudioPlayer> _players = {};
  void Function()? _onComplete;

  @override
  void onComplete(void Function() callback) => _onComplete = callback;

  Future<AudioPlayer> _playerFor(String asset) async {
    final existing = _players[asset];
    if (existing != null) return existing;

    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(asset.replaceFirst(_enginePrefix, '')));
    player.onPlayerComplete.listen((_) => _onComplete?.call());
    _players[asset] = player;
    return player;
  }

  @override
  Future<void> play(String asset, {required double volume}) async {
    try {
      for (final entry in _players.entries) {
        if (entry.key != asset) await entry.value.stop();
      }

      final player = await _playerFor(asset);
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.stop();
      await player.resume();
    } catch (_) {
      // No audio backend here: the channel stays silent.
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    for (final player in _players.values) {
      try {
        await player.setVolume(volume.clamp(0.0, 1.0));
      } catch (_) {
        // Nothing to adjust.
      }
    }
  }

  @override
  Future<void> stop() async {
    for (final player in _players.values) {
      try {
        await player.stop();
      } catch (_) {
        // Already silent.
      }
    }
  }

  @override
  Future<void> dispose() async {
    for (final player in _players.values) {
      try {
        await player.dispose();
      } catch (_) {
        // Nothing useful to do while tearing down.
      }
    }
    _players.clear();
  }
}
