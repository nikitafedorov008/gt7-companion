import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/telemetry_service.dart';
import '../../services/udp_service.dart';
import 'playstation_scanner_dialog.dart';

/// The telemetry connection panel on the home page.
///
/// Styled like the rest of the app rather than as a feature banner: a dark
/// translucent panel with a hairline border, a small letterspaced heading and
/// a status chip. GT7 never colours a whole panel to say what state something
/// is in — it prints a badge and leaves the panel alone — so connection state
/// lives in the chip, and colour is spent only on the one call to action.
class TelemetryPanel extends StatefulWidget {
  const TelemetryPanel({super.key});

  @override
  State<TelemetryPanel> createState() => _TelemetryPanelState();
}

class _TelemetryPanelState extends State<TelemetryPanel> {
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

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isConnecting = true);
    final service = context.read<TelemetryService>();
    await service.connectToGT7(_ipController.text);
    if (mounted) setState(() => _isConnecting = false);
  }

  Future<void> _startDemo() async {
    final tabsRouter = context.tabsRouter;
    setState(() => _isConnecting = true);
    try {
      await context.read<TelemetryService>().startDemoTelemetry();
      if (!mounted) return;
      tabsRouter.setActiveIndex(3);
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TELEMETRY',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
              Consumer<TelemetryService>(
                builder: (context, service, _) =>
                    _StatusChip(service: service, connecting: _isConnecting),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Form(key: _formKey, child: _buildConnectionRow(context)),
          const SizedBox(height: 12),
          _buildPacketRow(context),
          const SizedBox(height: 10),
          Consumer<TelemetryService>(
            builder: (context, service, _) => _buildFooter(context, service),
          ),
        ],
      ),
    );
  }

  Widget _buildPacketRow(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TelemetryService>(
      builder: (context, service, _) {
        return Row(
          children: [
            Text(
              'PACKET',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.4,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 10),
            for (final type in UdpService.packetTypes) ...[
              _PacketChip(
                type: type,
                selected: service.packetType == type,
                onTap: () => service.packetType = type,
              ),
              const SizedBox(width: 6),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _packetHint(service.packetType),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _packetHint(String type) => switch (type) {
        'A' => '296 bytes: position, rotation, lap times — no steering',
        'B' => '316 bytes: adds steering angle and g-forces',
        _ => '368 bytes: adds surfaces and car category',
      };

  Widget _buildConnectionRow(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _ipController,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              labelText: 'PlayStation IP',
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.25),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, size: 20),
                tooltip: 'Scan for PlayStation',
                onPressed: () async {
                  final selectedIp = await showDialog<String>(
                    context: context,
                    builder: (_) => const PlayStationScannerDialog(),
                  );
                  if (selectedIp != null) _ipController.text = selectedIp;
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter IP';
              final ipPattern = RegExp(
                r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
                r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
              );
              if (!ipPattern.hasMatch(value)) return 'Invalid IP';
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Consumer<TelemetryService>(
          builder: (context, service, _) {
            if (service.isConnected) {
              return _PanelButton(
                label: 'Disconnect',
                color: theme.colorScheme.error,
                onPressed: service.disconnect,
              );
            }
            return _PanelButton(
              label: 'Connect',
              color: theme.colorScheme.primary,
              busy: _isConnecting,
              onPressed: _isConnecting ? null : _connect,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, TelemetryService service) {
    final theme = Theme.of(context);

    if (service.isConnected) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.tabsRouter.setActiveIndex(3),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Open dashboard'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            padding: EdgeInsets.zero,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _isConnecting ? null : _startDemo,
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: const Text('Demo telemetry'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        if (service.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              service.errorMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// Connection state as a badge, the way the game states things.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.service, required this.connecting});

  final TelemetryService service;
  final bool connecting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (label, color) = switch (service) {
      _ when connecting => ('CONNECTING', theme.colorScheme.primary),
      _ when service.isConnected && service.isDemo => (
        'DEMO',
        theme.colorScheme.secondary,
      ),
      _ when service.isConnected => ('CONNECTED', theme.colorScheme.primary),
      _ when service.errorMessage != null => (
        'ERROR',
        theme.colorScheme.error,
      ),
      _ => ('OFFLINE', theme.colorScheme.onSurface.withValues(alpha: 0.4)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// The panel's one call to action, sized to sit level with the input.
class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.label,
    required this.color,
    this.onPressed,
    this.busy = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black87,
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

/// One of the heartbeat characters: what the console is asked to send.
class _PacketChip extends StatelessWidget {
  const _PacketChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.25),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.white12,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: selected ? theme.colorScheme.primary : Colors.white70,
          ),
        ),
      ),
    );
  }
}
