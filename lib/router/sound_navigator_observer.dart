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

/// Sounds route transitions.
///
/// Registered through auto_route's config, so pushing and popping screens makes
/// a noise without a single screen importing audio.
///
/// Both kinds of route are covered, each with the effect that fits it: a page is
/// a navigation, a popup — a bottom sheet or a dialog — opens and closes. A sheet
/// added later therefore sounds itself, and no caller has to remember.
class SoundNavigatorObserver extends NavigatorObserver {
  SoundNavigatorObserver(this._sound);

  final SoundService _sound;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // The first route is the app opening, not a navigation the user made.
    if (previousRoute == null) return;

    if (route is PageRoute) {
      _sound.play(Sfx.navigate);
    } else if (route is PopupRoute) {
      _sound.play(Sfx.open);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      _sound.play(Sfx.back);
    } else if (route is PopupRoute) {
      _sound.play(Sfx.close);
    }
  }
}
