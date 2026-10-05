// FILE: lib/services/sfx_player.dart
// VERSION: 1.0.0
// START_MODULE_CONTRACT
//   PURPOSE: Play one interface sound, with the audio engine kept behind an interface tests can replace.
//   SCOPE: Loading effects, replaying them and releasing them. No policy, no preference, no debounce.
//   DEPENDS: none
//   LINKS: M-SOUND, V-M-SOUND
//   ROLE: RUNTIME
//   MAP_MODE: EXPORTS
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   SfxPlayer - the playback seam the app depends on.
//   AudioPlayersSfxPlayer - the audioplayers-backed implementation.
// END_MODULE_MAP

import 'package:audioplayers/audioplayers.dart';

import '../models/sfx.dart';

/// Everything the app needs in order to make a noise, and nothing else.
///
/// The service depends on this rather than on a plugin, so unit and widget tests
/// inject a fake and never touch a platform channel.
abstract class SfxPlayer {
  /// Loads the given effects up front, so the first press is not the one that
  /// pays for decoding.
  Future<void> preload(Iterable<Sfx> sounds);

  /// Plays one effect, restarting it when it is already sounding.
  Future<void> play(Sfx sound, {required double volume});

  /// Releases every player this instance created.
  Future<void> dispose();
}

/// The [SfxPlayer] backed by the audioplayers plugin.
///
/// One player per effect, kept alive between plays: [preload] sets each source
/// once, and replaying is a stop-then-resume. `AudioPlayer.stop()` is documented
/// to reset the position to the beginning, which is what makes a repeated press
/// audible instead of silent. Layering the same effect over itself is
/// deliberately unsupported — for interface feedback, restarting is what a press
/// should do.
///
/// Failures are swallowed on purpose: on a platform without an audio backend, or
/// in a test that never initialised the plugin, a missing sound must not throw
/// into the tap handler that asked for it.
class AudioPlayersSfxPlayer implements SfxPlayer {
  /// audioplayers prepends this itself (`AudioCache.prefix` defaults to
  /// `assets/`), while [Sfx.asset] holds the full bundle key. The prefix is
  /// trimmed here, at the engine boundary, so the model stays engine-agnostic.
  static const String _enginePrefix = 'assets/';

  final Map<Sfx, AudioPlayer> _players = {};

  @override
  Future<void> preload(Iterable<Sfx> sounds) async {
    for (final sound in sounds) {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(
          AssetSource(sound.asset.replaceFirst(_enginePrefix, '')),
        );
        _players[sound] = player;
      } catch (_) {
        // No audio backend here: this effect stays silent.
      }
    }
  }

  @override
  Future<void> play(Sfx sound, {required double volume}) async {
    final player = _players[sound];
    if (player == null) return;

    try {
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.stop();
      await player.resume();
    } catch (_) {
      // Silence is an acceptable outcome; a sound is never worth an exception.
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
