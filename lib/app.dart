import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/gt7_theme.dart';
import 'repositories/unified_car_repository.dart';
import 'services/telemetry_service.dart';
import 'services/gt7info_service.dart';
import 'services/gtdb_service.dart';
import 'services/dg_edge_service.dart';

// AutoRoute router
import 'router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final _appRouter = AppRouter();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TelemetryService()),
        ChangeNotifierProvider(create: (context) => GT7InfoService()),
        ChangeNotifierProvider(create: (context) => GTDBService()),
        ChangeNotifierProvider(create: (context) => DgEdgeService()),
        ChangeNotifierProxyProvider2<
          GT7InfoService,
          GTDBService,
          UnifiedCarRepository
        >(
          create: (context) => UnifiedCarRepository(
            Provider.of<GT7InfoService>(context, listen: false),
            Provider.of<GTDBService>(context, listen: false),
          ),
          update: (context, gt7InfoService, gtdbService, repository) {
            return repository ??
                UnifiedCarRepository(gt7InfoService, gtdbService);
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Gran Turismo 7 Companion',
        theme: gt7Theme(),
        routerConfig: _appRouter.config(),
      ),
    );
  }
}
