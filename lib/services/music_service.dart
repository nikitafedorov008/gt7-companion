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
  })  : _player = player ?? AudioPlayersMusicPlayer(),
        _enabled = enabled,
        _volume = volume {
    _player.onComplete(_advance);
  }

  /// The rotation, in play order. Asset bundle keys, as pubspec declares them.
  static const List<String> tracks = [
    'assets/music/almost-floating.mp3',
    'assets/music/deep-space-loop.mp3',
  ];

  /// Key under which the preference is stored.
  static const String prefsKey = 'ui_music_enabled';

  /// A bed sits far below a click: this is music to work next to, not a concert.
  static const double defaultVolume = 0.25;

  /// How many steps a fade takes, and how far the volume moves in total.
  static const int fadeSteps = 8;

  final MusicPlayer _player;
  final double _volume;
  final Duration fadeDuration;

  bool _enabled;
  bool _isLoaded = false;
  bool _isForeground = true;
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

    _isLoaded = true;
    WidgetsBinding.instance.addObserver(this);
    notifyListeners();

    if (_enabled) await _start();
  }

  /// Turns the music on or off and remembers the choice.
  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;

    _enabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (e) {
      debugPrint('MusicService: could not store the preference: $e');
    }

    if (value) {
      await _start();
    } else {
      await _fadeOut();
      await _player.stop();
    }
  }

  /// Falls silent when the app is not in front of the user, and comes back when
  /// it is — a companion app must not play to an empty room.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (!_enabled) return;

    if (_isForeground) {
      unawaited(_start());
    } else {
      unawaited(_player.stop());
    }
  }

  /// Moves to the next track when the current one ends, wrapping around.
  void _advance() {
    if (!_enabled || !_isForeground) return;
    _index = (_index + 1) % tracks.length;
    unawaited(_start());
  }

  Future<void> _start() async {
    await _player.play(currentTrack, volume: 0);
    await _fadeIn();
  }

  Future<void> _fadeIn() async {
    for (var step = 1; step <= fadeSteps; step++) {
      await _player.setVolume(_volume * step / fadeSteps);
      await _pause();
    }
  }

  Future<void> _fadeOut() async {
    for (var step = fadeSteps - 1; step >= 0; step--) {
      await _player.setVolume(_volume * step / fadeSteps);
      await _pause();
    }
  }

  Future<void> _pause() async {
    final step = fadeDuration ~/ fadeSteps;
    if (step > Duration.zero) await Future<void>.delayed(step);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_player.dispose());
    super.dispose();
  }
}
