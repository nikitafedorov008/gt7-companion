import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/telemetry/telemetry_data.dart';
import '../../repositories/track_repository.dart';
import '../../theme/gt7_theme.dart';
import '../../utils/dev_flags.dart';
import 'gt7_hud.dart';
import 'telemetry_display.dart';

/// Which of the two telemetry presentations is on screen.
enum TelemetryView {
  /// A replica of the game's own race HUD.
  hud,

  /// Graphs and the full set of numeric readouts.
  data,
}

/// Hosts both telemetry presentations and the switch between them.
///
/// The in-game HUD is the default, because that is what a companion screen
/// should look like at a glance; the graphs live one button away (or one
/// keystroke - `H` and `Tab` both toggle).
class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key, this.telemetry, this.errorMessage});

  final TelemetryData? telemetry;
  final String? errorMessage;

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  late TelemetryView _view = kInitialTelemetryView == 'data'
      ? TelemetryView.data
      : TelemetryView.hud;

  int _mfdPage = kInitialMfdPage;

  void _toggle() {
    setState(() {
      _view = _view == TelemetryView.hud ? TelemetryView.data : TelemetryView.hud;
    });
  }

  /// Cycle the HUD's MFD page, the way the game's left/right buttons do.
  void _stepMfd(int delta) {
    setState(() {
      _mfdPage = (_mfdPage + delta + mfdTitles.length) % mfdTitles.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = widget.telemetry;
    // The route is recorded from the packet stream, so both presentations can
    // draw it: the HUD as its TRACK MAP page, the data view as a panel.
    final trace = context.watch<TrackTraceRepository>().trace;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyH): _toggle,
        const SingleActivator(LogicalKeyboardKey.tab): _toggle,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _stepMfd(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _stepMfd(1),
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                _ViewBar(
                  view: _view,
                  onChanged: (view) => setState(() => _view = view),
                  topSpeed: telemetry?.estTopSpeed,
                ),
                Expanded(
                  child: telemetry == null
                      ? _EmptyState(errorMessage: widget.errorMessage)
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: _view == TelemetryView.hud
                              ? Gt7Hud(
                                  key: const ValueKey('hud'),
                                  telemetry: telemetry,
                                  trace: trace,
                                  mfdPage: _mfdPage,
                                  onMfdPage: (page) =>
                                      setState(() => _mfdPage = page),
                                )
                              : TelemetryDisplay(
                                  key: const ValueKey('data'),
                                  telemetry: telemetry,
                                  trace: trace,
                                ),
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

/// Header with the two view buttons - the game's own way of switching what the
/// screen shows.
class _ViewBar extends StatelessWidget {
  const _ViewBar({
    required this.view,
    required this.onChanged,
    this.topSpeed,
  });

  final TelemetryView view;
  final ValueChanged<TelemetryView> onChanged;
  final int? topSpeed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          Text(
            'TELEMETRY',
            style: gt7Caption(
              color: gt7Text,
              size: 12,
              letterSpacing: 2.2,
              weight: FontWeight.w700,
            ),
          ),
          if (topSpeed != null && topSpeed! > 0) ...[
            const SizedBox(width: 14),
            Text(
              'TOP SPEED EST. $topSpeed KM/H',
              style: gt7Caption(
                color: gt7TextMuted.withValues(alpha: 0.7),
                size: 9,
              ),
            ),
          ],
          const Spacer(),
          _ViewButton(
            label: 'HUD',
            selected: view == TelemetryView.hud,
            onTap: () => onChanged(TelemetryView.hud),
          ),
          const SizedBox(width: 6),
          _ViewButton(
            label: 'DATA',
            selected: view == TelemetryView.data,
            onTap: () => onChanged(TelemetryView.data),
          ),
          const SizedBox(width: 10),
          Text(
            'H',
            style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.5), size: 9),
          ),
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? gt7Text.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? gt7Text.withValues(alpha: 0.55) : gt7Hairline,
          ),
        ),
        child: Text(
          label,
          style: gt7Caption(
            color: selected ? gt7Text : gt7TextMuted,
            size: 10,
            letterSpacing: 1.6,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final isError = errorMessage != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isError ? 'LINK ERROR' : 'WAITING FOR TELEMETRY',
              style: gt7Caption(
                color: isError ? gt7Warn : gt7TextMuted,
                size: 12,
                letterSpacing: 2.0,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage ?? 'No packets received yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: gt7TextMuted.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
