// FILE: lib/widgets/tap_sound_area.dart
// VERSION: 1.1.0
// START_MODULE_CONTRACT
//   PURPOSE: Make the generic press sound automatic, so a surface added later clicks without anyone remembering the convention.
//   SCOPE: Telling a tap from a drag, recovering from a lost release, and asking for the press effect. Nothing else.
//   DEPENDS: M-SOUND
//   LINKS: M-SOUND, V-M-SOUND
//   ROLE: RUNTIME
//   MAP_MODE: EXPORTS
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   TapSoundArea - one root interceptor that turns genuine taps into the press effect.
// END_MODULE_MAP

import 'package:flutter/gestures.dart' show PointerDeviceKind, computeHitSlop;
import 'package:flutter/widgets.dart';

import '../models/sfx.dart';
import '../services/sound_service.dart';

/// Plays the press sound for every genuine tap in the app.
///
/// One interceptor rather than a call at every button: coverage stops depending
/// on memory, and the decision about whether sound is on stays where it already
/// lives, in [SoundService] — switching it off silences this layer exactly as it
/// silences an explicit call.
///
/// A press that becomes a drag is not a tap, and the threshold is the
/// framework's own device-aware hit slop rather than a fixed number: it is the
/// same measure Flutter's buttons use, so this layer and the button underneath
/// agree about what counts as a tap on a mouse, a trackpad and a finger alike.
/// The sound fires on release, as a real control does, which also keeps a
/// cancelled gesture quiet.
///
/// A release that never arrives — the window losing focus mid-press, a gesture
/// the system cancels without saying so — does not silence what follows: a later
/// press takes over from a pointer that has gone quiet, because refusing it
/// would cost every press until the app restarted.
///
/// Input passes straight through: the hit-test behaviour is translucent, so no
/// gesture, scroll or drag underneath changes its behaviour.
class TapSoundArea extends StatefulWidget {
  const TapSoundArea({required this.child, super.key});

  final Widget child;

  @override
  State<TapSoundArea> createState() => _TapSoundAreaState();
}

class _TapSoundAreaState extends State<TapSoundArea> {
  /// How long a tracked pointer may go unheard before its release is presumed
  /// lost. Only touch needs the wait: a mouse has a single pointer and cannot be
  /// mid-gesture with a second one.
  static const Duration _lostAfter = Duration(seconds: 1);

  /// The pointer whose gesture decides the outcome; later fingers are ignored,
  /// so a two-finger gesture does not click twice.
  int? _pointer;
  Offset? _origin;
  bool _moved = false;
  DateTime? _heardAt;

  void _forget() {
    _pointer = null;
    _origin = null;
    _moved = false;
    _heardAt = null;
  }

  bool get _trackedIsStale {
    final heard = _heardAt;
    if (heard == null) return true;
    return DateTime.now().difference(heard) > _lostAfter;
  }

  void _onPointerDown(PointerDownEvent event) {
    // A press means a finger is down now. If the tracked pointer has gone quiet
    // its release was lost, and refusing this press would silence every press
    // that followed until the app restarted. A mouse is taken at its word
    // straight away, since it cannot be holding a second pointer.
    final adopt = _pointer == null ||
        event.kind == PointerDeviceKind.mouse ||
        _trackedIsStale;
    if (!adopt) return;

    _pointer = event.pointer;
    _origin = event.position;
    _moved = false;
    _heardAt = DateTime.now();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || _moved) return;

    _heardAt = DateTime.now();
    final origin = _origin;
    final slop = computeHitSlop(
      event.kind,
      MediaQuery.maybeOf(context)?.gestureSettings,
    );
    if (origin != null && (event.position - origin).distance > slop) {
      _moved = true;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;

    final wasDrag = _moved;
    _forget();
    if (wasDrag) return;

    context.sfx(Sfx.tap);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _forget(),
      child: widget.child,
    );
  }
}
