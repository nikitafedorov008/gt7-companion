// FILE: lib/services/music_player.dart
// VERSION: 1.1.0
// START_MODULE_CONTRACT
//   PURPOSE: Play the ambient music channel, with the audio engine kept behind an interface tests can replace.
//   SCOPE: Preparing a track, starting, pausing, resuming, stopping, releasing, and reporting that a track ended.
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

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// The music playback seam.
///
/// One track plays at a time and is allowed to finish on its own: rotation is
/// the service's job, so this seam reports completion instead of looping a
/// single file forever.
///
/// [pause] and [stop] are deliberately different: pausing keeps the position so
/// the track can carry on, while stopping resets it — which is what switching
/// the channel off should do, and what returning to the window should not.
abstract class MusicPlayer {
  /// Registers the callback fired when the current track reaches its end.
  void onComplete(void Function() callback);

  /// Starts [asset] from the beginning, replacing whatever was playing.
  Future<void> play(String asset, {required double volume});

  /// Changes the volume of whatever is playing.
  Future<void> setVolume(double volume);

  /// Holds the current track where it is.
  Future<void> pause();

  /// Carries on from where [pause] left the track.
  Future<void> resume();

  /// Stops the current track, resetting it to the beginning.
  Future<void> stop();

  /// Releases every player this instance created.
  Future<void> dispose();
}

/// The [MusicPlayer] backed by the audioplayers plugin.
///
/// The map holds the *pending* load rather than the finished player, so two
/// callers asking for the same track at the same time await one creation instead
/// of building two players — which is exactly how one track once came out of two
/// speakers at once. A load that fails is dropped from the map so a later attempt
/// can retry rather than await a broken future forever.
///
/// The release mode is `stop` rather than `loop` on purpose: a single looping
/// player could never report completion, and without that the service could not
/// rotate through tracks.
///
/// Failures degrade to silence: music is never worth an exception in the UI.
class AudioPlayersMusicPlayer implements MusicPlayer {
  /// audioplayers prepends this itself (`AudioCache.prefix`), while the service
  /// names assets by their full bundle key. Trimmed here, at the engine edge.
  static const String _enginePrefix = 'assets/';

  final Map<String, Future<AudioPlayer>> _players = {};
  void Function()? _onComplete;

  @override
  void onComplete(void Function() callback) => _onComplete = callback;

  /// The one player for [asset], created once however many callers ask for it.
  Future<AudioPlayer> _playerFor(String asset) {
    final pending = _players[asset];
    if (pending != null) return pending;

    final created = _createPlayer(asset);
    _players[asset] = created;
    unawaited(
      created.then((_) {}, onError: (Object _) => _players.remove(asset)),
    );
    return created;
  }

  Future<AudioPlayer> _createPlayer(String asset) async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(asset.replaceFirst(_enginePrefix, '')));
    player.onPlayerComplete.listen((_) => _onComplete?.call());
    return player;
  }

  /// Runs [action] against every prepared player, swallowing engine failures.
  Future<void> _forEachPlayer(Future<void> Function(AudioPlayer) action) async {
    for (final pending in _players.values.toList()) {
      try {
        await action(await pending);
      } catch (_) {
        // A silent channel is an acceptable outcome.
      }
    }
  }

  @override
  Future<void> play(String asset, {required double volume}) async {
    try {
      final player = await _playerFor(asset);

      for (final entry in _players.entries.toList()) {
        if (entry.key == asset) continue;
        try {
          await (await entry.value).stop();
        } catch (_) {
          // The other track was not playing anyway.
        }
      }

      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.stop();
      await player.resume();
    } catch (_) {
      // No audio backend here: the channel stays silent.
    }
  }

  @override
  Future<void> setVolume(double volume) =>
      _forEachPlayer((player) => player.setVolume(volume.clamp(0.0, 1.0)));

  @override
  Future<void> pause() => _forEachPlayer((player) => player.pause());

  @override
  Future<void> resume() => _forEachPlayer((player) => player.resume());

  @override
  Future<void> stop() => _forEachPlayer((player) => player.stop());

  @override
  Future<void> dispose() async {
    for (final pending in _players.values.toList()) {
      try {
        await (await pending).dispose();
      } catch (_) {
        // Nothing useful to do while tearing down.
      }
    }
    _players.clear();
  }
}
