// FILE: lib/router/sound_navigator_observer.dart
// VERSION: 1.0.0
// START_MODULE_CONTRACT
//   PURPOSE: Sound route transitions from one place, so no screen has to know that sound exists.
//   SCOPE: Page pushes and pops only; it holds no other logic.
//   DEPENDS: M-SOUND
//   LINKS: M-SOUND, V-M-SOUND
//   ROLE: RUNTIME
//   MAP_MODE: EXPORTS
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   SoundNavigatorObserver - plays the navigate and back effects for page routes.
// END_MODULE_MAP

import 'package:flutter/widgets.dart';

import '../models/sfx.dart';
import '../services/sound_service.dart';

/// Sounds page transitions.
///
/// Registered through `MaterialApp.router`'s `navigatorObservers`, so pushing and
/// popping screens makes a noise without a single screen importing audio.
///
/// Only [PageRoute]s are sounded. Bottom sheets and dialogs are popup routes and
/// get their own open and close effects from the code that shows them — if this
/// observer sounded those too, opening the daily-race sheet would play two
/// effects at once.
class SoundNavigatorObserver extends NavigatorObserver {
  SoundNavigatorObserver(this._sound);

  final SoundService _sound;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // The first route is the app opening, not a navigation the user made.
    if (previousRoute == null || route is! PageRoute) return;
    _sound.play(Sfx.navigate);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute) return;
    _sound.play(Sfx.back);
  }
}
