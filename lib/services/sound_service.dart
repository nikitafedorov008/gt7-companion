// FILE: lib/services/sound_service.dart
// VERSION: 1.0.0
// START_MODULE_CONTRACT
//   PURPOSE: Own whether the interface makes a sound, how loud, and how often, and hand widgets a one-line way to ask for one.
//   SCOPE: The preference, the volume, the debounce and the haptic pairing. Playback itself is SfxPlayer.
//   DEPENDS: none
//   LINKS: M-SOUND, V-M-SOUND
//   ROLE: RUNTIME
//   MAP_MODE: EXPORTS
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   SoundService - the app's sound policy and the only thing that talks to the player.
//   SoundContextX - BuildContext.sfx(effect), the call sites' entry point.
// END_MODULE_MAP

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sfx.dart';
import 'sfx_player.dart';

/// Owns the interface's sound policy.
///
/// Widgets do not decide anything about sound: they ask for an effect through
/// [SoundContextX.sfx] and this service answers. That keeps the toggle, the
/// stored preference, the volume and the debounce from drifting apart, and lets a
/// test drive the whole thing through an injected [SfxPlayer] without a device.
class SoundService extends ChangeNotifier {
  SoundService({
    SfxPlayer? player,
    bool enabled = true,
    double volume = defaultVolume,
  })  : _player = player ?? AudioPlayersSfxPlayer(),
        _enabled = enabled,
        _volume = volume;

  /// Key under which the preference is stored.
  static const String prefsKey = 'ui_sound_enabled';

  /// Full scale, because the pack leaves no headroom: every effect file is
  /// already peak-normalised, so this channel cannot be made louder without
  /// clipping. The music is what gives way instead.
  static const double defaultVolume = 1.0;

  /// Repeats of the same effect faster than this are dropped, so a quick tapper
  /// cannot machine-gun clicks.
  static const Duration minGap = Duration(milliseconds: 40);

  final SfxPlayer _player;
  final Map<Sfx, DateTime> _lastPlayed = {};

  bool _enabled;
  final double _volume;
  bool _isLoaded = false;
  bool _isPreloaded = false;

  bool get enabled => _enabled;
  double get volume => _volume;

  /// Restores the stored preference and loads the effects.
  ///
  /// Call once from the app scope; calling it again is a no-op.
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(prefsKey) ?? _enabled;
    } catch (e) {
      debugPrint('SoundService: could not read the preference: $e');
    }

    _isLoaded = true;
    notifyListeners();
    await _preload();
  }

  /// Turns interface sound on or off and remembers the choice.
  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;

    _enabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (e) {
      debugPrint('SoundService: could not store the preference: $e');
    }

    if (value) await _preload();
  }

  /// Plays [effect] unless sound is off, the effects are still loading, or the
  /// same effect played within [minGap].
  ///
  /// Fire-and-forget on purpose: a tap must never wait for audio.
  void play(Sfx effect) {
    if (!_enabled) return;

    final now = DateTime.now();
    final last = _lastPlayed[effect];
    if (last != null && now.difference(last) < minGap) return;
    _lastPlayed[effect] = now;

    unawaited(HapticFeedback.lightImpact().catchError((Object _) {}));
    unawaited(_player.play(effect, volume: _volume * effect.gain));
  }

  Future<void> _preload() async {
    if (!_enabled || _isPreloaded) return;
    _isPreloaded = true;
    await _player.preload(Sfx.values);
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }
}

/// The entry point for a sound whose meaning automation cannot infer.
extension SoundContextX on BuildContext {
  /// The sound service registered above this context.
  SoundService get sound => read<SoundService>();

  /// Asks for one interface sound. Reads as a single line wherever a press,
  /// a push or a failure happens, and stays silent when sound is switched off.
  void sfx(Sfx effect) => sound.play(effect);
}
