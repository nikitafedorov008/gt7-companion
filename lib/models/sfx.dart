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
/// The files come from Kenney's CC0 Interface Sounds pack; see
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
        Sfx.tap => 'assets/sfx/tap.ogg',
        Sfx.navigate => 'assets/sfx/navigate.ogg',
        Sfx.back => 'assets/sfx/back.ogg',
        Sfx.open => 'assets/sfx/open.ogg',
        Sfx.close => 'assets/sfx/close.ogg',
        Sfx.toggle => 'assets/sfx/toggle.ogg',
        Sfx.confirm => 'assets/sfx/confirm.ogg',
        Sfx.error => 'assets/sfx/error.ogg',
      };

  /// Multiplier that brings each effect to the same loudness.
  ///
  /// The pack is not loudness-matched — the press effect is 12 dB quieter than
  /// the pack's loudest sound — and every file is already peak-normalised, so
  /// there is no headroom to raise them. These gains normalise downwards instead,
  /// taking the quietest effect as the reference, so which effect a surface asks
  /// for never decides whether it can be heard. The measurements behind the
  /// numbers, and the command that produced them, are in assets/sfx/LEVELS.md.
  double get gain => switch (this) {
        Sfx.tap => 1.0,
        Sfx.back => 0.55,
        Sfx.error => 0.43,
        Sfx.open => 0.32,
        Sfx.close => 0.26,
        Sfx.navigate => 0.26,
        Sfx.toggle => 0.24,
        Sfx.confirm => 0.18,
      };
}
