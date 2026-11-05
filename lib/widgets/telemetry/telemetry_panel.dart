import '../gt_loading_indicator.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../l10n/ui_messages.dart';
import '../../repositories/car_catalog.dart';
import '../../repositories/telemetry_connection_repository.dart';
import '../../services/telemetry_service.dart';
import 'telemetry_connection_dialog.dart';

/// Compact home entry. Protocol, freshness and automatic work belong to the
/// connection repository; only explicit user actions open the instruments.
class TelemetryPanel extends StatefulWidget {
  const TelemetryPanel({super.key});
  @override
  State<TelemetryPanel> createState() => _TelemetryPanelState();
}

class _TelemetryPanelState extends State<TelemetryPanel> {
  String? _manualAddress;
  bool _busy = false;
  Future<void> _configure({bool connect = false}) async {
    final service = context.read<TelemetryService>();
    final repo = context.read<TelemetryConnectionRepository>();
    final result = await showDialog<TelemetryConnectionSettings>(
      context: context,
      builder: (_) => TelemetryConnectionDialog(
        ipAddress:
            _manualAddress ??
            repo.address ??
            repo.settings.confirmedConsole ??
            '',
        packetType: service.packetType,
        connect: connect,
      ),
    );
    if (!mounted || result == null) return;
    final changed = (repo.address ?? _manualAddress) != result.ipAddress;
    _manualAddress = result.ipAddress;
    service.packetType = result.packetType;
    if (connect || (changed && service.isConnected && !service.isDemo)) {
      await _perform(() => repo.connectManual(result.ipAddress));
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(TelemetryConnectionRepository repo) async {
    final candidate = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.telemetryChoose),
        children: [
          for (final item in repo.candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(item.address),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('${item.name} · ${item.platform}\n${item.address}'),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
    if (!mounted || candidate == null) return;
    final name = repo.candidates
        .where((c) => c.address == candidate)
        .firstOrNull
        ?.name;
    await _perform(() => repo.connectManual(candidate, name: name));
  }

  @override
  Widget build(
    BuildContext context,
  ) => Consumer3<TelemetryConnectionRepository, TelemetryService, CarCatalog>(
    builder: (context, repo, service, catalog, _) {
      final theme = Theme.of(context), l10n = context.l10n;
      final colors = theme.colorScheme;
      final phase = repo.phase;
      final live = phase == ConnectionPhase.live && repo.hasFreshData;
      final demo = phase == ConnectionPhase.demo;
      final car = live ? catalog.byPacketId(service.telemetry!.carId) : null;
      final title = live
          ? car?.name ??
                '${l10n.telemetryUnknownCar} · ${service.telemetry!.carId}'
          : switch (phase) {
              ConnectionPhase.searching => l10n.telemetrySearchTitle,
              ConnectionPhase.choose => l10n.telemetryChoose,
              ConnectionPhase.notFound => l10n.telemetryNotFound,
              ConnectionPhase.demo => l10n.telemetryDemoDescription,
              _ => repo.consoleName ?? 'PlayStation',
            };
      final description = live
          ? '${repo.consoleName ?? 'PlayStation'} · ${repo.address ?? ''} · ${l10n.telemetryPacketShort} ${service.telemetry!.packetType}'
          : switch (phase) {
              ConnectionPhase.searching => l10n.telemetryAutoHelp,
              ConnectionPhase.waiting => l10n.telemetryWaitingHelp,
              ConnectionPhase.choose => l10n.telemetryChooseHelp,
              ConnectionPhase.lost => l10n.telemetryLostHelp,
              ConnectionPhase.unavailable => l10n.telemetryIdleHelp,
              ConnectionPhase.demo => l10n.telemetryDemoBadge,
              _ => l10n.telemetryIdleHelp,
            };
      return LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 1000 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.25;
          final intro = Row(
            children: [
              SizedBox(
                width: wide ? 96 : 64,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (car != null && car.manufacturerId.isNotEmpty)
                      ClipRect(
                        child: SizedBox(
                          height: 44,
                          width: wide ? 96 : 64,
                          child: Image.network(
                            'https://www.gran-turismo.com/common/dist/gt7/carlist/tuner_logos/dark/${car.manufacturerId}.png',
                            key: ValueKey(
                              'telemetry-brand-${car.manufacturerId}',
                            ),
                            fit: BoxFit.cover,
                            semanticLabel: car.name,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                car.name,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                ? child
                                : const SizedBox.shrink(),
                          ),
                        ),
                      )
                    else
                      ExcludeSemantics(
                        child: SvgPicture.asset(
                          'assets/images/telemetry_connection.svg',
                          key: const ValueKey('telemetry-connection-art'),
                          height: 44,
                          colorFilter: ColorFilter.mode(
                            colors.onSurface.withValues(alpha: .8),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Semantics(
                      label: l10n.telemetryPlatforms,
                      child: Row(
                        key: const ValueKey('telemetry-platforms'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final platform in ['PS4', 'PS5']) ...[
                            if (platform == 'PS5') const SizedBox(width: 6),
                            SizedBox(
                              width: wide ? 36 : 28,
                              height: 10,
                              child: SvgPicture.asset(
                                'assets/images/${platform.toLowerCase()}_logo.svg',
                                key: ValueKey('telemetry-platform-$platform'),
                                semanticsLabel: platform,
                                width: wide ? 36 : 28,
                                height: 10,
                                colorFilter: ColorFilter.mode(
                                  colors.onSurface.withValues(alpha: .5),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.telemetryTitle.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1,
                            color: colors.onSurface.withValues(alpha: .55),
                          ),
                        ),
                        _ConnectionStatus(phase: phase),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      key: const ValueKey('telemetry-car-title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final primaryLabel = live || demo
              ? (wide ? l10n.telemetryOpen : l10n.telemetryInstruments)
              : phase == ConnectionPhase.choose
              ? l10n.telemetryChoose
              : phase == ConnectionPhase.lost ||
                    phase == ConnectionPhase.notFound
              ? l10n.telemetryRetry
              : l10n.telemetryManual;
          final actions = Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton(
                  key: const ValueKey('telemetry-connect'),
                  onPressed: _busy
                      ? null
                      : () {
                          if (live || demo) {
                            context.tabsRouter.setActiveIndex(3);
                          } else if (phase == ConnectionPhase.choose) {
                            _choose(repo);
                          } else if (phase == ConnectionPhase.lost ||
                              phase == ConnectionPhase.notFound) {
                            repo.search(explicit: true);
                          } else {
                            _configure(connect: true);
                          }
                        },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.standard,
                    backgroundColor: colors.onSurface,
                    foregroundColor: colors.surface,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: const StadiumBorder(),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(primaryLabel, textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  key: const ValueKey('telemetry-settings'),
                  onPressed: _busy ? null : _configure,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.standard,
                    foregroundColor: colors.onSurface.withValues(alpha: .7),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(l10n.settings, textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 56,
                child: PopupMenuButton<String>(
                  key: const ValueKey('telemetry-more'),
                  tooltip: l10n.telemetryMore,
                  enabled: !_busy,
                  onSelected: (value) async {
                    if (value == 'manual') {
                      await _configure(connect: true);
                    }
                    if (value == 'search') {
                      await repo.search(explicit: true);
                    }
                    if (value == 'disconnect') {
                      await _perform(repo.disconnect);
                    }
                    if (value == 'demo') {
                      final tabs = context.tabsRouter;
                      await _perform(repo.startDemo);
                      if (mounted) tabs.setActiveIndex(3);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'demo', child: Text(l10n.uiDemo)),
                    PopupMenuItem(
                      value: 'manual',
                      child: Text(l10n.telemetryManual),
                    ),
                    PopupMenuItem(
                      value: 'search',
                      child: Text(l10n.telemetryRetry),
                    ),
                    PopupMenuItem(
                      key: const ValueKey('telemetry-menu-disconnect'),
                      value: 'disconnect',
                      child: Text(l10n.uiDisconnect),
                    ),
                  ],
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      l10n.telemetryMore,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: .6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
          return Container(
            key: const ValueKey('telemetry-panel'),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 20 : 16,
              vertical: 16,
            ),
            constraints: BoxConstraints(minHeight: wide ? 114 : 0),
            decoration: BoxDecoration(
              color: colors.surfaceContainer.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.onSurface.withValues(alpha: .16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  Row(
                    children: [
                      Expanded(child: intro),
                      const SizedBox(width: 24),
                      SizedBox(width: 390, child: actions),
                    ],
                  )
                else ...[
                  intro,
                  const SizedBox(height: 16),
                  actions,
                ],
                if (service.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.tr(service.errorMessage!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({required this.phase});
  final ConnectionPhase phase;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), l10n = context.l10n;
    final label = switch (phase) {
      ConnectionPhase.live => l10n.telemetryLive,
      ConnectionPhase.searching => l10n.telemetrySearch,
      ConnectionPhase.waiting => l10n.telemetryWaiting,
      ConnectionPhase.choose => l10n.telemetryChoose,
      ConnectionPhase.lost => l10n.telemetryLost,
      ConnectionPhase.demo => l10n.telemetryDemoBadge,
      _ => l10n.telemetryManual,
    };
    final color = phase == ConnectionPhase.live
        ? HSLColor.fromColor(
            theme.colorScheme.tertiary,
          ).withHue(150).withSaturation(.3).withLightness(.7).toColor()
        : phase == ConnectionPhase.lost
        ? HSLColor.fromColor(
            theme.colorScheme.error,
          ).withHue(40).withSaturation(.45).withLightness(.7).toColor()
        : theme.colorScheme.onSurface.withValues(alpha: .6);
    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .05),
            border: Border.all(color: color.withValues(alpha: .3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (phase == ConnectionPhase.searching &&
                  !MediaQuery.disableAnimationsOf(context))
                SizedBox(
                  width: 18,
                  height: 18,
                  child: GtLoadingIndicator(size: 18),
                )
              else
                Icon(
                  phase == ConnectionPhase.waiting
                      ? Icons.circle_outlined
                      : Icons.circle,
                  size: 6,
                  color: color,
                ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
