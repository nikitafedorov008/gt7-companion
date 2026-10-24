// FILE: lib/router/sound_navigator_observer.dart
// VERSION: 1.1.0
// START_MODULE_CONTRACT
//   PURPOSE: Sound route transitions from one place, so no screen has to know that sound exists.
//   SCOPE: Page, popup and tab transitions; it holds no other logic.
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
import 'package:auto_route/auto_route.dart';

import '../models/sfx.dart';
import '../services/sound_service.dart';

/// Sounds page, popup and tab transitions.
///
/// Registered through auto_route's config, so pushing and popping screens makes
/// a noise without a single screen importing audio.
///
/// Route transitions use the effect that fits: a page is
/// a navigation, a popup — a bottom sheet or a dialog — opens and closes. A sheet
/// added later therefore sounds itself, and no caller has to remember.
class SoundNavigatorObserver extends AutoRouterObserver {
  SoundNavigatorObserver(this._sound);

  final SoundService _sound;

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {
    if (previousRoute != null && route.index != previousRoute.index) {
      _sound.play(Sfx.navigate);
    }
  }

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    if (route.index != previousRoute.index) _sound.play(Sfx.navigate);
  }

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
