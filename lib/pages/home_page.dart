import 'package:gt7_companion/l10n/ui_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:fluid_background/fluid_background.dart';

import '../router/app_router.dart';
import '../services/telemetry_service.dart';
import '../widgets/home/service_menu.dart';
import '../widgets/daily_races/daily_races_display.dart';
import '../widgets/telemetry/telemetry_screen.dart';
import '../widgets/telemetry/telemetry_panel.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _openUsedCarDealer(BuildContext context) {
    context.router.push(const UsedCarDisplayRoute());
  }

  void _openLegendaryCarDealer(BuildContext context) {
    context.router.push(const LegendaryCarDisplayRoute());
  }

  void _openGTAuto(BuildContext context) {
    context.router.push(const GTAutoDisplayRoute());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        //statusBarColor: Colors.black.withOpacity(0.2),
        statusBarColor: Colors.red,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: null,
        bottomNavigationBar: null,
        body: Stack(
          children: [
            // Background (fills under the status bar)
            FluidBackground(
              initialColors: InitialColors.random(4),
              initialPositions: InitialOffsets.predefined(),
              velocity: 80,
              bubblesSize: 400,
              sizeChangingRange: const [300, 600],
              allowColorChanging: true,
              bubbleMutationDuration: const Duration(seconds: 4),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: 0.22),
                      theme.colorScheme.surface.withValues(alpha: 0.06),
                      theme.colorScheme.surface,
                    ],
                    // смещаем середину чуть выше для более явного перехода
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Content (kept inside SafeArea so it does not overlap the system UI)
            // Bottom padding is disabled so content can scroll under the bottom nav.
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TelemetryPanel(),

                    const SizedBox(height: 24),
                    Text(
                      context.tr('Services'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),

                    ServiceMenu(
                      onBrandCentral: () =>
                          context.router.push(const BrandCentralDisplayRoute()),
                      onUsed: () => _openUsedCarDealer(context),
                      onLegendary: () => _openLegendaryCarDealer(context),
                      onGTAuto: () => _openGTAuto(context),
                    ),
                    const SizedBox(height: 24),
                    const DailyRacesDisplay(ifFutureExistsNotShowPast: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Provides a full-screen view for telemetry — kept as a separate route so
// the provider context (TelemetryService) is reused from the app root.
@RoutePage()
class TelemetryDetailsScreen extends StatelessWidget {
  const TelemetryDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      bottomNavigationBar: null,
      body: Consumer<TelemetryService>(
        builder: (context, service, child) {
          if (!service.isConnected) {
            return Center(child: Text(context.tr('Not connected to GT7')));
          }

          return TelemetryScreen(
            telemetry: service.telemetry,
            errorMessage: service.errorMessage,
          );
        },
      ),
    );
  }
}
