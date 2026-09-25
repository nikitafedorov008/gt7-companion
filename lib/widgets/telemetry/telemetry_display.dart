import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/telemetry/telemetry_data.dart';
import '../../models/telemetry/track_trace.dart';
import '../../theme/gt7_theme.dart';
import '../../repositories/track_catalog.dart';
import '../../services/telemetry_service.dart';
import '../../utils/dev_flags.dart';
import 'throttle_brake_graph.dart';
import 'elevation_profile.dart';
import 'g_force_ball.dart';
import 'motion_side_cards.dart';
import 'motion_workspace.dart';
import 'motion_panel.dart';
import 'track_map.dart';

/// Telemetry dashboard, styled after the in-game Gran Turismo 7 instruments.
///
/// Reference: docs/reference/gt7-ui-spec.md (measured off the game's own
/// screenshots). The rules it follows:
///  * near-black translucent panels, 1 px hairlines, 6-10 px radii, no shadows;
///  * a thin scale arc with ticks and numbers, a **needle**, and the redline
///    drawn as one red band **on the scale** - never a traffic-light ramp;
///  * monochrome chrome, colour spent only on data meaning
///    (purple = best, blue = gain, red = loss/warning, cyan/yellow = A/B);
///  * uppercase micro-captions with wide letter spacing, tabular numerals.
class TelemetryDisplay extends StatelessWidget {
  final TelemetryData? telemetry;
  final String? errorMessage;

  /// The route driven so far, drawn as a map at the top of the page. Optional
  /// so the display still works without a session behind it.
  final TrackTrace? trace;

  const TelemetryDisplay({
    super.key,
    this.telemetry,
    this.errorMessage,
    this.trace,
  });

  static const double _desktopBreakpoint = 760;

  @override
  Widget build(BuildContext context) {
    final data = telemetry;
    if (data == null) {
      return _StatusMessage(errorMessage: errorMessage);
    }

    final isDesktop = MediaQuery.sizeOf(context).width > _desktopBreakpoint;
    final hasRoute = trace != null && trace!.hasRoute;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MotionWorkspace(
                telemetry: data,
                trace: trace,
                // A height budget for the top row: the map's drawing box and the
                // dial are the only two things on the page that can grow without
                // limit, and left alone they push everything else out of the
                // frame. The dial is sized to the point where its wheelbase
                // dimension still fits inside the circle - it is the smallest
                // dial that shows everything the dial can show.
                dialSize: 360,
                // On a wide page the map stands beside the motion block: the
                // route and the car on one screen is the whole point of the
                // layout. Narrower than that it goes above, as it always did.
                // Everything else - the dials, the elevation, the session and
                // the pedals - stays below, full width.
                leading: hasRoute
                    // Sized so the map's panel and the motion block come out the
                    // same height in the row: the block is the dial's 360 px plus
                    // its heading and padding, and a panel is its drawing box plus
                    // about 145 px of header and footer. The footer wraps by a line
                    // depending on the numbers in it, which moves the panel by a
                    // dozen pixels either way and is not worth plumbing a fixed
                    // height through both panels for.
                    ? _TrackMapPanel(
                        trace: trace!,
                        mapHeight: 320,
                        overlay: _SessionOverlay(telemetry: data),
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              // Speed and revs come straight after the route and the load: they
              // are what a driver reads while driving, so they sit above the
              // session's numbers rather than below them.
              _buildDials(data, isDesktop),
              const SizedBox(height: 14),
              // The session's numbers and the car's state: read at a glance
              // between corners, not while driving.
              MotionSideCards(telemetry: data, trace: trace),
              const SizedBox(height: 14),
              if (hasRoute) ...[
                ElevationProfile(trace: trace!),
                const SizedBox(height: 14),
              ],
              _SessionBestPanel(telemetry: data, trace: trace),
              const SizedBox(height: 14),
              const ThrottleBrakeGraph(height: 230),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDials(TelemetryData data, bool isDesktop) {
    final speed = GaugeDial(
      value: data.speed,
      maxValue: 540,
      majorStep: 90,
      minorPerMajor: 5,
      unitCaption: 'km/h',
    );

    // The game marks the redline on the scale itself and takes its extent from
    // the car. GT7 sends the warning/limiter thresholds, so use them, with
    // sane fallbacks when the car does not report them.
    final limiter = data.rpmLimiter > 0 ? data.rpmLimiter.toDouble() : 9000.0;
    final warning = data.rpmWarning > 0
        ? data.rpmWarning.toDouble()
        : limiter * 0.9;

    final rpm = GaugeDial(
      value: data.rpm,
      maxValue: 9000,
      majorStep: 1000,
      minorPerMajor: 2,
      labelScale: 0.001,
      unitCaption: 'x1000 rpm',
      redlineStart: warning,
      redlineEnd: limiter,
    );

    if (isDesktop) {
      // No `stretch` here: this Row sits in a scrolling column, so tight
      // cross-axis constraints would be infinite. The dials carry their own
      // fixed height instead.
      return Row(
        children: [
          Expanded(child: speed),
          const SizedBox(width: 12),
          Expanded(child: rpm),
        ],
      );
    }

    // Deliberately not `Expanded`: a vertical flex child inside a scrolling
    // column has unbounded main-axis constraints and asserts in debug.
    return Column(
      children: [
        speed,
        const SizedBox(height: 12),
        rpm,
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final isError = errorMessage != null;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
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
      ),
    );
  }
}

/// The instrument: thin scale arc, ticks with numbers, one red redline band,
/// a needle, and the value inside the face - the way the game draws a dial.
class GaugeDial extends StatelessWidget {
  const GaugeDial({
    super.key,
    required this.value,
    required this.maxValue,
    required this.majorStep,
    required this.unitCaption,
    this.minorPerMajor = 5,
    this.labelScale = 1.0,
    this.redlineStart,
    this.redlineEnd,
    this.caption,
    this.height = 236,
    this.showValue = true,
    this.framed = true,
    this.core,
    this.valueSize = 36,
  });

  final double value;
  final double maxValue;
  final double majorStep;
  final String unitCaption;
  final int minorPerMajor;
  final double labelScale;
  final double? redlineStart;
  final double? redlineEnd;
  final String? caption;
  final double height;

  /// The in-game cluster prints its numbers in the centre block instead of
  /// inside the dial, so the HUD turns this off and keeps only the scale.
  final bool showValue;

  /// The game's dials float over the scene with no panel behind them.
  final bool framed;

  /// Sub-gauge drawn inside the face (fuel arc, boost gauge), like the game.
  final Widget? core;

  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: framed ? gt7PanelDecoration() : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, maxValue).toDouble()),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) {
          return CustomPaint(
            painter: _DialPainter(
              value: animated,
              maxValue: maxValue,
              majorStep: majorStep,
              minorPerMajor: minorPerMajor,
              labelScale: labelScale,
              redlineStart: redlineStart,
              redlineEnd: redlineEnd,
              scaleColor: gt7TextMuted.withValues(alpha: 0.40),
              tickColor: gt7Text.withValues(alpha: 0.72),
              labelColor: gt7TextMuted,
              needleColor: gt7Text,
              redlineColor: gt7Warn,
              hubColor: gt7TextMuted,
            ),
            child: Align(
              alignment: const Alignment(0, 0.60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (core != null) core!,
                  if (showValue) ...[
                    Text(
                      animated.toStringAsFixed(0),
                      style: gt7Digital(size: valueSize),
                    ),
                    const SizedBox(height: 5),
                  ],
                  Text(
                    unitCaption.toUpperCase(),
                    style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.9)),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      caption!,
                      style: gt7Caption(
                        color: gt7TextMuted.withValues(alpha: 0.6),
                        size: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.value,
    required this.maxValue,
    required this.majorStep,
    required this.minorPerMajor,
    required this.labelScale,
    required this.redlineStart,
    required this.redlineEnd,
    required this.scaleColor,
    required this.tickColor,
    required this.labelColor,
    required this.needleColor,
    required this.redlineColor,
    required this.hubColor,
  });

  final double value;
  final double maxValue;
  final double majorStep;
  final int minorPerMajor;
  final double labelScale;
  final double? redlineStart;
  final double? redlineEnd;
  final Color scaleColor;
  final Color tickColor;
  final Color labelColor;
  final Color needleColor;
  final Color redlineColor;
  final Color hubColor;

  static const double _startAngle = math.pi * 0.75;
  static const double _sweepAngle = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Clamp on BOTH axes so the dial can never paint outside its own box,
    // whatever the window width does.
    final radius = math.min(size.width, size.height) / 2 - 16;
    if (radius <= 24) return;

    final scaleRect = Rect.fromCircle(center: center, radius: radius);

    // Base scale.
    canvas.drawArc(
      scaleRect,
      _startAngle,
      _sweepAngle,
      false,
      Paint()
        ..color = scaleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Redline band, drawn on the scale itself.
    final redStart = redlineStart;
    final redEnd = redlineEnd;
    if (redStart != null && redEnd != null && redEnd > redStart) {
      final from = (redStart / maxValue).clamp(0.0, 1.0);
      final to = (redEnd / maxValue).clamp(0.0, 1.0);
      canvas.drawArc(
        scaleRect,
        _startAngle + _sweepAngle * from,
        _sweepAngle * (to - from),
        false,
        Paint()
          ..color = redlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Ticks + numbers. 7 majors / 31 ticks on the speedo is exactly the game's
    // grid, scaled to our wider speed range.
    final majors = (maxValue / majorStep).round();
    final totalTicks = majors * minorPerMajor;
    final tickPaint = Paint()..strokeCap = StrokeCap.butt;

    for (var i = 0; i <= totalTicks; i++) {
      final ratio = i / totalTicks;
      final angle = _startAngle + _sweepAngle * ratio;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final isMajor = i % minorPerMajor == 0;
      final inner = radius - (isMajor ? 17 : 9);

      tickPaint
        ..color = tickColor
        ..strokeWidth = isMajor ? 1.6 : 1.0;
      canvas.drawLine(
        center + direction * inner,
        center + direction * (radius - 3),
        tickPaint,
      );

      if (!isMajor) continue;

      final tickValue = majorStep * (i / minorPerMajor);
      final label = (tickValue * labelScale).round().toString();
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelCenter = center + direction * (radius - 34);
      textPainter.paint(
        canvas,
        labelCenter - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Needle: from just outside the value readout to the scale.
    final valueRatio = (value / maxValue).clamp(0.0, 1.0);
    final needleAngle = _startAngle + _sweepAngle * valueRatio;
    final needleDirection = Offset(math.cos(needleAngle), math.sin(needleAngle));
    canvas.drawLine(
      center + needleDirection * (radius * 0.28),
      center + needleDirection * (radius - 10),
      Paint()
        ..color = needleColor
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Hub.
    canvas.drawCircle(center, 6.5, Paint()..color = hubColor.withValues(alpha: 0.35));
    canvas.drawCircle(center, 2.6, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(_DialPainter old) {
    return old.value != value ||
        old.maxValue != maxValue ||
        old.redlineStart != redlineStart ||
        old.redlineEnd != redlineEnd ||
        old.labelScale != labelScale ||
        old.majorStep != majorStep ||
        old.minorPerMajor != minorPerMajor;
  }
}

/// One GT7-style readout: micro-caption, big tabular value, muted sub-line.
class Gt7Readout extends StatelessWidget {
  const Gt7Readout({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.valueColor = gt7Text,
    this.width = 168,
  });

  final String label;
  final String value;
  final String? sub;
  final Color valueColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: gt7PanelDecoration(radius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: gt7Caption()),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: gt7Digital(size: 22, color: valueColor),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(
              sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gt7Caption(
                color: gt7TextMuted.withValues(alpha: 0.7),
                size: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// GT7 sends sentinel values for "no data yet": 0xFFFF in the 16-bit lap,
/// position and gear fields and 0xFFFFFFFF in the 32-bit lap-time fields.
/// They arrive whenever the car is in the menus, before a race starts, or
/// before a lap has been set, and they must never reach the screen as numbers.
const int _unset16 = 0xFFFF;
const int _unset32 = 0xFFFFFFFF;
const String _noTime = '--:--.---';

String gt7LapTime(int milliseconds) {
  if (milliseconds <= 0 ||
      milliseconds >= _unset32 ||
      milliseconds > 60 * 60 * 1000) {
    return _noTime;
  }
  final seconds = milliseconds / 1000.0;
  final minutes = (seconds / 60).floor();
  final remaining = seconds % 60;
  return '$minutes:${remaining.toStringAsFixed(3).padLeft(6, '0')}';
}

/// Distance as the HUD prints it: metres under a kilometre, kilometres above.
String gt7Distance(double metres) {
  if (metres < 1000) return '${metres.round()} m';
  return '${(metres / 1000).toStringAsFixed(2)} km';
}

String gt7Count(int value, int total) {
  if (total <= 0 || total >= _unset16 || value <= 0 || value >= _unset16) {
    return '--';
  }
  return '$value/$total';
}

String gt7Gear(int gear) {
  if (gear == -1) return 'R';
  if (gear == 0) return 'N';
  if (gear > 8) return '--';
  return gear.toString();
}

/// The cards that sit beside the load dial: the session's numbers (gear, fuel,
/// lap, position) and the car's own state (the four tyres, the fluids, the
/// brakes). They were three separate panels down the page; beside the dial they
/// read together, and the motion block becomes a rectangle rather than a band.
/// Lap, position and the lap in progress, in the corner of the map.
///
/// The three numbers a driver glances at between corners, where a racing HUD puts
/// them: over the map, rather than in a row of cards that costs a whole band of
/// the page for three short numbers.
class _SessionOverlay extends StatelessWidget {
  const _SessionOverlay({required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        // Dark enough to read the numbers over whatever the route does behind
        // them, thin enough to still see the route through it.
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(color: gt7Hairline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _line('LAP', gt7Count(telemetry.currentLap, telemetry.totalLaps)),
          const SizedBox(height: 4),
          _line('POSITION', gt7Count(telemetry.currentPos, telemetry.totalPositions)),
          const SizedBox(height: 4),
          _line(
            'TIME',
            telemetry.lapTimeMs >= 0
                ? gt7LapTime(telemetry.lapTimeMs)
                : '--:--.---',
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 54,
          child: Text(label, style: gt7Caption(color: gt7TextMuted, size: 8)),
        ),
        Text(value, style: gt7Digital(size: 15)),
      ],
    );
  }
}

/// The game's "Session Best" table: LAST / BEST rows with a signed delta pill.
class _SessionBestPanel extends StatelessWidget {
  const _SessionBestPanel({required this.telemetry, this.trace});

  final TelemetryData telemetry;

  /// For the live delta against the fastest lap of this session.
  final TrackTrace? trace;

  @override
  Widget build(BuildContext context) {
    final best = gt7LapTime(telemetry.bestLapTime);
    final last = gt7LapTime(telemetry.lastLapTime);
    final hasBest = best != _noTime;
    final hasLast = last != _noTime;
    final deltaMs = (hasLast && hasBest)
        ? telemetry.lastLapTime - telemetry.bestLapTime
        : null;
    // Live delta: the current lap against the fastest completed one, at the
    // same point on the track. Null until a lap has been completed.
    final liveDelta = trace?.deltaToBest();
    final ghostLap = trace?.bestLap;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: gt7PanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SESSION BEST', style: gt7Caption(color: gt7TextMuted)),
              const SizedBox(width: 12),
              if (ghostLap != null)
                Text(
                  'GHOST: LAP ${ghostLap + 1} OF THE SESSION',
                  style: gt7Caption(
                    color: gt7Best.withValues(alpha: 0.9),
                    size: 8,
                  ),
                ),
              const Spacer(),
              if (liveDelta != null)
                Row(
                  children: [
                    Text(
                      'LIVE VS BEST  ',
                      style: gt7Caption(color: gt7TextMuted, size: 8),
                    ),
                    Text(
                      '${liveDelta < 0 ? '-' : '+'}'
                      '${liveDelta.abs().toStringAsFixed(3)}',
                      style: gt7Digital(
                        size: 15,
                        color: liveDelta < 0 ? gt7Gain : gt7Warn,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          _TimingRow(
            label: 'LAST',
            time: last,
            deltaSeconds: deltaMs == null ? null : deltaMs / 1000.0,
          ),
          const SizedBox(height: 8),
          _TimingRow(label: 'BEST', time: best, highlight: true),
          const SizedBox(height: 10),
          Text(
            hasBest && hasLast
                ? 'DELTA TO BEST, ISOLATED LAP TIME'
                : 'WAITING FOR A COMPLETED LAP',
            style: gt7Caption(
              color: gt7TextMuted.withValues(alpha: 0.6),
              size: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  const _TimingRow({
    required this.label,
    required this.time,
    this.deltaSeconds,
    this.highlight = false,
  });

  final String label;
  final String time;
  final double? deltaSeconds;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    // The game's semantics: blue with a minus = faster than the reference,
    // red with a plus = slower.
    final delta = deltaSeconds;
    final isGain = delta != null && delta < 0;
    final deltaColor = isGain ? gt7Gain : gt7Warn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF16301F) : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: highlight ? gt7SlotB.withValues(alpha: 0.0) : gt7Hairline,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: gt7Caption(
                color: highlight ? gt7Text : gt7TextMuted,
                size: 11,
                letterSpacing: 1.6,
              ),
            ),
          ),
          Text(time, style: gt7Digital(size: 19)),
          const Spacer(),
          if (delta != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: deltaColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: deltaColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                '${isGain ? '-' : '+'}${delta.abs().toStringAsFixed(3)}',
                style: gt7Digital(size: 13, color: deltaColor),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tyres laid out the way the game draws them: four blocks around the car,
/// heat carried by colour rather than by words.
/// The route the car has driven, with what the trace knows about it. The line
/// is coloured by speed, so the map doubles as a picture of where the car is
/// quick and where it is not.
class _TrackMapPanel extends StatefulWidget {
  const _TrackMapPanel({
    required this.trace,
    this.mapHeight = 260,
    this.overlay,
  });

  final TrackTrace trace;

  /// Drawn over the map's own drawing box - the session's numbers, in the corner
  /// the way a racing HUD puts them. They were a row of cards under the dials,
  /// which is a lot of page for three numbers, and the map had the room.
  final Widget? overlay;

  /// How tall the drawing is. In the row with the motion block the panel has a
  /// tall neighbour and no reason to be short, and a taller box is a more
  /// detailed route: the map scales to fill whatever it is given.
  final double mapHeight;

  @override
  State<_TrackMapPanel> createState() => _TrackMapPanelState();
}

class _TrackMapPanelState extends State<_TrackMapPanel> {
  /// Navigator style: the map turns so the way the car is going is up, and the
  /// plane is tipped away from the camera.
  late bool _headingUp = kInitialMapMode == 'heading';

  /// Which circuit the measured lap looks like, recomputed when a lap lands.
  TrackMatch? _match;
  int _matchedLap = -1;

  TrackTrace get trace => widget.trace;

  /// Names the circuit from the lap the trace measured. GT7 sends no track id,
  /// so this is a lookup, and it stays quiet unless the evidence is strong.
  void _identify() {
    final lap = trace.laps;
    if (lap == _matchedLap) return;
    _matchedLap = lap;

    final catalog = context.read<TrackCatalog>();
    final service = context.read<TelemetryService>();
    // The demo drives a fictional loop; naming a real circuit for it would be
    // a lie dressed up as telemetry.
    if (service.isDemo || !catalog.isLoaded) {
      _match = null;
      return;
    }

    final signature = trace.lapSignature;
    final match = signature == null ? null : catalog.identify(signature);
    setState(() => _match = match);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _identify();
  }

  @override
  Widget build(BuildContext context) {
    // Laps are what the lookup depends on, so re-run it when the trace gains
    // one (cheap: it only looks at the last completed lap).
    if (trace.laps != _matchedLap) _identify();
    final range = trace.speedRange;
    final speed = range == null
        ? null
        : '${range.$1.round()} – ${range.$2.round()} km/h';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: gt7PanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The panel shares its row with the motion block on a wide page, so it
          // can be half as wide as it used to be. The explanatory caption is the
          // first thing to go: it is a paragraph, and a paragraph in a 400 px
          // column is six lines of grey above the map.
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Text(
                  'TRACK MAP',
                  style: gt7Caption(
                    color: gt7Text,
                    size: 11,
                    letterSpacing: 1.8,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: constraints.maxWidth < 620
                      ? const SizedBox.shrink()
                      : _TrackCaption(match: _match),
                ),
                if (speed != null) ...[
                  const SizedBox(width: 12),
                  Text(speed, style: gt7Caption(color: gt7TextMuted, size: 9)),
                ],
                const SizedBox(width: 10),
                _MapModeButton(
                  headingUp: _headingUp,
                  onTap: () => setState(() => _headingUp = !_headingUp),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: widget.mapHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TrackMap(
                    trace: trace,
                    headingUp: _headingUp,
                    // The navigator view is the one that is tipped away from the
                    // camera, like a mini map in a game; the whole-circuit plan
                    // is read flat.
                    tilt: _headingUp ? kMapTilt : 0,
                  ),
                ),
                if (widget.overlay != null)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: widget.overlay!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // A Wrap, not a Row: four facts and a five-step legend are wider than
          // half a page, and in the three-column layout the map gets half a page.
          Wrap(
            spacing: 20,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _mapFact('ROUTE', gt7Distance(trace.distance)),
              _mapFact('POINTS', '${trace.length}'),
              _mapFact('LAPS', '${trace.laps}'),
              _mapFact('ELEVATION', '${trace.elevationRange.round()} m'),
              const _SpeedLegend(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapFact(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: gt7Caption(size: 8)),
        const SizedBox(height: 3),
        Text(value, style: gt7Digital(size: 14)),
      ],
    );
  }
}

/// Switches the map between north-up and the navigator's heading-up view.
class _MapModeButton extends StatelessWidget {
  const _MapModeButton({required this.headingUp, required this.onTap});

  final bool headingUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: headingUp ? 0.10 : 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              headingUp ? Icons.navigation : Icons.explore,
              size: 11,
              color: gt7TextMuted,
            ),
            const SizedBox(width: 5),
            Text(
              headingUp ? 'HEADING UP' : 'NORTH UP',
              style: gt7Caption(color: gt7TextMuted, size: 8),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the colours on the line mean.
class _SpeedLegend extends StatelessWidget {
  const _SpeedLegend();

  static const List<(String, Color)> _steps = [
    ('<60', Color(0xFF3FB950)),
    ('<120', Color(0xFF8FD44B)),
    ('<180', Color(0xFFE7CB3C)),
    ('<250', Color(0xFFF0883E)),
    ('250+', Color(0xFFFA0F0B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (label, color) in _steps) ...[
          Container(width: 14, height: 3, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: gt7Caption(color: gt7TextMuted, size: 8),
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}

/// Says where the car is, when the measured lap says so convincingly.
class _TrackCaption extends StatelessWidget {
  const _TrackCaption({required this.match});

  final TrackMatch? match;

  @override
  Widget build(BuildContext context) {
    final match = this.match;

    if (match == null) {
      return Text(
        'THE ROUTE COMES FROM THE POSITION GT7 SENDS IN EVERY PACKET (X/Z), SO '
        'IT IS BUILT BY DRIVING — NO COURSE DATA, NO RIVALS. GT7 SENDS NO TRACK '
        'ID, SO THE CIRCUIT IS NAMED ONLY WHEN A DRIVEN LAP MATCHES ONE',
        style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.6), size: 8),
      );
    }

    final track = match.track;
    final percent = (match.confidence * 100).round();
    final length = (track.length / 1000).toStringAsFixed(3);

    return Row(
      children: [
        Text(
          track.name.toUpperCase(),
          style: gt7Caption(
            color: gt7Text,
            size: 10,
            letterSpacing: 1.2,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          match.ambiguousWith == null
              ? 'MATCHED FROM THE LAP · ${length} km · ${track.corners} CORNERS '
                    '· $percent%'
              : 'ALSO FITS ${match.ambiguousWith!.name.toUpperCase()} — '
                    'TOO CLOSE TO CALL',
          style: gt7Caption(
            color: match.ambiguousWith == null
                ? gt7TextMuted.withValues(alpha: 0.6)
                : gt7SlotB,
            size: 8,
          ),
        ),
      ],
    );
  }
}

/// The round load indicator, with the session's numbers beside it.
