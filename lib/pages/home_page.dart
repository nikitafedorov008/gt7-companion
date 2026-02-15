import 'package:fluid_background/fluid_background.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../router/app_router.dart';
import '../services/telemetry_service.dart';
import '../widgets/gt_auto_display.dart';
import '../widgets/legendary_car_display.dart';
import '../widgets/playstation_scanner_dialog.dart';
import '../widgets/telemetry_display.dart';
import '../widgets/used_car_display.dart';
import '../widgets/daily_races_display.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _ipController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _ipController.text = '192.168.1.123';
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _openTelemetry(BuildContext context) {
    context.router.push(const TelemetryDetailsScreenRoute());
  }

  void _openUsedCarDealer(BuildContext context) {
    context.router.push(const UsedCarDisplayRoute());
  }

  void _openLegendaryCarDealer(BuildContext context) {
    context.router.push(const LegendaryCarDisplayRoute());
  }

  void _openGTAuto(BuildContext context) {
    context.router.push(const GTAutoDisplayRoute());
  }

  Widget _buildConnectionForm(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ipController,
                  style: TextStyle(color: theme.colorScheme.onBackground),
                  decoration: InputDecoration(
                    labelText: 'PlayStation IP',
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.onBackground.withOpacity(0.12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.85),
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: theme.iconTheme.color),
                      tooltip: 'Scan for PlayStation',
                      onPressed: () async {
                        final selectedIp = await showDialog<String>(
                          context: context,
                          builder: (context) =>
                              const PlayStationScannerDialog(),
                        );
                        if (selectedIp != null) {
                          _ipController.text = selectedIp;
                        }
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter IP';
                    }
                    final ipPattern = RegExp(
                      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
                    );
                    if (!ipPattern.hasMatch(value)) {
                      return 'Invalid IP';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56, // Match input height roughly
                child: Consumer<TelemetryService>(
                  builder: (context, service, _) {
                    if (service.isConnected) {
                      return ElevatedButton(
                        onPressed: () => service.disconnect(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        child: const Text('Disconnect'),
                      );
                    } else {
                      return ElevatedButton(
                        onPressed: _isConnecting
                            ? null
                            : () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  setState(() {
                                    _isConnecting = true;
                                  });
                                  await Provider.of<TelemetryService>(
                                    context,
                                    listen: false,
                                  ).connectToGT7(_ipController.text);
                                  setState(() {
                                    _isConnecting = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: _isConnecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Connect'),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Consumer<TelemetryService>(
            builder: (context, service, _) {
              if (service.isConnected) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status: Connected',
                      style: TextStyle(
                        color: theme.colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openTelemetry(context),
                      icon: Icon(
                        Icons.open_in_new,
                        color: theme.colorScheme.onBackground,
                      ),
                      label: Text(
                        'Open Dashboard',
                        style: TextStyle(color: theme.colorScheme.onBackground),
                      ),
                    ),
                  ],
                );
              } else if (service.errorMessage != null) {
                return Text(
                  'Error: ${service.errorMessage}',
                  style: TextStyle(color: theme.colorScheme.error),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return SafeArea(
      child: Scaffold(
        appBar: null,
        bottomNavigationBar: null,
        body: FluidBackground(
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
                  theme.colorScheme.background,
                ],
                // смещаем середину чуть выше для более явного перехода
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // telemetry header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(90),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            blurRadius: 24,
                            spreadRadius: 0,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Telemetry',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildConnectionForm(context, isDesktop),
                        ],
                      ),
                    ),

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
                                    color: theme.colorScheme.onBackground,
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
                                    color: theme.colorScheme.onBackground,
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
                                    color: theme.colorScheme.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const DailyRacesDisplay(),
                  ],
                ),
              ),
            ), // ConstrainedBox
          ), // Container
        ), // FluidBackground
      ), // Scaffold
    ); // SafeArea
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
                    color: theme.colorScheme.onBackground,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

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
