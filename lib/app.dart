import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dependency_injection/app_scope.dart';
import 'theme/gt7_theme.dart';

// AutoRoute router
import 'router/app_router.dart';
import 'router/sound_navigator_observer.dart';
import 'services/sound_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScope(child: _AppView());
  }
}

/// Builds the router below [AppScope].
///
/// It sits inside the scope on purpose: the route observer needs the sound
/// service, and that service only exists once the scope above has provided it.
class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();
    final sound = context.read<SoundService>();

    return MaterialApp.router(
      title: 'Gran Turismo 7 Companion',
      theme: gt7Theme(),
      // Transitions make a sound from here, so screens never mention audio.
      // auto_route takes observers through its own config: MaterialApp.router
      // does not accept them when a routerConfig is supplied.
      routerConfig: appRouter.config(
        navigatorObservers: () => [SoundNavigatorObserver(sound)],
      ),
    );
  }
}
