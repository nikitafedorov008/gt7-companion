import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/telemetry/telemetry_data.dart';
import '../../models/telemetry/track_trace.dart';
import '../../services/telemetry_service.dart';
import 'car_plate.dart';
import 'elevation_profile.dart';
import 'g_force_ball.dart';
import 'motion_panel.dart';
import 'track_map.dart';
import '../../theme/gt7_theme.dart';
import 'telemetry_display.dart'
    show GaugeDial, gt7Count, gt7Distance, gt7Gear, gt7LapTime;
import 'throttle_brake_graph.dart';

/// A replica of Gran Turismo 7's in-race HUD.
///
/// Reference: the game's own race screen (manual `race/02`, 25 numbered
/// elements) as measured in `docs/reference/gt7-ui-spec.md`. What the game
/// shows, and what this draws:
///
///  * bottom-centre instrument cluster - speedometer left, tachometer right,
///    both with thin white needles (elements 15 / 18);
///  * between them the digital block: rev strip, speed, gear, `MT` (14), with
///    the throttle and brake bars and the brake-pressure bar beside it (19 / 16);
///  * tyre widget with the four tyres and their heat (20);
///  * fuel as an E-F arc inside the speedometer, with the odometer (15);
///  * position, lap, lap list with the fastest lap picked out in purple and the
///    signed gap to the best lap in blue/red (1 / 2 / 5 / 7 / 12);
///  * a shift lamp that lights before the limiter (13).
///
/// Not drawn, because GT7's UDP feed does not carry it: opponents (so no
/// proximity radar, no blindside arcs, no GPS with rivals), tyre wear and
/// compound, track map, driving-assist states.
class Gt7Hud extends StatelessWidget {
  const Gt7Hud({
    super.key,
    required this.telemetry,
    this.trace,
    this.mfdPage = 0,
    this.onMfdPage,
  });

  final TelemetryData telemetry;

  /// The route driven so far, for the TRACK MAP page. Without it that page
  /// explains that it needs a session.
  final TrackTrace? trace;

  /// Which MFD page is showing (see [mfdTitles]).
  final int mfdPage;
  final ValueChanged<int>? onMfdPage;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 1080;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The game sizes its cluster in fractions of the frame, not in fixed
        // pixels: the instrument cluster spans about 46% of the screen width,
        // each dial is about 12% of it, and the cluster sits ~7% above the
        // bottom edge. Reproduce that by laying the HUD out at a design width
        // and scaling the whole thing uniformly.
        final targetWidth = (constraints.maxWidth * _clusterWidthFraction)
            .clamp(520.0, _designWidth);
        final bottomMargin =
            constraints.maxHeight * _clusterBottomMarginFraction;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                constraints.maxHeight - (30 + bottomMargin),
                0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimingHeader(telemetry: telemetry, trace: trace),
                Center(
                  child: SizedBox(
                    width: targetWidth,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _designWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: CarPlate(telemetry: telemetry),
                            ),
                            const SizedBox(height: 12),
                            if (wide)
                              _Cluster(telemetry: telemetry)
                            else
                              _ClusterStacked(telemetry: telemetry),
                            const SizedBox(height: 14),
                            _MfdPanel(
                              telemetry: telemetry,
                              trace: trace,
                              page: mfdPage,
                              onPage: onMfdPage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The intrinsic width of the cluster row (tyres + dial + block + dial +
/// status, with the gaps between them). The whole HUD is laid out at this
/// width and then scaled uniformly, so the game's proportions survive any
/// window size.
const double _designWidth = 1410;

/// Share of the frame width the cluster band occupies. Tuned so the two dials
/// and the centre panel land on the game's own fractions of the frame: dial
/// ~11.5% of the width, panel ~16% (measured off the in-game cluster).
const double _clusterWidthFraction = 0.55;

/// Gap the game leaves between the cluster and the bottom of the screen.
const double _clusterBottomMarginFraction = 0.07;

/// The pages the MFD cycles through - the ones this app actually has data for.
const List<String> mfdTitles = [
  'SESSION BEST',
  'THROTTLE / BRAKE',
  'TYRES',
  'TEMPS & PRESSURES',
  'GEAR RATIOS',
  'SPEED / RPM',
  'STINT',
  'TRACK MAP',
  'MOTION',
  'ELEVATION',
];

// ---------------------------------------------------------------------------
// Timing: position, lap, lap list, delta (elements 1, 2, 5, 7, 12)
// ---------------------------------------------------------------------------

class _TimingHeader extends StatelessWidget {
  const _TimingHeader({required this.telemetry, this.trace});

  final TelemetryData telemetry;

  /// The driven route, which is where the live delta to the fastest lap comes
  /// from.
  final TrackTrace? trace;

  @override
  Widget build(BuildContext context) {
    final best = telemetry.bestLapTime;
    final last = telemetry.lastLapTime;
    final hasBoth = best > 0 && last > 0 && gt7LapTime(best) != '--:--.---';

    // The live delta against this session's fastest lap beats the static
    // last-minus-best number as soon as one lap has been completed: it says
    // what the car is doing *right now*, at this point on the track.
    final live = trace?.deltaToBest();
    final deltaSeconds = live ?? (hasBoth ? (last - best) / 1000.0 : null);
    final liveLabel = live != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ValueBlock(
          label: 'POSITION',
          value: gt7Count(telemetry.currentPos, telemetry.totalPositions),
        ),
        const SizedBox(width: 22),
        _ValueBlock(
          label: 'LAP',
          value: gt7Count(telemetry.currentLap, telemetry.totalLaps),
        ),
        const Spacer(),
        if (deltaSeconds != null)
          _DeltaChip(
            seconds: deltaSeconds,
            label: liveLabel ? 'LIVE' : null,
          )
        else
          Text(
            'NO REFERENCE LAP YET',
            style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.55), size: 9),
          ),
        const SizedBox(width: 26),
        _LapList(
          best: gt7LapTime(best),
          last: gt7LapTime(last),
        ),
      ],
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: gt7Caption(size: 9)),
        const SizedBox(height: 4),
        Text(value, style: gt7Digital(size: 26)),
      ],
    );
  }
}

/// The game's gap readout: blue with a minus when faster than the reference,
/// red with a plus when slower.
class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.seconds, this.label});

  final double seconds;

  /// Set to `LIVE` when the number compares the current lap with the fastest
  /// one at the same distance, rather than last lap with best lap.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isGain = seconds < 0;
    final color = isGain ? gt7Gain : gt7Warn;

    return Row(
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.7), size: 8),
          ),
          const SizedBox(width: 6),
        ],
        Icon(
          isGain ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          color: color,
          size: 20,
        ),
        Text(
          '${isGain ? '-' : '+'}${seconds.abs().toStringAsFixed(3)}',
          style: gt7Digital(size: 18, color: color),
        ),
      ],
    );
  }
}

/// Lap list, with the fastest lap row filled purple - the way the game marks
/// the fastest lap in the timing list.
class _LapList extends StatelessWidget {
  const _LapList({required this.best, required this.last});

  final String best;
  final String last;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _row('BEST', best, highlight: true),
        const SizedBox(height: 4),
        _row('LAST', last, highlight: false),
      ],
    );
  }

  Widget _row(String label, String time, {required bool highlight}) {
    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: highlight
          ? BoxDecoration(
              color: gt7Best.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(2),
            )
          : null,
      child: Row(
        children: [
          Text(
            label,
            style: gt7Caption(
              color: highlight ? Colors.white : gt7TextMuted,
              size: 9,
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: gt7Digital(
              size: 15,
              color: highlight ? Colors.white : gt7Text,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The cluster
// ---------------------------------------------------------------------------

class _Cluster extends StatelessWidget {
  const _Cluster({required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _TyreWidget(telemetry: telemetry),
        const SizedBox(width: 18),
        SizedBox(
          width: 330,
          child: _speedDial(telemetry),
        ),
        const SizedBox(width: 10),
        _CentreBlock(telemetry: telemetry),
        const SizedBox(width: 10),
        SizedBox(
          width: 330,
          child: _rpmDial(telemetry),
        ),
        const SizedBox(width: 18),
        _StatusColumn(telemetry: telemetry),
      ],
    );
  }

  Widget _speedDial(TelemetryData t) {
    // The game's speedometer: 0-320 km/h in steps of 40, fuel arc inside.
    return GaugeDial(
      value: t.speed,
      maxValue: 320,
      majorStep: 40,
      minorPerMajor: 2,
      unitCaption: 'km/h',
      height: 330,
      showValue: false,
      framed: false,
      core: _FuelCore(
        ratio: t.maxFuel > 0 ? (t.fuel / t.maxFuel).clamp(0.0, 1.0) : 0.0,
        isEv: t.isEV,
      ),
    );
  }

  Widget _rpmDial(TelemetryData t) {
    final limiter = t.rpmLimiter > 0 ? t.rpmLimiter.toDouble() : 9000.0;
    final warning = t.rpmWarning > 0 ? t.rpmWarning.toDouble() : limiter * 0.9;

    return GaugeDial(
      value: t.rpm,
      maxValue: 10000,
      majorStep: 1000,
      minorPerMajor: 2,
      labelScale: 0.001,
      unitCaption: 'x1000 rpm',
      redlineStart: warning,
      redlineEnd: limiter,
      height: 330,
      showValue: false,
      framed: false,
      core: t.boost > 0 ? _BoostCore(boost: t.boost) : null,
    );
  }
}

/// Narrow windows: the cluster stacks, the dials keep their size.
class _ClusterStacked extends StatelessWidget {
  const _ClusterStacked({required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final limiter = t.rpmLimiter > 0 ? t.rpmLimiter.toDouble() : 9000.0;
    final warning = t.rpmWarning > 0 ? t.rpmWarning.toDouble() : limiter * 0.9;

    return Column(
      children: [
        _CentreBlock(telemetry: t),
        const SizedBox(height: 18),
        SizedBox(
          height: 240,
          child: Row(
            children: [
              Expanded(
                child: GaugeDial(
                  value: t.speed,
                  maxValue: 320,
                  majorStep: 40,
                  minorPerMajor: 2,
                  unitCaption: 'km/h',
                  height: 240,
                  showValue: true,
                  valueSize: 28,
                  framed: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GaugeDial(
                  value: t.rpm,
                  maxValue: 10000,
                  majorStep: 1000,
                  minorPerMajor: 2,
                  labelScale: 0.001,
                  unitCaption: 'x1000 rpm',
                  redlineStart: warning,
                  redlineEnd: limiter,
                  height: 240,
                  showValue: true,
                  valueSize: 28,
                  framed: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _TyreWidget(telemetry: t),
        const SizedBox(height: 16),
        _StatusColumn(telemetry: t, horizontal: true),
      ],
    );
  }
}

/// Element 14: rev strip, speed, gear, transmission, with the pedal bars (19)
/// and the brake-pressure bar (16) below.
class _CentreBlock extends StatelessWidget {
  const _CentreBlock({required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final limiter = t.rpmLimiter > 0 ? t.rpmLimiter.toDouble() : 9000.0;
    final warning = t.rpmWarning > 0 ? t.rpmWarning.toDouble() : limiter * 0.9;
    final overWarning = t.rpm >= warning;

    return SizedBox(
      // Measured off the in-game cluster: the panel is ~1.4x a dial's width and
      // ~5.6x wider than it is tall, so it reads as a wide flat strip.
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The game hangs the rev strip off the top edge of the panel, on the
          // same width as the panel's wider (upper) side.
          _RevBar(rpm: t.rpm, limiter: limiter, warning: warning),
          const SizedBox(height: 3),
          CustomPaint(
            painter: _CentrePanelPainter(
              fill: Colors.black.withValues(alpha: 0.45),
              edge: Colors.white.withValues(alpha: 0.12),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 9, 48, 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(t.speed.toStringAsFixed(0), style: gt7Digital(size: 34)),
                      Text(
                        'km/h',
                        style: gt7Caption(
                          color: gt7TextMuted.withValues(alpha: 0.8),
                          size: 9,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  Text(gt7Gear(t.currentGear), style: gt7Digital(size: 46)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Text(
                      t.isEV ? 'EV' : 'MT',
                      style: gt7Caption(size: 10, letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PedalBar(label: 'THR', value: t.throttle, color: gt7Text),
              const SizedBox(width: 10),
              _PedalBar(label: 'BRK', value: t.brake, color: gt7Text, cap: gt7Warn),
              const SizedBox(width: 14),
              _PressureBar(value: t.brake),
              const SizedBox(width: 14),
              _Blink(
                active: overWarning,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: overWarning ? gt7Warn : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: overWarning
                          ? gt7Warn
                          : Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard_double_arrow_up,
                    size: 18,
                    color: overWarning ? Colors.black : gt7TextMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The game's centre panel is a **hexagon**, not a trapezoid: the top edge is
/// the widest, the sides run almost vertically down the upper part, and only
/// the lower part tapers in towards a narrower bottom edge. Every corner is
/// rounded, including where the vertical sides kink into the taper.
///
/// Measured off the 1920x800 in-game screenshot: top edge 543 px, vertical
/// section 55 % of the height, taper the rest, ~10 % inset per side.
class _CentrePanelPainter extends CustomPainter {
  _CentrePanelPainter({
    required this.fill,
    required this.edge,
    this.bottomInset = 26,
    this.verticalFraction = 0.55,
    this.cornerRadius = 9,
  });

  final Color fill;
  final Color edge;

  /// How far each side pulls in at the bottom edge, in layout pixels.
  final double bottomInset;

  /// Share of the height that keeps the near-vertical sides.
  final double verticalFraction;

  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final kinkY = size.height * verticalFraction;

    final path = _roundedPolygon(
      [
        Offset.zero, // top-left
        Offset(size.width, 0), // top-right
        Offset(size.width, kinkY), // right kink
        Offset(size.width - bottomInset, size.height), // bottom-right
        Offset(bottomInset, size.height), // bottom-left
        Offset(0, kinkY), // left kink
      ],
      cornerRadius,
    );

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// Rounds every vertex of a polygon, so the straight runs meet with an arc
  /// instead of a sharp corner.
  static Path _roundedPolygon(List<Offset> points, double radius) {
    final path = Path();
    final count = points.length;

    for (var i = 0; i < count; i++) {
      final previous = points[(i - 1 + count) % count];
      final current = points[i];
      final next = points[(i + 1) % count];

      final toPrevious = previous - current;
      final toNext = next - current;
      final shortest = math.min(toPrevious.distance, toNext.distance);
      final r = math.min(radius, shortest / 2);

      final entry = current + toPrevious / toPrevious.distance * r;
      final exit = current + toNext / toNext.distance * r;

      if (i == 0) {
        path.moveTo(entry.dx, entry.dy);
      } else {
        path.lineTo(entry.dx, entry.dy);
      }
      path.arcToPoint(exit, radius: Radius.circular(r));
    }

    return path..close();
  }

  @override
  bool shouldRepaint(_CentrePanelPainter old) =>
      old.fill != fill ||
      old.edge != edge ||
      old.bottomInset != bottomInset ||
      old.verticalFraction != verticalFraction ||
      old.cornerRadius != cornerRadius;
}


/// Shift strip: segments light up with revs, the last ones in the game's
/// pink-red, and the whole strip is static so it stays readable at speed.
class _RevBar extends StatelessWidget {
  const _RevBar({
    required this.rpm,
    required this.limiter,
    required this.warning,
  });

  final double rpm;
  final double limiter;
  final double warning;

  static const int _segments = 26;
  static const Color _hot = Color(0xFFDB557A);

  @override
  Widget build(BuildContext context) {
    final ratio = (rpm / limiter).clamp(0.0, 1.0);
    final warningRatio = (warning / limiter).clamp(0.0, 1.0);

    return SizedBox(
      width: double.infinity,
      height: 12,
      child: Row(
        children: List.generate(_segments, (i) {
          final position = (i + 1) / _segments;
          final lit = position <= ratio;
          final hot = position > warningRatio;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: lit
                    ? (hot ? _hot : gt7Text.withValues(alpha: 0.85))
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PedalBar extends StatelessWidget {
  const _PedalBar({
    required this.label,
    required this.value,
    required this.color,
    this.cap,
  });

  final String label;
  final double value;
  final Color color;

  /// The game frames the brake bar differently from the throttle bar (the red
  /// is reserved for the ABS-reduced share, which the UDP feed does not
  /// report), so colour the frame, not the fill.
  final Color? cap;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / 100).clamp(0.0, 1.0);

    return Column(
      children: [
        // Thin white bracket, the way the game wraps each pedal bar.
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border.all(
              color: cap?.withValues(alpha: 0.35) ??
                  Colors.white.withValues(alpha: 0.28),
            ),
            borderRadius: BorderRadius.circular(1),
          ),
          child: Container(
            width: 9,
            height: 50,
            color: Colors.black.withValues(alpha: 0.35),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio,
                child: Container(color: color),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: gt7Caption(size: 8)),
      ],
    );
  }
}

/// Element 16: the brake-pressure bar, drawn with the game's 0 / 50 / 100
/// scale ticks beside it.
class _PressureBar extends StatelessWidget {
  const _PressureBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 58,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 7,
                height: 58,
                color: Colors.black.withValues(alpha: 0.35),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: (value / 100).clamp(0.0, 1.0),
                    child: Container(color: gt7Text),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              CustomPaint(
                size: const Size(10, 58),
                painter: _TickScalePainter(color: Colors.white.withValues(alpha: 0.35)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text('BRK %', style: gt7Caption(size: 8)),
      ],
    );
  }
}

class _TickScalePainter extends CustomPainter {
  _TickScalePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      final long = i == 0 || i == 4;
      canvas.drawLine(
        Offset(long ? 0 : 4, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickScalePainter old) => old.color != color;
}

/// Element 15: the fuel arc that lives inside the speedometer.
class _FuelCore extends StatelessWidget {
  const _FuelCore({required this.ratio, required this.isEv});

  final double ratio;
  final bool isEv;

  @override
  Widget build(BuildContext context) {
    final low = !isEv && ratio <= 0.2;
    final color = low ? gt7Warn : gt7Text;

    return Column(
      children: [
        SizedBox(
          width: 112,
          height: 42,
          child: CustomPaint(
            painter: _FuelArcPainter(
              ratio: ratio,
              color: color,
              track: Colors.white.withValues(alpha: 0.14),
            ),
          ),
        ),
        const SizedBox(height: 1),
        SizedBox(
          width: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('E', style: gt7Caption(size: 9, color: gt7Text)),
              _PumpGlyph(color: color),
              Text('F', style: gt7Caption(size: 9, color: gt7Text)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isEv ? 'CHARGE' : '${(ratio * 100).toStringAsFixed(0)}%',
          style: gt7Caption(color: low ? gt7Warn : gt7TextMuted, size: 8),
        ),
      ],
    );
  }
}

/// The fuel-pump pictogram the game prints inside the fuel gauge.
class _PumpGlyph extends StatelessWidget {
  const _PumpGlyph({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(17, 17),
      painter: _PumpPainter(color: color),
    );
  }
}

class _PumpPainter extends CustomPainter {
  _PumpPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.46, h * 0.68),
        const Radius.circular(1.5),
      ),
      paint,
    );
    // Window on the body.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.26, h * 0.30, w * 0.30, h * 0.18),
      paint,
    );
    // Nozzle and hose.
    canvas.drawLine(
      Offset(w * 0.64, h * 0.38),
      Offset(w * 0.80, h * 0.38),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.80, h * 0.38),
      Offset(w * 0.80, h * 0.66),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.80, h * 0.66),
      Offset(w * 0.68, h * 0.72),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PumpPainter old) => old.color != color;
}

/// Low-beam pictogram, printed inside the tachometer in the game.
class _HeadlightGlyph extends StatelessWidget {
  const _HeadlightGlyph({this.size = 15});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HeadlightPainter(color: gt7Text.withValues(alpha: 0.85)),
    );
  }
}

class _HeadlightPainter extends CustomPainter {
  _HeadlightPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // The lamp: a half-disc facing right.
    canvas.drawArc(
      Rect.fromLTWH(w * 0.10, h * 0.22, w * 0.52, h * 0.56),
      -math.pi / 2,
      math.pi,
      false,
      paint,
    );
    // The beam: three rays sloping down to the right.
    for (var i = 0; i < 3; i++) {
      final y = h * (0.32 + i * 0.18);
      canvas.drawLine(
        Offset(w * 0.68, y),
        Offset(w * 0.95, y + h * 0.12),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeadlightPainter old) => old.color != color;
}

class _FuelArcPainter extends CustomPainter {
  _FuelArcPainter({
    required this.ratio,
    required this.color,
    required this.track,
  });

  final double ratio;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, (size.height - 4) * 2);
    const start = math.pi;
    const sweep = math.pi;

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawArc(
      rect,
      start,
      sweep * ratio.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FuelArcPainter old) =>
      old.ratio != ratio || old.color != color;
}

/// The boost gauge the game draws inside the tachometer on turbo cars.
class _BoostCore extends StatelessWidget {
  const _BoostCore({required this.boost});

  final double boost;

  @override
  Widget build(BuildContext context) {
    // GT7 scales it in x100 kPa, roughly -1 .. +2 bar of boost.
    final value = (boost).clamp(0.0, 2.0);

    return Column(
      children: [
        SizedBox(
          width: 74,
          height: 40,
          child: CustomPaint(
            painter: _BoostPainter(
              value: value,
              max: 2,
              color: gt7SlotA,
              track: Colors.white.withValues(alpha: 0.14),
            ),
          ),
        ),
        Text(
          'BOOST ${value.toStringAsFixed(1)}',
          style: gt7Caption(color: gt7TextMuted, size: 8),
        ),
      ],
    );
  }
}

class _BoostPainter extends CustomPainter {
  _BoostPainter({
    required this.value,
    required this.max,
    required this.color,
    required this.track,
  });

  final double value;
  final double max;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, (size.height - 4) * 2);
    const start = math.pi;
    const sweep = math.pi;
    final center = Offset(size.width / 2, size.height - 2);
    final ratio = (value / max).clamp(0.0, 1.0);

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawArc(
      rect,
      start,
      sweep * ratio,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    final angle = start + sweep * ratio;
    final direction = Offset(math.cos(angle), math.sin(angle));
    canvas.drawLine(
      center,
      center + direction * (size.width / 2 - 4),
      Paint()
        ..color = gt7Text
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BoostPainter old) =>
      old.value != value || old.color != color;
}

/// Element 20: the four tyres. The game reddens the frame as they heat up;
/// we do not have wear or compound, so heat is what the colour carries.
class _TyreWidget extends StatelessWidget {
  const _TyreWidget({required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    // Laid out the way the game draws it: a car seen from above with the four
    // tyres around it, each tyre framed in its own heat colour.
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: SizedBox(
        width: 152,
        height: 150,
        child: Stack(
          children: [
            const Center(child: _CarBody()),
            Align(
              alignment: Alignment.topLeft,
              child: _TyreBlock(label: 'FL', temperature: telemetry.tireTempFL),
            ),
            Align(
              alignment: Alignment.topRight,
              child: _TyreBlock(label: 'FR', temperature: telemetry.tireTempFR),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: _TyreBlock(label: 'RL', temperature: telemetry.tireTempRL),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: _TyreBlock(label: 'RR', temperature: telemetry.tireTempRR),
            ),
          ],
        ),
      ),
    );
  }
}

/// The car silhouette the tyres are arranged around.
class _CarBody extends StatelessWidget {
  const _CarBody();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 86),
      painter: _CarBodyPainter(),
    );
  }
}

class _CarBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(body, Paint()..color = Colors.white.withValues(alpha: 0.16));
    canvas.drawRRect(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final glass = Paint()..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.16, size.height * 0.17, size.width * 0.68, size.height * 0.15),
        const Radius.circular(4),
      ),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.16, size.height * 0.68, size.width * 0.68, size.height * 0.15),
        const Radius.circular(4),
      ),
      glass,
    );
  }

  @override
  bool shouldRepaint(_CarBodyPainter old) => false;
}

class _TyreBlock extends StatelessWidget {
  const _TyreBlock({required this.label, required this.temperature});

  final String label;
  final double temperature;

  Color get _color {
    if (temperature < 60) return gt7Gain;
    if (temperature < 100) return gt7Text;
    if (temperature < 120) return gt7SlotB;
    return gt7Warn;
  }

  @override
  Widget build(BuildContext context) {
    // Heat fills the tyre frame, the way the game reddens it as the tyre works.
    final fill = ((temperature - 20) / 130).clamp(0.08, 1.0);

    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _color.withValues(alpha: 0.75)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: gt7Caption(size: 7, color: _color)),
          const SizedBox(height: 2),
          Text(
            temperature.toStringAsFixed(0),
            style: gt7Digital(size: 13, color: _color),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: Stack(
                children: [
                  Container(height: 3, color: Colors.white.withValues(alpha: 0.10)),
                  FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(height: 3, color: _color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small pictogram row the game keeps under the cluster: driving-assist
/// lamps. GT7's UDP feed does not report their state, so they are drawn in the
/// game's "off" grey and the row says so.
class _AssistRow extends StatelessWidget {
  const _AssistRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: Wrap(
      spacing: 5,
      runSpacing: 5,
      alignment: WrapAlignment.end,
      children: const [
        _GlyphChip(label: 'ABS'),
        _TextGlyph('TCS'),
        _TextGlyph('ASM'),
        _TextGlyph('(P)'),
        _WarningTriangle(),
        _HeadlightGlyph(size: 12),
      ],
      ),
    );
  }
}

class _GlyphChip extends StatelessWidget {
  const _GlyphChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: _TextGlyph(label),
    );
  }
}

class _TextGlyph extends StatelessWidget {
  const _TextGlyph(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: gt7Caption(
          color: gt7Text,
          size: 7.5,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _WarningTriangle extends StatelessWidget {
  const _WarningTriangle();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 15),
      painter: _WarningPainter(color: gt7Text.withValues(alpha: 0.85)),
    );
  }
}

class _WarningPainter extends CustomPainter {
  _WarningPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 1)
      ..lineTo(size.width - 1, size.height - 1)
      ..lineTo(1, size.height - 1)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.42),
      Offset(size.width / 2, size.height * 0.66),
      Paint()
        ..color = color
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.78),
      0.8,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_WarningPainter old) => old.color != color;
}

/// The small status column the game keeps at the edges of the cluster:
/// temperatures and pressures here, since we have no assist lamps.
class _StatusColumn extends StatelessWidget {
  const _StatusColumn({required this.telemetry, this.horizontal = false});

  final TelemetryData telemetry;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final entries = <Widget>[
      _mini('OIL', '${telemetry.oilTemp.toStringAsFixed(0)}°'),
      _mini('WATER', '${telemetry.waterTemp.toStringAsFixed(0)}°'),
      _mini('BRAKE', '${telemetry.brake.toStringAsFixed(0)}%'),
      if (telemetry.oilPressure > 0)
        _mini('PRESS', '${telemetry.oilPressure.toStringAsFixed(1)}'),
      const _AssistRow(),
    ];

    if (horizontal) {
      return Wrap(spacing: 14, runSpacing: 10, children: entries);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in entries) ...[
          entry,
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _mini(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: gt7Caption(size: 8)),
        const SizedBox(width: 6),
        Text(value, style: gt7Digital(size: 12)),
      ],
    );
  }
}

/// Tyre heat colour, the game's cold-blue / optimal-white / warm-yellow /
/// hot-red progression.
Color gt7HeatColor(double temperature) {
  if (temperature < 60) return gt7Gain;
  if (temperature < 100) return gt7Text;
  if (temperature < 120) return gt7SlotB;
  return gt7Warn;
}

/// Fades its child in and out while [active] - used for the shift lamp, which
/// in the game blinks as the limiter approaches.
class _Blink extends StatefulWidget {
  const _Blink({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  // Built eagerly in initState: a lazily built controller would be constructed
  // during dispose() on a deactivated element, which asserts.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Blink old) {
    super.didUpdateWidget(old);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// MFD: the panel the game keeps under the cluster, cycled with left/right
// ---------------------------------------------------------------------------

class _MfdPanel extends StatelessWidget {
  const _MfdPanel({
    required this.telemetry,
    required this.page,
    this.trace,
    this.onPage,
  });

  final TelemetryData telemetry;
  final TrackTrace? trace;
  final int page;
  final ValueChanged<int>? onPage;

  @override
  Widget build(BuildContext context) {
    final index = page % mfdTitles.length;

    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _MfdArrow(
                icon: Icons.chevron_left,
                onTap: onPage == null
                    ? null
                    : () => onPage!(
                          (index - 1 + mfdTitles.length) % mfdTitles.length,
                        ),
              ),
              const SizedBox(width: 10),
              Text(
                mfdTitles[index],
                style: gt7Caption(
                  color: gt7Text,
                  size: 11,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              _MfdArrow(
                icon: Icons.chevron_right,
                onTap: onPage == null
                    ? null
                    : () => onPage!((index + 1) % mfdTitles.length),
              ),
              const Spacer(),
              for (var i = 0; i < mfdTitles.length; i++)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == index
                        ? gt7Text
                        : Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                '← →',
                style: gt7Caption(
                  color: gt7TextMuted.withValues(alpha: 0.5),
                  size: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 152,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: _body(index),
          ),
        ],
      ),
    );
  }

  Widget _body(int index) => switch (index) {
        0 => _sessionBest(),
        1 => const ThrottleBrakeGraph(height: 130, bare: true),
        2 => _tyres(),
        3 => _temps(),
        4 => _gears(),
        5 => const _SpeedRpmPage(),
        6 => _StintPage(trace: trace, telemetry: telemetry),
        7 => _TrackMapPage(trace: trace),
        8 => MotionPanel(
          telemetry: telemetry,
          trace: trace,
          bare: true,
        ),
        _ => _ElevationPage(trace: trace),
      };

  Widget _sessionBest() {
    final best = gt7LapTime(telemetry.bestLapTime);
    final last = gt7LapTime(telemetry.lastLapTime);
    final hasBoth = best != '--:--.---' && last != '--:--.---';
    final delta = hasBoth
        ? (telemetry.lastLapTime - telemetry.bestLapTime) / 1000.0
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _mfdRow('LAST', last, delta: delta),
        const SizedBox(height: 8),
        _mfdRow('BEST', best, highlight: true),
        const SizedBox(height: 10),
        Text(
          hasBoth
              ? 'THEORETICAL BEST NEEDS SECTOR TIMES, WHICH GT7 DOES NOT SEND'
              : 'WAITING FOR A COMPLETED LAP',
          style: gt7Caption(
            color: gt7TextMuted.withValues(alpha: 0.55),
            size: 8,
          ),
        ),
      ],
    );
  }

  Widget _mfdRow(
    String label,
    String time, {
    double? delta,
    bool highlight = false,
  }) {
    final isGain = delta != null && delta < 0;
    final color = isGain ? gt7Gain : gt7Warn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF16301F) : Colors.transparent,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: gt7Caption(
                color: highlight ? gt7Text : gt7TextMuted,
                size: 10,
                letterSpacing: 1.6,
              ),
            ),
          ),
          Text(time, style: gt7Digital(size: 20)),
          const Spacer(),
          if (delta != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                '${isGain ? '-' : '+'}${delta.abs().toStringAsFixed(3)}',
                style: gt7Digital(size: 13, color: color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tyres() {
    final tyres = <(String, double)>[
      ('FL', telemetry.tireTempFL),
      ('FR', telemetry.tireTempFR),
      ('RL', telemetry.tireTempRL),
      ('RR', telemetry.tireTempRR),
    ];

    return Row(
      children: [
        for (final (label, temperature) in tyres) ...[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: gt7Caption(size: 10)),
                const SizedBox(height: 6),
                Text(
                  temperature.toStringAsFixed(0),
                  style: gt7Digital(size: 22, color: gt7HeatColor(temperature)),
                ),
                const SizedBox(height: 2),
                Text(
                  '°C',
                  style: gt7Caption(
                    color: gt7TextMuted.withValues(alpha: 0.7),
                    size: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: Stack(
                      children: [
                        Container(
                          height: 4,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        FractionallySizedBox(
                          widthFactor: ((temperature - 20) / 130).clamp(0.05, 1.0),
                          child: Container(
                            height: 4,
                            color: gt7HeatColor(temperature),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _temps() {
    final rows = <(String, String)>[
      ('OIL', '${telemetry.oilTemp.toStringAsFixed(1)} °C'),
      ('WATER', '${telemetry.waterTemp.toStringAsFixed(1)} °C'),
      ('OIL PRESS', telemetry.oilPressure.toStringAsFixed(2)),
      ('RIDE HEIGHT', '${telemetry.rideHeight.toStringAsFixed(0)} mm'),
      ('BOOST', telemetry.boost.toStringAsFixed(2)),
      ('BRAKE', '${telemetry.brake.toStringAsFixed(0)} %'),
    ];

    return Wrap(
      spacing: 26,
      runSpacing: 12,
      children: [
        for (final (label, value) in rows)
          SizedBox(
            width: 132,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: gt7Caption(size: 9),
                  ),
                ),
                const SizedBox(width: 6),
                Text(value, style: gt7Digital(size: 14)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _gears() {
    final ratios = <double>[
      telemetry.gear1,
      telemetry.gear2,
      telemetry.gear3,
      telemetry.gear4,
      telemetry.gear5,
      telemetry.gear6,
      telemetry.gear7,
      telemetry.gear8,
    ];
    final usable = ratios.where((r) => r > 0).toList();

    if (usable.isEmpty) {
      return Center(
        child: Text(
          'GEAR RATIOS NOT IN THIS PACKET',
          style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.7), size: 10),
        ),
      );
    }

    final maxRatio = usable.reduce(math.max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < usable.length; i++) ...[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  usable[i].toStringAsFixed(2),
                  style: gt7Digital(size: 10, color: gt7TextMuted),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 78 * (usable[i] / maxRatio),
                  decoration: BoxDecoration(
                    color: i + 1 == telemetry.currentGear
                        ? gt7SlotB
                        : gt7Text.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 5),
                Text('${i + 1}', style: gt7Caption(size: 9)),
              ],
            ),
          ),
          const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _MfdArrow extends StatelessWidget {
  const _MfdArrow({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        width: 22,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, size: 15, color: gt7Text),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MFD pages that need their own history: the speed/rev cloud and the stint
// ---------------------------------------------------------------------------

/// The game's Data Logger draws speed against revs as a cloud - the shape is
/// the gear-ratio ladder of the car. Same idea here, coloured by gear.
class _SpeedRpmPage extends StatefulWidget {
  const _SpeedRpmPage();

  @override
  State<_SpeedRpmPage> createState() => _SpeedRpmPageState();
}

class _SpeedRpmPageState extends State<_SpeedRpmPage> {
  static const int _maxPoints = 900;

  final List<(double, double, int)> _points = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => _sample(),
    );
  }

  void _sample() {
    final telemetry = context.read<TelemetryService>().telemetry;
    if (telemetry == null || !mounted) return;

    setState(() {
      _points.add((
        telemetry.speed.clamp(0, 600).toDouble(),
        telemetry.rpm.clamp(0, 12000).toDouble(),
        telemetry.currentGear,
      ));
      if (_points.length > _maxPoints) _points.removeAt(0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Each gear gets its own colour, so the ladder reads as gears rather than
  /// as one blob.
  static const List<Color> _gearColors = [
    gt7SlotA,
    gt7SlotB,
    gt7Best,
    gt7Gain,
    Color(0xFF5FD08A),
    Color(0xFFE08A5F),
    gt7Warn,
    Color(0xFFB0B7C3),
  ];

  @override
  Widget build(BuildContext context) {
    if (_points.isEmpty) {
      return Center(
        child: Text(
          'COLLECTING…',
          style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.7), size: 10),
        ),
      );
    }

    final maxSpeed = _points
        .map((p) => p.$1)
        .reduce(math.max)
        .clamp(120.0, 600.0);
    final maxRpm = _points
        .map((p) => p.$2)
        .reduce(math.max)
        .clamp(4000.0, 12000.0);

    return Row(
      // stretch, otherwise the childless CustomPaint gets zero height
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomPaint(
            // explicit size: a childless CustomPaint otherwise collapses to
            // zero when its constraints are loose
            size: const Size(double.infinity, double.infinity),
            painter: _SpeedRpmPainter(
              points: _points,
              maxSpeed: maxSpeed,
              maxRpm: maxRpm,
              colors: _gearColors,
              grid: Colors.white.withValues(alpha: 0.10),
              label: gt7TextMuted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('SPEED →', style: gt7Caption(size: 7)),
            const SizedBox(height: 4),
            Text(
              '${maxSpeed.toStringAsFixed(0)} km/h',
              style: gt7Digital(size: 12),
            ),
            const SizedBox(height: 10),
            Text('RPM ↑', style: gt7Caption(size: 7)),
            const SizedBox(height: 4),
            Text('${maxRpm.toStringAsFixed(0)}', style: gt7Digital(size: 12)),
          ],
        ),
      ],
    );
  }
}

class _SpeedRpmPainter extends CustomPainter {
  _SpeedRpmPainter({
    required this.points,
    required this.maxSpeed,
    required this.maxRpm,
    required this.colors,
    required this.grid,
    required this.label,
  });

  final List<(double, double, int)> points;
  final double maxSpeed;
  final double maxRpm;
  final List<Color> colors;
  final Color grid;
  final Color label;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0;
    final rect = Rect.fromLTRB(left, 6, size.width - 4, size.height - 16);
    if (rect.width <= 8 || rect.height <= 8) return;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = rect.bottom - rect.height * (i / 4);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
      _text(canvas, (maxRpm * i / 4).toStringAsFixed(0), Offset(rect.left - 6, y),
          right: true);
    }
    for (var i = 0; i <= 4; i++) {
      final x = rect.left + rect.width * (i / 4);
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
      _text(canvas, (maxSpeed * i / 4).toStringAsFixed(0),
          Offset(x, rect.bottom + 3), center: true);
    }

    canvas.save();
    canvas.clipRect(rect);
    final paint = Paint()..strokeWidth = 1.6..strokeCap = StrokeCap.round;
    for (final (speed, rpm, gear) in points) {
      paint.color = colors[gear.abs() % colors.length].withValues(alpha: 0.55);
      final x = rect.left + rect.width * (speed / maxSpeed).clamp(0.0, 1.0);
      final y = rect.bottom - rect.height * (rpm / maxRpm).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(x, y), 1.2, paint);
    }
    canvas.restore();
  }

  void _text(
    Canvas canvas,
    String value,
    Offset anchor, {
    bool right = false,
    bool center = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: label,
          fontSize: 8,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = switch ((right, center)) {
      (true, _) => Offset(anchor.dx - painter.width, anchor.dy - painter.height / 2),
      (_, true) => Offset(anchor.dx - painter.width / 2, anchor.dy),
      _ => anchor,
    };
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_SpeedRpmPainter old) => old.points.length != points.length;
}

/// Fuel per lap and how far the tank still goes - the game shows this on its
/// fuel-map page; here it is measured from the car's own consumption.
class _StintPage extends StatelessWidget {
  const _StintPage({this.trace, this.telemetry});

  final TrackTrace? trace;
  final TelemetryData? telemetry;

  @override
  Widget build(BuildContext context) {
    final telemetry = this.telemetry;
    if (telemetry == null) {
      return Center(child: Text('NO DATA', style: gt7Caption(size: 10)));
    }

    // Fuel per lap is arithmetic on a real packet field, so it is the one
    // "strategy" number we can honestly show. The lap bookkeeping lives in the
    // trace, which every view shares.
    final perLap = trace?.fuelPerLap;
    final lapsLeft = trace?.lapsRemaining;
    final ratio = telemetry.maxFuel > 0
        ? (telemetry.fuel / telemetry.maxFuel).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stintRow(
                'FUEL',
                telemetry.isEV
                    ? 'ELECTRIC'
                    : '${telemetry.fuel.toStringAsFixed(1)} / '
                          '${telemetry.maxFuel.toStringAsFixed(0)} L',
              ),
              const SizedBox(height: 8),
              _stintRow(
                'PER LAP',
                perLap == null ? '—' : '${perLap.toStringAsFixed(2)} L',
              ),
              const SizedBox(height: 8),
              _stintRow(
                'REMAINING',
                lapsLeft == null ? '—' : '${lapsLeft.floor()} LAPS',
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TANK', style: gt7Caption(size: 9)),
              const SizedBox(height: 6),
              Text(
                '${(ratio * 100).round()}%',
                style: gt7Digital(
                  size: 20,
                  color: ratio <= 0.2 ? gt7Warn : gt7Text,
                ),
              ),
              const SizedBox(height: 6),
              if (trace?.lastLapFuel != null)
                Text(
                  'LAST ${trace!.lastLapFuel!.toStringAsFixed(2)} L',
                  style: gt7Caption(color: gt7TextMuted, size: 8),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stintRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(label, style: gt7Caption(color: gt7TextMuted, size: 9)),
        ),
        Flexible(child: Text(value, style: gt7Digital(size: 15))),
      ],
    );
  }
}

/// The MFD page that draws where the car has been: the route comes straight out
/// of the packet's coordinates, so it is the navigation view of the session.
class _TrackMapPage extends StatelessWidget {
  const _TrackMapPage({this.trace});

  final TrackTrace? trace;

  @override
  Widget build(BuildContext context) {
    final trace = this.trace;

    if (trace == null || !trace.hasRoute) {
      return Center(
        child: Text(
          'NO ROUTE YET — GT7 SENDS THE CAR\'S POSITION IN EVERY PACKET, '
          'SO THE MAP APPEARS AS SOON AS YOU MOVE',
          textAlign: TextAlign.center,
          style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.6), size: 8),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TrackMap(trace: trace, padding: 6, tilt: 0),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 132,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _mapStat('ROUTE', gt7Distance(trace.distance)),
              const SizedBox(height: 6),
              _mapStat('POINTS', '${trace.length}'),
              const SizedBox(height: 6),
              _mapStat('ELEV', '${trace.elevationRange.round()} m'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: gt7Caption(size: 8)),
        const SizedBox(height: 2),
        Text(value, style: gt7Digital(size: 13)),
      ],
    );
  }
}

/// The MFD page that shows the shape of the lap in profile.
class _ElevationPage extends StatelessWidget {
  const _ElevationPage({this.trace});

  final TrackTrace? trace;

  @override
  Widget build(BuildContext context) {
    final trace = this.trace;
    if (trace == null || !trace.hasRoute) {
      return Center(
        child: Text(
          'THE PROFILE COMES FROM THE CAR\'S HEIGHT IN EVERY PACKET — '
          'IT APPEARS AS SOON AS YOU MOVE',
          textAlign: TextAlign.center,
          style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.6), size: 8),
        ),
      );
    }

    return ElevationProfile(
      trace: trace,
      height: 120,
      label: 'ELEVATION',
      panel: false,
    );
  }
}
