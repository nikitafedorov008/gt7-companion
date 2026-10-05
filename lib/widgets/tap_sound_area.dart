// FILE: lib/widgets/tap_sound_area.dart
// VERSION: 1.0.0
// START_MODULE_CONTRACT
//   PURPOSE: Make the generic press sound automatic, so a surface added later clicks without anyone remembering the convention.
//   SCOPE: Telling a tap from a drag and asking for the press effect. Nothing else.
//   DEPENDS: M-SOUND
//   LINKS: M-SOUND, V-M-SOUND
//   ROLE: RUNTIME
//   MAP_MODE: EXPORTS
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   TapSoundArea - one root interceptor that turns genuine taps into the press effect.
// END_MODULE_MAP

import 'package:flutter/gestures.dart' show kTouchSlop;
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
/// A press that becomes a drag is not a tap. The threshold is the framework's
/// own [kTouchSlop], the same one Flutter uses to tell a tap from a drag, so
/// scrolling a list stays silent without an invented constant. The sound fires
/// on release, as a real control does, which also keeps a cancelled gesture quiet.
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
  /// The pointer whose gesture decides the outcome; later fingers are ignored,
  /// so a two-finger gesture does not click twice.
  int? _pointer;
  Offset? _origin;
  bool _moved = false;

  void _forget() {
    _pointer = null;
    _origin = null;
    _moved = false;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _origin = event.position;
    _moved = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || _moved) return;

    final origin = _origin;
    if (origin != null && (event.position - origin).distance > kTouchSlop) {
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
