// FILE: lib/models/sfx.dart
// VERSION: 1.0.0
// START_MODULE_CONTRACT
//   PURPOSE: Name every interface sound the app can play and map it to the asset that carries it.
//   SCOPE: The catalogue only; playback lives behind SfxPlayer, policy in SoundService.
//   DEPENDS: none
//   LINKS: M-SOUND, V-M-SOUND
//   ROLE: RUNTIME
//   MAP_MODE: EXPORTS
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   Sfx - the interface sounds, one per kind of interaction.
// END_MODULE_MAP

/// The interface sounds, one per kind of interaction.
///
/// [SfxX] carries the two things call sites must not repeat: which file plays and
/// how loud it sits relative to the service volume. Paths are asset bundle keys —
/// exactly what `pubspec.yaml` declares and what the bundle answers to — so the
/// playback engine's own conventions stay inside [SfxPlayer].
///
/// The files are an original synthesised soft menu bank; see
/// `assets/sfx/SOURCES.md` for provenance and for how to swap one.
enum Sfx {
  /// A press that does not leave the current screen.
  tap,

  /// A route push: a new screen replaces the view.
  navigate,

  /// A route pop: the previous screen comes back.
  back,

  /// A bottom sheet or dialog appearing.
  open,

  /// A bottom sheet or dialog closing.
  close,

  /// A setting changing state, such as sound itself.
  toggle,

  /// An action that finished successfully, such as a completed refresh.
  confirm,

  /// A failure state appearing.
  error,
}

extension SfxX on Sfx {
  /// Asset bundle key for this sound, as declared under `assets:` in pubspec.
  String get asset => switch (this) {
    Sfx.tap => 'assets/sfx/tap.wav',
    Sfx.navigate => 'assets/sfx/navigate.wav',
    Sfx.back => 'assets/sfx/back.wav',
    Sfx.open => 'assets/sfx/open.wav',
    Sfx.close => 'assets/sfx/close.wav',
    Sfx.toggle => 'assets/sfx/toggle.wav',
    Sfx.confirm => 'assets/sfx/confirm.wav',
    Sfx.error => 'assets/sfx/error.wav',
  };

  /// The bank is matched to -24 dBFS RMS; leave a little channel headroom.
  /// See assets/sfx/LEVELS.md for the reproducible measurements.
  double get gain => 0.8;
}
