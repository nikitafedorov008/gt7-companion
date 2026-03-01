import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/sport_repository.dart';
import '../services/telemetry_service.dart';
import '../services/gt7info_service.dart';
import '../services/gtdb_service.dart';
import '../services/dg_edge_service.dart';
import '../services/gtsh_rank_service.dart';
import '../repositories/unified_car_repository.dart';

/// Top-level provider scope used by the application.
///
/// Extracted from `App` so that the widget tree can be more easily
/// instantiated in tests or preview environments without dragging along the
/// entire `MaterialApp` configuration.
class AppScope extends StatelessWidget {
  final Widget child;

  const AppScope({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TelemetryService()),
        ChangeNotifierProvider(create: (context) => GT7InfoService()),
        ChangeNotifierProvider(create: (context) => GTDBService()),
        ChangeNotifierProvider(create: (context) => DgEdgeService()),
        ChangeNotifierProvider(create: (context) => GtshRankService()),
        // repository that merges daily races from both sources
        ChangeNotifierProxyProvider2<
          DgEdgeService,
          GtshRankService,
          SportRepository
        >(
          create: (context) => SportRepositoryImpl(
            Provider.of<DgEdgeService>(context, listen: false),
            Provider.of<GtshRankService>(context, listen: false),
          ),
          update: (context, dg, gtsh, repository) {
            return repository ?? SportRepositoryImpl(dg, gtsh);
          },
        ),
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
      child: child,
    );
  }
}
