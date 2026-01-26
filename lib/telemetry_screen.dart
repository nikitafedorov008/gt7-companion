import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/telemetry_service.dart';
import 'widgets/playstation_scanner_dialog.dart';
import 'widgets/telemetry_display.dart';
import 'widgets/used_car_display.dart';
import 'widgets/legendary_car_display.dart';
import 'widgets/gt_auto_display.dart';

class TelemetryScreen extends StatelessWidget {
  const TelemetryScreen({super.key});

  void _openTelemetry(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TelemetryDetailsScreen()));
  }

  void _openUsedCarDealer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Used car dealer')),
          body: const UsedCarDisplay(),
        ),
      ),
    );
  }

  void _openLegendaryCarDealer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Legendary car dealer')),
          body: const LegendaryCarDisplay(),
        ),
      ),
    );
  }

  void _openGTAuto(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('GT Auto')),
          body: const GTAutoDisplay(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: const Text('GT7 Companion Flutter'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _openTelemetry(context),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Telemetry',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Apps', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine crossAxisCount based on screen width
                // For example: 2 columns for mobile, 3 for tablet, 4+ for desktop
                final width = constraints.maxWidth;
                int crossAxisCount = 2;
                if (width > 600) crossAxisCount = 3;
                if (width > 900) crossAxisCount = 4;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25, // Adjust as needed
                  children: [
                    _AppTile(
                      icon: Icons.storefront,
                      label: 'Used car dealer',
                      onTap: () => _openUsedCarDealer(context),
                    ),
                    _AppTile(
                      icon: Icons.star,
                      label: 'Legendary car dealer',
                      onTap: () => _openLegendaryCarDealer(context),
                    ),
                    _AppTile(
                      icon: Icons.build,
                      label: 'GT Auto',
                      onTap: () => _openGTAuto(context),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AppTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TelemetryDetailsScreen extends StatefulWidget {
  const TelemetryDetailsScreen({super.key});

  @override
  State<TelemetryDetailsScreen> createState() => _TelemetryDetailsScreenState();
}

class _TelemetryDetailsScreenState extends State<TelemetryDetailsScreen> {
  List<Widget> _buildConnectionControls(bool isDesktop) {
    if (isDesktop) {
      return [
        Expanded(
          child: TextFormField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'PlayStation IP Address',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Scan for PlayStation',
                onPressed: () async {
                  final selectedIp = await showDialog<String>(
                    context: context,
                    builder: (context) => const PlayStationScannerDialog(),
                  );
                  if (selectedIp != null) {
                    _ipController.text = selectedIp;
                  }
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an IP address';
              }
              final ipPattern = RegExp(
                r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
              );
              if (!ipPattern.hasMatch(value)) {
                return 'Please enter a valid IP address';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 240, // фиксированная ширина для кнопок
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isConnecting
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
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
                  child: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Consumer<TelemetryService>(
                  builder: (context, service, _) => ElevatedButton(
                    onPressed: service.isConnected
                        ? () => service.disconnect()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Disconnect'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    } else {
      // Для мобильного режима - вертикальный layout
      return [
        TextFormField(
          controller: _ipController,
          decoration: InputDecoration(
            labelText: 'PlayStation IP Address',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Scan for PlayStation',
              onPressed: () async {
                final selectedIp = await showDialog<String>(
                  context: context,
                  builder: (context) => const PlayStationScannerDialog(),
                );
                if (selectedIp != null) {
                  _ipController.text = selectedIp;
                }
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an IP address';
            }
            final ipPattern = RegExp(
              r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
            );
            if (!ipPattern.hasMatch(value)) {
              return 'Please enter a valid IP address';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isConnecting
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
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
                child: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Consumer<TelemetryService>(
                builder: (context, service, _) => ElevatedButton(
                  onPressed: service.isConnected
                      ? () => service.disconnect()
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Disconnect'),
                ),
              ),
            ),
          ],
        ),
      ];
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Telemetry'),
        actions: [
          Consumer<TelemetryService>(
            builder: (context, service, child) {
              return IconButton(
                icon: Icon(
                  service.isConnected ? Icons.link : Icons.link_off,
                  color: service.isConnected ? Colors.green : Colors.red,
                ),
                onPressed: () {
                  if (service.isConnected) {
                    service.disconnect();
                  }
                },
                tooltip: service.isConnected ? 'Disconnect' : 'Not Connected',
              );
            },
          ),
        ],
      ),
      body: Consumer<TelemetryService>(
        builder: (context, service, child) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: isDesktop
                      ? Row(children: _buildConnectionControls(isDesktop))
                      : Column(children: _buildConnectionControls(isDesktop)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: service.isConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      service.isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: service.isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (service.errorMessage != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Error: ${service.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TelemetryDisplay(
                  telemetry: service.telemetry,
                  errorMessage: service.errorMessage,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
