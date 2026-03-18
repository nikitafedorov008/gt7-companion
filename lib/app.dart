import 'package:flutter/material.dart';

import 'dependency_injection/app_scope.dart';
import 'theme/gt7_theme.dart';

// AutoRoute router
import 'router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();

    return AppScope(
      child: MaterialApp.router(
        title: 'Gran Turismo 7 Companion',
        theme: gt7Theme(),
        routerConfig: appRouter.config(),
      ),
    );
  }
}
