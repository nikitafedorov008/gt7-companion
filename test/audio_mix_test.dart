import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/sfx.dart';
import 'package:gt7_companion/services/music_service.dart';
import 'package:gt7_companion/services/sound_service.dart';

/// Mean level of each effect file over its own duration, measured with ffmpeg's
/// volumedetect. The command and the full table live in assets/sfx/LEVELS.md.
final Map<Sfx, double> _fileLevels = {
  for (final effect in Sfx.values) effect: -24.0,
};

/// The shipped music tracks' measured means after loudness normalisation.
const Map<String, double> _musicFileLevels = {
  'assets/music/airport-lounge.mp3': -19.7,
  'assets/music/chill-wave.mp3': -19.5,
  'assets/music/bossa-antigua.mp3': -19.9,
};

/// How far apart the eight effects may sit, in decibels.
const double _maxSpread = 1.5;

/// How far above the music bed an effect must sit to read as a click over it.
const double _minMargin = 8.0;

/// A file's level as it comes out of the speakers, given the volume applied.
double _level(double fileLevel, double volume) =>
    fileLevel + 20 * math.log(volume) / math.ln10;

double _effectLevel(Sfx effect) =>
    _level(_fileLevels[effect]!, effect.gain * SoundService.defaultVolume);

void main() {
  test('every effect plays at the same loudness', () {
    final levels = [for (final effect in Sfx.values) _effectLevel(effect)];
    final spread = levels.reduce(math.max) - levels.reduce(math.min);

    expect(
      spread,
      lessThan(_maxSpread),
      reason: 'the pack is not loudness-matched, so the gains have to do it',
    );
  });

  test('every effect clears the music bed', () {
    final loudestTrack = MusicService.tracks
        .map((track) => _musicFileLevels[track]!)
        .reduce(math.max);
    final music = _level(loudestTrack, MusicService.defaultVolume);

    for (final effect in Sfx.values) {
      expect(
        _effectLevel(effect) - music,
        greaterThanOrEqualTo(_minMargin),
        reason: '${effect.name} would be masked by the music',
      );
    }
  });

  test('no effect asks for more volume than the player can give', () {
    // The player clamps the volume to 1.0, so a gain above it would be silently
    // capped and the effect would land quieter than this arithmetic claims.
    for (final effect in Sfx.values) {
      expect(
        effect.gain * SoundService.defaultVolume,
        lessThanOrEqualTo(1.0),
        reason: '${effect.name} would be clamped',
      );
    }
  });
}
