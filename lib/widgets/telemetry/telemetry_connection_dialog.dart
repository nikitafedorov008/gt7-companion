import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_settings_service.dart';
import 'dart:io' show Platform;
import '../../l10n/ui_messages.dart';
import '../../services/udp_service.dart';
import 'playstation_scanner_dialog.dart';

typedef TelemetryConnectionSettings = ({String ipAddress, String packetType});

/// Changes remain a draft until the user submits the dialog.
class TelemetryConnectionDialog extends StatefulWidget {
  const TelemetryConnectionDialog({
    super.key,
    required this.ipAddress,
    required this.packetType,
    this.connect = false,
  });
  final String ipAddress;
  final String packetType;
  final bool connect;

  @override
  State<TelemetryConnectionDialog> createState() =>
      _TelemetryConnectionDialogState();
}

class _TelemetryConnectionDialogState extends State<TelemetryConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _ipController = TextEditingController(text: widget.ipAddress);
  late String _packetType = widget.packetType;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop<TelemetryConnectionSettings>((
      ipAddress: _ipController.text.trim(),
      packetType: _packetType,
    ));
  }

  Future<void> _scan() async {
    final address = await showDialog<String>(
      context: context,
      builder: (_) => const PlayStationScannerDialog(),
    );
    if (mounted && address != null) _ipController.text = address;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    return Dialog(
      backgroundColor: colors.surfaceContainer,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.onSurface.withValues(alpha: 0.16)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.telemetryConnectionSettings,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('telemetry-settings-close'),
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const TelemetryAutoSettings(),
                const SizedBox(height: 16),
                Text(
                  l10n.telemetryNetworkHelp,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('telemetry-ip'),
                  controller: _ipController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.uiPlaystationIp,
                    suffixIcon: IconButton(
                      key: const ValueKey('telemetry-scan'),
                      tooltip: l10n.uiScanForPlaystation,
                      onPressed: _scan,
                      icon: const Icon(Icons.search),
                    ),
                  ),
                  validator: (value) {
                    final address = value?.trim() ?? '';
                    if (address.isEmpty) return l10n.uiEnterIp;
                    final parts = address.split('.');
                    if (parts.length != 4 ||
                        parts.any(
                          (part) =>
                              !RegExp(r'^\d{1,3}$').hasMatch(part) ||
                              int.parse(part) > 255,
                        )) {
                      return l10n.uiInvalidIp;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.telemetryPacketFormat,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in UdpService.packetTypes)
                      ChoiceChip(
                        key: ValueKey('telemetry-packet-$type'),
                        label: Text(type),
                        selected: _packetType == type,
                        selectedColor: colors.onSurface,
                        checkmarkColor: colors.surface,
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          color: _packetType == type
                              ? colors.surface
                              : colors.onSurface,
                        ),
                        onSelected: (_) => setState(() => _packetType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(switch (_packetType) {
                  'A' => l10n.telemetryPacketA,
                  'B' => l10n.telemetryPacketB,
                  '~' => l10n.telemetryPacketExtended,
                  _ => l10n.telemetryPacketC,
                }, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Text(
                  l10n.telemetryPacketHelp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('telemetry-settings-submit'),
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.onSurface,
                    foregroundColor: colors.surface,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    widget.connect
                        ? l10n.uiConnect
                        : l10n.telemetrySaveSettings,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The same immediate, persisted preference in global and connection settings.
class TelemetryAutoSettings extends StatelessWidget {
  const TelemetryAutoSettings({super.key});
  @override
  Widget build(BuildContext context) => Consumer<AppSettingsService>(
    builder: (context, settings, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.telemetryAutoTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Switch(
              key: const ValueKey('settings-telemetry-auto'),
              value: settings.autoTelemetry,
              onChanged: settings.setAutoTelemetry,
            ),
          ],
        ),
        Text(
          context.l10n.telemetryAutoHelp,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (Platform.isIOS) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.telemetryAutoIosHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (settings.storageError != null) ...[
          const SizedBox(height: 8),
          Text(
            context.tr(settings.storageError!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    ),
  );
}
