import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/throttle_brake_graph/throttle_brake_graph_bloc.dart';
import '../../blocs/throttle_brake_graph/throttle_brake_graph_event.dart';
import '../../blocs/throttle_brake_graph/throttle_brake_graph_state.dart';
import '../../theme/gt7_theme.dart';

/// Throttle, brake and clutch inputs as a time-series trace.
///
/// Drawn in the game's Data Logger plot language: a dark plotting area, 1 px
/// gridlines, thin traces, a labelled axis and a live numeric readout column
/// beside the graph. The throttle trace is white and the brake trace red, the
/// same pairing the game uses for its pedal bars; the clutch takes the HUD's
/// cyan, which nothing else in this plot uses.
///
/// The clutch trace is drawn **only when the window has clutch in it**. Most
/// cars are driven with paddles, where the packet's clutch stays at zero, and a
/// line pinned to the axis would be noise pretending to be data. The readout
/// beside the graph always shows the value, so an absent trace is not a
/// question the driver has to ask twice.
class ThrottleBrakeGraph extends StatefulWidget {
  final double height;

  /// Drops the panel chrome, for when the graph is embedded in a panel that
  /// already draws its own frame (the HUD's MFD).
  final bool bare;

  const ThrottleBrakeGraph({
    super.key,
    this.height = 230.0,
    this.bare = false,
  });

  @override
  State<ThrottleBrakeGraph> createState() => _ThrottleBrakeGraphState();
}

class _ThrottleBrakeGraphState extends State<ThrottleBrakeGraph> {
  @override
  void initState() {
    super.initState();
    // Initialize the BLoC when widget is created
    context.read<ThrottleBrakeGraphBloc>().add(
          const ThrottleBrakeGraphEvent.initialize(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThrottleBrakeGraphBloc, ThrottleBrakeGraphState>(
      builder: (context, state) {
        return Container(
          height: widget.height,
          padding: widget.bare
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: widget.bare ? null : gt7PanelDecoration(),
          child: state.when(
            initial: () => const _LoadingPlaceholder(),
            loading: () => const _LoadingPlaceholder(),
            success: (history) {
              if (history.isEmpty) {
                return const _NoDataPlaceholder();
              }
              return _buildGraphContent(context, history);
            },
            error: (message) => _ErrorPlaceholder(message: message),
          ),
        );
      },
    );
  }

  Widget _buildGraphContent(
    BuildContext context,
    List<ThrottleBrakeDataPoint> history,
  ) {
    final graphColors = Theme.of(context).extension<GT7GraphColors>();
    final latest = history.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('THROTTLE / BRAKE', style: gt7Caption()),
            const Spacer(),
            Text(
              '10 S WINDOW',
              style: gt7Caption(
                color: gt7TextMuted.withValues(alpha: 0.6),
                size: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _ThrottleBrakeGraphPainter(
                    history: history,
                    grid: graphColors?.grid ?? const Color(0x14FFFFFF),
                    plot: graphColors?.track ?? gt7Plot,
                    axis: gt7TextMuted.withValues(alpha: 0.45),
                    label: gt7TextMuted,
                    throttle: graphColors?.lineA ?? gt7Text,
                    brake: graphColors?.lineB ?? gt7Warn,
                    clutch: gt7SlotA,
                    clutchEngaged: gt7SlotB,
                  ),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(width: 12),
              _LiveReadout(
                throttle: latest.throttle,
                brake: latest.brake,
                clutch: latest.clutch,
                clutchEngaged: latest.clutchEngaged,
                // The same rule as the traces: shown when the clutch is a real
                // pedal on this car, absent when it never moves.
                showClutch: history.any((p) => p.clutch > 1.0),
                throttleColor: graphColors?.lineA ?? gt7Text,
                brakeColor: graphColors?.lineB ?? gt7Warn,
                clutchColor: gt7SlotA,
                engagedColor: gt7SlotB,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The numeric readout column the game keeps beside its traces.
class _LiveReadout extends StatelessWidget {
  const _LiveReadout({
    required this.throttle,
    required this.brake,
    required this.clutch,
    required this.clutchEngaged,
    required this.showClutch,
    required this.throttleColor,
    required this.brakeColor,
    required this.clutchColor,
    required this.engagedColor,
  });

  final double throttle;
  final double brake;
  final double clutch;
  final double clutchEngaged;
  final bool showClutch;
  final Color throttleColor;
  final Color brakeColor;
  final Color clutchColor;
  final Color engagedColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _entry('THROTTLE', throttle, throttleColor),
          const SizedBox(height: 12),
          _entry('BRAKE', brake, brakeColor),
          // Four entries have to fit the column the graph leaves them, so the
          // clutch pair is tighter than the pedal pair.
          if (showClutch) ...[
            const SizedBox(height: 10),
            _entry('CLUTCH', clutch, clutchColor, size: 17),
            const SizedBox(height: 8),
            _entry('ENGAGED', clutchEngaged, engagedColor, size: 17),
          ],
        ],
      ),
    );
  }

  Widget _entry(String label, double value, Color color, {double size = 20}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 2, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: gt7Caption(size: 9, letterSpacing: 1.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            maxLines: 1,
            softWrap: false,
            style: gt7Digital(size: size, color: color),
          ),
        ),
      ],
    );
  }
}

/// Custom painter that renders the throttle/brake traces on a dark plot.
class _ThrottleBrakeGraphPainter extends CustomPainter {
  _ThrottleBrakeGraphPainter({
    required this.history,
    required this.grid,
    required this.plot,
    required this.axis,
    required this.label,
    required this.throttle,
    required this.brake,
    required this.clutch,
    required this.clutchEngaged,
  });

  final List<ThrottleBrakeDataPoint> history;
  final Color grid;
  final Color plot;
  final Color axis;
  final Color label;
  final Color throttle;
  final Color brake;
  final Color clutch;
  final Color clutchEngaged;

  static const double _leftPad = 34;
  static const double _topPad = 6;
  static const double _rightPad = 6;
  static const double _bottomPad = 18;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty || size.width <= _leftPad + 12 || size.height <= 40) {
      return;
    }

    final plotRect = Rect.fromLTRB(
      _leftPad,
      _topPad,
      size.width - _rightPad,
      size.height - _bottomPad,
    );

    canvas.drawRect(plotRect, Paint()..color = plot);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1.0;

    // Horizontal gridlines + percentage labels.
    const horizontalSteps = [0.0, 25.0, 50.0, 75.0, 100.0];
    for (final step in horizontalSteps) {
      final y = plotRect.bottom - plotRect.height * (step / 100.0);
      canvas.drawLine(Offset(plotRect.left, y), Offset(plotRect.right, y), gridPaint);
      _paintLabel(
        canvas,
        step.toStringAsFixed(0),
        Offset(plotRect.left - 6, y),
        alignRight: true,
      );
    }

    // Vertical gridlines + window labels (the graph holds a rolling window,
    // so the axis reads right-to-left in seconds from "now").
    const verticalSteps = [0.0, 0.5, 1.0];
    const verticalLabels = ['-10s', '-5s', 'now'];
    for (var i = 0; i < verticalSteps.length; i++) {
      final x = plotRect.left + plotRect.width * verticalSteps[i];
      canvas.drawLine(Offset(x, plotRect.top), Offset(x, plotRect.bottom), gridPaint);
      _paintLabel(
        canvas,
        verticalLabels[i],
        Offset(x, plotRect.bottom + 5),
        centered: true,
      );
    }

    canvas.drawRect(
      plotRect,
      Paint()
        ..color = axis
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Traces, clipped so a series can never bleed outside the plot.
    canvas.save();
    canvas.clipRect(plotRect);
    _drawTrace(canvas, plotRect, history.map((p) => p.throttle).toList(), throttle);
    _drawTrace(canvas, plotRect, history.map((p) => p.brake).toList(), brake);

    // Only when the clutch has actually moved: a pressed clutch is an event, and
    // a paddle-shift car never produces one.
    // The pedal first, then how far the clutch actually went in: where the two
    // differ, that gap is the slip.
    final clutchValues = history.map((p) => p.clutch).toList();
    if (clutchValues.any((value) => value > 1.0)) {
      _drawTrace(canvas, plotRect, clutchValues, clutch);
      _drawTrace(
        canvas,
        plotRect,
        history.map((p) => p.clutchEngaged).toList(),
        clutchEngaged,
        width: 1.3,
      );
    }
    canvas.restore();
  }

  void _drawTrace(
    Canvas canvas,
    Rect plotRect,
    List<double> values,
    Color color, {
    double width = 1.8,
  }) {
    if (values.length < 2) return;

    final path = ui.Path();
    for (var i = 0; i < values.length; i++) {
      final dx = plotRect.left + plotRect.width * (i / (values.length - 1));
      final dy =
          plotRect.bottom - plotRect.height * (values[i].clamp(0.0, 100.0) / 100.0);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
    bool centered = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: label,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = switch ((alignRight, centered)) {
      (true, _) => Offset(anchor.dx - painter.width, anchor.dy - painter.height / 2),
      (_, true) => Offset(anchor.dx - painter.width / 2, anchor.dy),
      _ => anchor,
    };
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ThrottleBrakeGraphPainter oldDelegate) {
    return oldDelegate.history.length != history.length ||
        (history.isNotEmpty &&
            (oldDelegate.history.isEmpty ||
                oldDelegate.history.last != history.last)) ||
        oldDelegate.throttle != throttle ||
        oldDelegate.brake != brake;
  }
}

/// Placeholder when loading
class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// Placeholder when no data available
class _NoDataPlaceholder extends StatelessWidget {
  const _NoDataPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'WAITING FOR INPUT DATA',
        style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.8), size: 11),
      ),
    );
  }
}

/// Placeholder when error occurs
class _ErrorPlaceholder extends StatelessWidget {
  final String message;

  const _ErrorPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'GRAPH ERROR: $message',
        textAlign: TextAlign.center,
        style: gt7Caption(color: gt7Warn, size: 11),
      ),
    );
  }
}
