// FILE: lib/services/music_service.dart
// VERSION: 1.0.0
// START_MODULE_CONTRACT
//   PURPOSE: Own the ambient music channel: which track plays, how loud, whether it plays at all, and when it must fall silent.
//   SCOPE: The preference, the rotation, the fades and the app life cycle. Playback itself is MusicPlayer.
//   DEPENDS: none
//   LINKS: M-SOUND, V-M-SOUND
//   ROLE: RUNTIME
//   MAP_MODE: EXPORTS
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   MusicService - the ambient music policy and the only thing that talks to the music player.
// END_MODULE_MAP

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'music_player.dart';

/// Owns the ambient music channel.
///
/// It is deliberately a channel of its own rather than a second switch on
/// [SoundService]: music loops, it must stop when nobody is looking at the app,
/// and it carries its own stored preference and its own, much lower, volume. The
/// interface sounds keep their own policy untouched.
class MusicService extends ChangeNotifier with WidgetsBindingObserver {
  MusicService({
    MusicPlayer? player,
    bool enabled = true,
    double volume = defaultVolume,
    this.fadeDuration = const Duration(milliseconds: 600),
  }) : _player = player ?? AudioPlayersMusicPlayer(),
       _enabled = enabled,
       _volume = volume {
    final state = WidgetsBinding.instance.lifecycleState;
    _isForeground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _player.onComplete(_advance);
  }

  /// The rotation, in play order. Asset bundle keys, as pubspec declares them.
  static const List<String> tracks = [
    'assets/music/airport-lounge.mp3',
    'assets/music/chill-wave.mp3',
    'assets/music/bossa-antigua.mp3',
  ];

  static const String credits =
      'Airport Lounge, Chill Wave, Bossa Antigua\n'
      'Kevin MacLeod — incompetech.com\n\n'
      'Licensed under Creative Commons Attribution 4.0\n'
      'https://creativecommons.org/licenses/by/4.0/\n\n'
      'Source: https://incompetech.com/music/royalty-free/\n'
      'Audio normalised and re-encoded for this app.\n'
      'These recordings are not from the Gran Turismo soundtrack.';

  /// Key under which the preference is stored.
  static const String prefsKey = 'ui_music_enabled';

  /// A bed, and a measured one: at this level the music sits about thirteen decibels
  /// below an interface sound, the margin that keeps a click audible over it.
  /// Measured file levels are in assets/sfx/LEVELS.md.
  static const double defaultVolume = 0.10;

  /// How many steps a fade takes, and how far the volume moves in total.
  static const int fadeSteps = 8;

  final MusicPlayer _player;
  final double _volume;
  final Duration fadeDuration;

  bool _enabled;
  bool _isLoaded = false;
  bool _disposed = false;
  int _generation = 0;
  Future<void> _operations = Future<void>.value();

  Future<void> _enqueue(Future<void> Function() action) {
    _operations = _operations
        .then((_) async {
          if (!_disposed) await action();
        })
        .catchError((Object error) {
          debugPrint('MusicService: playback failed: $error');
        });
    return _operations;
  }

  /// Wait for outstanding audio commands, including a late native player load.
  Future<void> flush() => _operations;
  bool _isForeground = true;

  /// Whether a track is playing or paused mid-track. Kept explicitly rather than
  /// inferred from the life-cycle state, because it is what stops a second start
  /// from doubling the playback.
  bool _isPlaying = false;
  int _index = 0;

  bool get enabled => _enabled;
  double get volume => _volume;

  /// The track currently selected for playback.
  String get currentTrack => tracks[_index];

  /// Restores the stored preference and starts the music if it is on.
  ///
  /// Call once from the app scope; calling it again is a no-op.
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(prefsKey) ?? _enabled;
    } catch (e) {
      debugPrint('MusicService: could not read the preference: $e');
    }

    if (_disposed) return;
    _isLoaded = true;
    notifyListeners();

    if (_enabled && _isForeground) await _enqueue(_start);
  }

  /// Turns the music on or off and remembers the choice.
  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;

    _enabled = value;
    _generation++;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (e) {
      debugPrint('MusicService: could not store the preference: $e');
    }

    await _enqueue(() async {
      if (_enabled && _isForeground) {
        await _resumeOrStart();
      } else if (!_enabled) {
        await _fadeOut();
        await _player.stop();
        _isPlaying = false;
      }
    });
  }

  /// Falls silent when the app is not in front of the user, and comes back when
  /// it is — a companion app must not play to an empty room.
  ///
  /// Leaving pauses and returning resumes, so the track carries on from where it
  /// was instead of starting over.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    _generation++;
    unawaited(
      _enqueue(() async {
        if (_enabled && _isForeground && _isLoaded) {
          await _resumeOrStart();
        } else {
          await _player.pause();
        }
      }),
    );
  }

  /// Moves to the next track when the current one ends, wrapping around.
  void _advance() {
    if (_disposed || !_enabled || !_isForeground) return;
    _index = (_index + 1) % tracks.length;
    _isPlaying = false;
    unawaited(_enqueue(_start));
  }

  Future<void> _start() async {
    // Asking again for the track that is already playing is not a restart. The
    // observer's first resumed notification arrives while load() is still
    // preparing that very track, and without this guard the second call built a
    // second player, so one track came out of two speakers at once.
    if (_isPlaying || !_enabled || !_isForeground || _disposed) return;
    _isPlaying = true;

    final generation = _generation;
    await _player.play(currentTrack, volume: 0);
    if (_disposed || !_enabled || !_isForeground || generation != _generation) {
      await _player.pause();
      return;
    }
    await _fadeIn();
  }

  /// Carries on where the track was paused, starting one if nothing is playing.
  Future<void> _resumeOrStart() async {
    if (_isPlaying) {
      await _player.resume();
      await _fadeIn();
    } else {
      await _start();
    }
  }

  Future<void> _fadeIn() async {
    final generation = _generation;
    for (var step = 1; step <= fadeSteps; step++) {
      if (_disposed ||
          !_enabled ||
          !_isForeground ||
          generation != _generation) {
        return;
      }
      await _player.setVolume(_volume * step / fadeSteps);
      await _waitFadeStep();
    }
  }

  Future<void> _fadeOut() async {
    for (var step = fadeSteps - 1; step >= 0; step--) {
      await _player.setVolume(_volume * step / fadeSteps);
      await _waitFadeStep();
    }
  }

  /// Waits out one fade step; a zero-length fade makes this a no-op.
  Future<void> _waitFadeStep() async {
    final step = fadeDuration ~/ fadeSteps;
    if (step > Duration.zero) await Future<void>.delayed(step);
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_operations.then((_) => _player.dispose()));
    super.dispose();
  }
}
