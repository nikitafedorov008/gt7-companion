import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repositories/unified_car_repository.dart';
import 'services/telemetry_service.dart';
import 'services/gt7info_service.dart';
import 'services/gtdb_service.dart';
import 'telemetry_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TelemetryService()),
        ChangeNotifierProvider(create: (context) => GT7InfoService()),
        ChangeNotifierProvider(create: (context) => GTDBService()),
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
      child: MaterialApp(
        title: 'GT7 Telemetry Flutter',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const TelemetryScreen(),
      ),
    );
  }
}
