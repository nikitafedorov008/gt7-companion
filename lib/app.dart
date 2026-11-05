import 'widgets/gt_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dependency_injection/app_scope.dart';
import 'theme/gt7_theme.dart';

// AutoRoute router
import 'router/app_router.dart';
import 'router/sound_navigator_observer.dart';
import 'services/sound_service.dart';
import 'widgets/tap_sound_area.dart';
import 'services/app_settings_service.dart';
import 'l10n/generated/app_localizations.dart';

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
class _AppView extends StatefulWidget {
  const _AppView();
  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  final AppRouter _appRouter = AppRouter();
  // Keep the route-information provider and delegate stable across locale and
  // lifecycle rebuilds as well as the router object itself.
  late final _routerConfig = _appRouter.config(
    navigatorObservers: () => [
      SoundNavigatorObserver(context.read<SoundService>()),
    ],
  );
  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsService>();

    if (!settings.isLoaded) {
      return MaterialApp(
        theme: gt7Theme(),
        home: const Scaffold(body: Center(child: GtLoadingIndicator())),
      );
    }
    return TapSoundArea(
      // Wraps the whole app, so taps that land on dialogs and sheets count too:
      // overlays render inside the app this interceptor covers.
      child: MaterialApp.router(
        title: 'Gran Turismo 7 Companion',
        theme: gt7Theme(),
        locale: settings.effectiveLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        // Transitions make a sound from here, so screens never mention audio.
        // auto_route takes observers through its own config: MaterialApp.router
        // does not accept them when a routerConfig is supplied.
        routerConfig: _routerConfig,
      ),
    );
  }
}
