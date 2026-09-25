import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/telemetry/track_trace.dart';
import '../../theme/gt7_theme.dart';

/// The elevation the car has covered on the lap, drawn from the packet's
/// position Y (0x08).
///
/// GT7's own HUD never shows this; it is one of the few things the UDP feed
/// gives that the game keeps to itself, and on a circuit with real relief it
/// explains a lot about where the car is quick.
class ElevationProfile extends StatefulWidget {
  const ElevationProfile({
    super.key,
    required this.trace,
    this.height = 120,
    this.label = 'ELEVATION PROFILE',
    this.panel = true,
  });

  final TrackTrace trace;
  final double height;
  final String label;

  /// Wraps the plot in the usual panel; set false inside the HUD's MFD.
  final bool panel;

  @override
  State<ElevationProfile> createState() => _ElevationProfileState();
}

class _ElevationProfileState extends State<ElevationProfile> {
  int _cachedRevision = -1;
  int _cachedLap = -1;
  List<double> _distances = const [];
  List<double> _heights = const [];

  /// The profile only changes when the trace gains points, so it is rebuilt
  /// then and not per frame.
  void _rebuild() {
    final lap = widget.trace.laps;
    if (_cachedRevision == widget.trace.revision && _cachedLap == lap) return;
    _cachedRevision = widget.trace.revision;
    _cachedLap = lap;

    // Prefer the fastest completed lap: it is the one worth comparing against.
    final samples = widget.trace.bestLapSamples.isNotEmpty
        ? widget.trace.bestLapSamples
        : widget.trace.samples;

    final distances = <double>[];
    final heights = <double>[];
    var travelled = 0.0;
    for (var i = 0; i < samples.length; i++) {
      if (i > 0) {
        final dx = samples[i].x - samples[i - 1].x;
        final dz = samples[i].z - samples[i - 1].z;
        travelled += math.sqrt(dx * dx + dz * dz);
      }
      distances.add(travelled);
      heights.add(samples[i].y);
    }
    _distances = distances;
    _heights = heights;
  }

  @override
  Widget build(BuildContext context) {
    _rebuild();

    final hasProfile = _heights.length > 8 &&
        _distances.isNotEmpty &&
        _distances.last > 50;
    final body = hasProfile
        ? SizedBox(
            height: widget.height,
            child: CustomPaint(
              size: Size(double.infinity, widget.height),
              painter: _ElevationPainter(
                distances: _distances,
                heights: _heights,
              ),
            ),
          )
        : SizedBox(
            height: widget.height,
            child: Center(
              child: Text(
                'NO ELEVATION YET — THE PROFILE NEEDS A DRIVEN LAP',
                style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.6), size: 8),
              ),
            ),
          );

    if (!widget.panel) return body;

    final range = hasProfile
        ? '${(_heights.reduce(math.max) - _heights.reduce(math.min)).round()} m'
        : '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: gt7PanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: gt7Caption(
                  color: gt7Text,
                  size: 11,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'FROM POSITION Y (0x08), WHERE THE CAR ACTUALLY IS — '
                  'THE FASTEST LAP OF THE SESSION',
                  style: gt7Caption(
                    color: gt7TextMuted.withValues(alpha: 0.6),
                    size: 8,
                  ),
                ),
              ),
              Text(range, style: gt7Caption(color: gt7TextMuted, size: 9)),
            ],
          ),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }
}

class _ElevationPainter extends CustomPainter {
  _ElevationPainter({required this.distances, required this.heights});

  final List<double> distances;
  final List<double> heights;

  @override
  void paint(Canvas canvas, Size size) {
    if (distances.length < 2) return;

    var low = heights.first;
    var high = low;
    for (final value in heights) {
      low = math.min(low, value);
      high = math.max(high, value);
    }
    final span = math.max(high - low, 0.5);

    const padding = 14.0;
    final plot = Rect.fromLTRB(
      padding * 2,
      padding,
      size.width - padding,
      size.height - padding,
    );

    final grid = Paint()
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.06);
    for (var i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    final total = distances.last;
    final path = Path();
    for (var i = 0; i < heights.length; i++) {
      final x = plot.left + plot.width * (distances[i] / total);
      final y = plot.bottom - plot.height * ((heights[i] - low) / span);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Filled under the line, so climbs and drops read at a glance.
    final fill = Path.from(path)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gt7SlotA.withValues(alpha: 0.28),
            gt7SlotA.withValues(alpha: 0.02),
          ],
        ).createShader(plot),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = gt7SlotA,
    );

    // Scale labels: the range, in metres, top and bottom.
    _label(canvas, '${high.round()} m', Offset(plot.left - padding * 1.9, plot.top - 6));
    _label(canvas, '${low.round()} m', Offset(plot.left - padding * 1.9, plot.bottom - 10));
    _label(canvas, 'START', Offset(plot.left, plot.bottom + 2));
    _label(
      canvas,
      '${(total / 1000).toStringAsFixed(2)} km',
      Offset(plot.right - 34, plot.bottom + 2),
    );
  }

  void _label(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.7), size: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_ElevationPainter old) =>
      old.heights.length != heights.length ||
      old.distances.lastOrNull != distances.lastOrNull;
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
