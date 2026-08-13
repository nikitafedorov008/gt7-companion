import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluid_background/fluid_background.dart';

import '../router/app_router.dart';
import '../services/telemetry_service.dart';
import '../widgets/daily_races/daily_races_display.dart';
import '../widgets/telemetry/telemetry_display.dart';
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
                      theme.colorScheme.surface.withOpacity(0.22),
                      theme.colorScheme.surface.withOpacity(0.06),
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
                    Text('Services', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        int crossAxisCount = 2;
                        if (width > 600) crossAxisCount = 3;
                        if (width > 900) crossAxisCount = 4;

                        double childAspectRatio = crossAxisCount == 2
                            ? 1.65
                            : (crossAxisCount == 4 ? 1.25 : 1.55);

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                          children: [
                            // Used car dealer — image + white/grey gradient, label below card
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AppTile(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFBFCFD),
                                      Color.alphaBlend(
                                        Colors.white70,
                                        Colors.indigo,
                                      ),
                                      Color.alphaBlend(
                                        Colors.white70,
                                        Colors.red,
                                      ),
                                      Color(0xFFF0F2F4),
                                    ],
                                  ),
                                  onTap: () => _openUsedCarDealer(context),
                                  child: Image.asset(
                                    'assets/images/auto_plus.webp',
                                    width: 64,
                                    height: 56,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Used car dealer',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),

                            // Legendary car dealer — stacked SVGs, dark/black gradient, label below
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AppTile(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF070707),
                                      Color(0xFF141414),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  onTap: () => _openLegendaryCarDealer(context),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/legend_hagerty_icon.svg',
                                        width: 56,
                                        height: 28,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 10),
                                      SvgPicture.asset(
                                        'assets/images/hagerty_title.svg',
                                        width: 84,
                                        height: 14,
                                        fit: BoxFit.contain,
                                        colorFilter: ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Legendary car dealer',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),

                            // GT Auto — image + yellow-orange gradient, label below
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AppTile(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFF1D6),
                                      Color(0xFFFFB347),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () => _openGTAuto(context),
                                  child: Image.asset(
                                    'assets/images/gt_auto.webp',
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'GT Auto',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
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

class _AppTile extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final VoidCallback onTap;

  const _AppTile({required this.child, this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? theme.colorScheme.surface : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: DefaultTextStyle(
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ) ??
                  const TextStyle(color: Colors.white),
              child: child,
            ),
          ),
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
            return const Center(child: Text('Not connected to GT7'));
          }

          return TelemetryDisplay(
            telemetry: service.telemetry,
            errorMessage: service.errorMessage,
          );
        },
      ),
    );
  }
}
