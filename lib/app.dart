import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dependency_injection/app_scope.dart';
import 'theme/gt7_theme.dart';
import 'repositories/unified_car_repository.dart';
import 'services/telemetry_service.dart';
import 'services/gt7info_service.dart';
import 'services/gtdb_service.dart';
import 'services/dg_edge_service.dart';
import 'services/gtsh_rank_service.dart';

// AutoRoute router
import 'router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final _appRouter = AppRouter();

    return AppScope(
      child: MaterialApp.router(
        title: 'Gran Turismo 7 Companion',
        theme: gt7Theme(),
        routerConfig: _appRouter.config(),
      ),
    );
  }
}
