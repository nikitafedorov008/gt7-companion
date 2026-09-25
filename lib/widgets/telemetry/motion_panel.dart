import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/telemetry/telemetry_data.dart';
import '../../models/telemetry/track_trace.dart';
import '../../theme/gt7_theme.dart';
import 'attitude_card.dart';
import 'g_force_ball.dart';
import 'telemetry_display.dart' show gt7LapTime;

/// Steering and g-forces - the three things the base packet "A" does not carry.
///
/// GT7 picks the packet from the heartbeat character: `A` (296 bytes) has the
/// car's rotation but no steering, `B` (316 bytes) adds the motion block, and
/// `C` (368 bytes) adds more on top. Everything here is blank when the console
/// is answering `A`, and says so instead of showing a zero.
class MotionPanel extends StatelessWidget {
  const MotionPanel({
    super.key,
    required this.telemetry,
    this.trace,
    this.bare = false,
    this.showDial = true,
    this.dialSize,
    this.readoutsBelow = false,
  });

  final TelemetryData telemetry;

  /// The driven route, which is where the drift angle comes from: it holds the
  /// positions (direction of travel) and the packet's yaw (where the body
  /// points). Optional, so the panel still works without a session.
  final TrackTrace? trace;

  /// Draws without the panel frame and heading, for the HUD's MFD page.
  final bool bare;

  /// Adds the round load dial. In a wide panel it sits on the left and the
  /// readouts stack beside it; in a narrow one the dial goes on top and the
  /// readouts follow underneath, which is the same component either way.
  final bool showDial;

  /// Fixes the dial's size. Left unset it takes the space the layout allows.
  final double? dialSize;

  /// Stacks the readouts under the dial whatever the width, which is what the
  /// data view asks for: there the cards that used to share this panel now sit
  /// beside it as separate cards, and the motion block is tall rather than wide.
  final bool readoutsBelow;

  @override
  Widget build(BuildContext context) {
    final body = _body(context);
    if (bare) return body;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: gt7PanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'MOTION',
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
                  telemetry.hasMotionData
                      ? 'THE LOAD VECTOR AND THE BODY ATTITUDE COME FROM PACKET '
                            '${telemetry.packetType}; STEERING AND DRIFT ARE ON '
                            'THE CAR\'S CARD BELOW'
                      : 'LOAD AND ATTITUDE ARE NOT IN PACKET A — ASK THE '
                            'CONSOLE FOR HEARTBEAT B OR C '
                            '(SEE UdpService.packetType)',
                  style: gt7Caption(
                    color: gt7TextMuted.withValues(alpha: 0.6),
                    size: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final data = telemetry;

    // Two orientations, one component: beside each other when there is room,
    // one above the other when there is not. The breakpoint is where the dial
    // plus a readable column of readouts stops fitting.
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 24.0;
        final wide = constraints.maxWidth >= 820 && !bare && !readoutsBelow;

        if (bare) {
          // The HUD's MFD page: a small dial beside two lines of facts.
          final small = dialSize ?? 120;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showDial)
                GForceBall(
                  telemetry: data,
                  size: small,
                  trailSeconds: 2,
                ),
              if (showDial) const SizedBox(width: 14),
              Expanded(
                child: _readouts(
                  data,
                  compact: true,
                  showWheelbase: small < kGForceBallWheelbaseSize,
                ),
              ),
            ],
          );
        }

        // Stacked, the dial can use the width the column has: the readouts are
        // underneath it, not fighting it for the room.
        final dialPx =
            dialSize ?? math.min(constraints.maxWidth, 470.0);
        // The dial draws the wheelbase itself once it is big enough for the
        // dimension to fit inside the rim, and the facts carry it until then.
        // One constant decides, so the number can never appear twice or vanish.
        final dialHasWheelbase =
            showDial && dialPx >= kGForceBallWheelbaseSize;

        final dial = showDial
            ? GForceBall(
                telemetry: data,
                // Wide: a square that includes the band the readouts sit in.
                size: dialPx,
              )
            : const SizedBox.shrink();

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              dial,
              const SizedBox(width: gap + 8),
              Expanded(
                child: _readouts(data, showWheelbase: !dialHasWheelbase),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: dial),
            const SizedBox(height: gap * 0.75),
            _readouts(data, showWheelbase: !dialHasWheelbase),
          ],
        );
      },
    );
  }

  /// The motion channels. The load vector, the two body angles and the peaks
  /// live on the dial itself, so they are not repeated here.
  Widget _readouts(
    TelemetryData data, {
    bool compact = false,
    bool showWheelbase = true,
  }) {
    // `readoutsBelow` also means "the cards are elsewhere on the page", which is
    // where the steering instrument goes on the data view.
    final readoutsBelow = this.readoutsBelow;
    final lateral = data.lateralG;
    final longitudinal = data.longitudinalG;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The instrument lives in the car's card on the data view (see
        // `AttitudeCard` and `MotionSideCards`); here it stays for the HUD's MFD
        // page, which has no cards to put it in.
        if (!readoutsBelow)
          AttitudeCard(
            // Packet C reports the front wheels themselves; B only the wheel
            // rotation, which is accepted when it is inside steering range.
            steering: data.steeringRadians ?? double.nan,
            rate: data.steeringRate,
            source: data.steeringSource,
            trace: trace,
          ),
        // The row exists for a dial too small to draw the wheelbase on the car
        // (the HUD's MFD page). When the dial is big enough it draws the
        // measurement itself, and a row repeating it - or a category that now
        // lives in the car's card - would only add height.
        if (showWheelbase) ...[
          const SizedBox(height: 14),
          _CarFactsRow(telemetry: data),
        ],
        if (!compact && !showDial) ...[
          // The dial shows the load vector itself; these numbers only appear
          // when it is not there to show them.
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GReadout(
                  label: 'LATERAL',
                  value: lateral,
                  hint: 'positive = to the right',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _GReadout(
                  label: 'LONGITUDINAL',
                  value: longitudinal,
                  hint: 'positive = accelerating',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GReadout extends StatelessWidget {
  const _GReadout({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final double? value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final g = value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: gt7Caption(size: 9)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                g == null ? '—' : g.abs().toStringAsFixed(2),
                style: gt7Digital(size: 22),
              ),
              const SizedBox(width: 4),
              Text('g', style: gt7Caption(color: gt7TextMuted, size: 10)),
              const SizedBox(width: 8),
              if (g != null)
                Text(
                  g >= 0 ? 'R' : 'L',
                  style: gt7Caption(
                    color: g >= 0 ? gt7SlotA : gt7SlotB,
                    size: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            style: gt7Caption(
              color: gt7TextMuted.withValues(alpha: 0.5),
              size: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// The drift angle: how far the car's body is turned away from the direction
/// it is travelling (`slip = travel - body`, so a positive number means the
/// nose points to the left of the way the car is going).
///
/// GT7 reports the body yaw in every packet but documents its unit as nothing
/// more than "-1 -> 1", so [TrackTrace] measures that unit from the drive
/// (see `bodyHeading`) and this widget says so while it is still learning,
/// instead of printing a number nobody can trust.
class _DriftBar extends StatelessWidget {
  const _DriftBar({required this.trace});

  final TrackTrace? trace;

  /// Anything past this is a big slide, and fills the bar.
  static const double _fullScale = 0.7; // radians, ~40 degrees

  @override
  Widget build(BuildContext context) {
    final trace = this.trace;
    final slip = trace?.slipAngle;
    final calibrated = trace?.hasDriftData ?? false;
    final degrees = (slip == null || !calibrated) ? null : slip * 180 / math.pi;
    final scale = trace?.yawScale;

    return _ChannelCard(
      title: 'DRIFT ANGLE',
      value: degrees == null ? '—' : '${degrees.abs().toStringAsFixed(1)}°',
      valueColor: (degrees?.abs() ?? 0) > 5 ? const Color(0xFFF0883E) : gt7Text,
      note: (degrees != null && slip != null)
          ? (slip > 0 ? 'NOSE LEFT' : 'NOSE RIGHT')
          : null,
      height: 22,
      // The needle follows the nose: slip is travel - body, so a positive value
      // means the body is turned left of the travel.
      painter: _DriftPainter(
        fraction: (slip != null && calibrated)
            ? (-slip / _fullScale).clamp(-1.0, 1.0)
            : null,
      ),
      footer: Text(
          calibrated
              ? scale == null
                    ? 'BODY ANGLE TAKEN FROM THE PACKET\'S ROTATION QUATERNION — '
                          'EXACT, NO CALIBRATION NEEDED'
                    : 'YAW UNIT MEASURED AT ${scale.toStringAsFixed(2)} '
                          'RAD/PACKET (${(scale * 180 / math.pi).round()}°)'
              : trace == null
              ? 'NEEDS A DRIVE TO MEASURE THE PACKET\'S YAW UNIT'
              : slip == null
              ? 'DRIVE A LITTLE FURTHER: THE SLIP ANGLE NEEDS TWO POINTS'
              : 'MEASURING THE PACKET\'S YAW UNIT FROM THE DRIVE…',
          style: gt7Caption(
            color: gt7TextMuted.withValues(alpha: 0.5),
            size: 8,
          ),
        ),
    );
  }
}

/// One channel of the motion block: a title, its number, its bar, and where the
/// number came from.
///
/// The two channels that use it - steering and drift - are short and belong
/// together, so they share a shape and sit side by side. The card is what keeps
/// them from reading as one wide instrument each: a steering bar across the whole
/// panel said less than half of one beside its neighbour.
class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.title,
    required this.value,
    required this.painter,
    this.valueColor = gt7Text,
    this.note,
    this.footer,
    this.height = 22,
  });

  final String title;
  final String value;
  final CustomPainter painter;
  final Color valueColor;
  final String? note;
  final Widget? footer;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: gt7PanelDecoration(radius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Flexible rather than Spacer: in a narrow column the label and
              // the numbers together are wider than the row, and a fixed label
              // pushes the value off the edge instead of giving way.
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gt7Caption(color: gt7TextMuted, size: 9),
                ),
              ),
              const Spacer(),
              Text(value, style: gt7Digital(size: 16, color: valueColor)),
              if (note != null) ...[
                const SizedBox(width: 10),
                Text(
                  note!,
                  maxLines: 1,
                  style: gt7Caption(color: gt7TextMuted, size: 8),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: height,
            child: CustomPaint(
              size: Size(double.infinity, height),
              painter: painter,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _DriftPainter extends CustomPainter {
  _DriftPainter({required this.fraction});

  final double? fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final centreY = size.height / 2;
    final centreX = size.width / 2;

    canvas.drawLine(
      Offset(0, centreY - 2),
      Offset(size.width, centreY - 2),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // A tick for "no slip": the needle that walks away from it is the drift.
    canvas.drawLine(
      Offset(centreX, centreY - 7),
      Offset(centreX, centreY + 3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );

    final value = fraction;
    if (value == null) return;

    canvas.drawCircle(
      Offset(centreX + (size.width / 2) * value, centreY - 2),
      3.5,
      Paint()..color = const Color(0xFFF0883E),
    );
  }

  @override
  bool shouldRepaint(_DriftPainter old) => old.fraction != fraction;
}

/// Which surface each tyre is on. GT7 only reports it in packet `C`, and it is
/// the difference between a clean lap and one with two wheels on the grass.
/// What packet `C` says about the car itself: its category and - until the dial
/// is big enough to draw it - its wheelbase.
///
/// It is a [Wrap] rather than a row: in a narrow panel - a phone, or the panel
/// stacked under the dial - the facts flow onto a second line instead of
/// running off the edge.
///
/// The aids and the energy recovery used to sit here too. They are the car's
/// state rather than the driver's doing, so they moved to the `TYRES & VEHICLE`
/// card, which is where the rest of the car's state lives.
class _CarFactsRow extends StatelessWidget {
  const _CarFactsRow({required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    final category = telemetry.carCategory.replaceAll('\u0000', '');
    final wheelbase = telemetry.leftWheelbaseMeters;

    return Wrap(
      spacing: 22,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _fact('CATEGORY', category.isEmpty ? '—' : category),
        _fact(
          // Measured down the left-hand side, so it only equals the car's
          // wheelbase when the wheels are straight.
          'LEFT WHEELBASE',
          wheelbase.isNaN ? '—' : '${wheelbase.toStringAsFixed(2)} m',
        ),
      ],
    );
  }

  Widget _fact(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: gt7Caption(color: gt7TextMuted, size: 8)),
        const SizedBox(width: 6),
        Text(value, style: gt7Digital(size: 12)),
      ],
    );
  }
}
