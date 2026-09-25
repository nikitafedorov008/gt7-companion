import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/telemetry/track_trace.dart';
import '../../theme/gt7_theme.dart';

/// Steering and drift as **one instrument**: what the driver does with the
/// wheel, and what the car does with it.
///
/// It is its own widget because two places show it: the data view puts it in the
/// car's card (with the tyres, the fluids and the aids - all of it the car's
/// state), and the HUD's MFD page keeps it inline, having no cards to put it in.
///
/// They were two cards side by side, which left the reader comparing two pictures
/// in their head. Here they share one axis: the wheel is a filled dot with the
/// input bar behind it, the car's nose is a ring below the line, and the shaded
/// band between them *is* the slip angle - the distance between where the wheels
/// point and where the car actually goes.
///
/// The two markers are not the same unit. The wheel angle is a steering input
/// (up to full lock) and the nose angle is a slip (tens of degrees at most), so
/// each sits at its own full-scale position on a shared axis, and the numbers
/// are printed in degrees beside them. What the eye compares is how far into the
/// corner the wheels are against how far the car has let go, which is the
/// comparison a driver actually makes.
class AttitudeCard extends StatelessWidget {
  const AttitudeCard({
    required this.steering,
    required this.rate,
    required this.source,
    required this.trace,
  });

  /// Radians; NaN when the packet has no steering data.
  final double steering;

  /// Radians per second, from the motion block. NaN without it.
  final double rate;

  /// `B` or `C`: which packet the angle came from.
  final String? source;

  final TrackTrace? trace;

  /// Full lock on the input scale, and a slide big enough to fill the nose
  /// scale: the fraction of its own full scale that puts a marker at the end of
  /// the axis.
  static const double _fullSteer = 2.4;
  static const double _fullSlip = 0.7;

  static const Color _noseColour = Color(0xFFF0883E);

  @override
  Widget build(BuildContext context) {
    final hasWheel = !steering.isNaN;
    final wheelDeg = hasWheel ? steering * 180 / math.pi : double.nan;
    // Negative is left on screen: the packet turns left with a positive angle,
    // and so does the nose, since the slip is positive with the nose to the left
    // of the travel. The steering bar had this the other way round, which the
    // merged instrument would have shown as the two markers disagreeing about a
    // corner the car was taking cleanly.
    final wheelFraction =
        hasWheel ? (-steering / _fullSteer).clamp(-1.0, 1.0) : null;

    final slip = trace?.slipAngle;
    final measured = trace?.hasDriftData ?? false;
    final hasNose = slip != null && measured;
    final noseDeg = hasNose ? slip! * 180 / math.pi : double.nan;
    final noseFraction =
        hasNose ? (-slip! / _fullSlip).clamp(-1.0, 1.0) : null;

    final (verdict, verdictColour) = _verdict(
      wheelDeg: wheelDeg,
      noseDeg: noseDeg,
      hasWheel: hasWheel,
      hasNose: hasNose,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: gt7PanelDecoration(radius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  source == null ? 'STEERING' : 'STEERING · PACKET $source',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gt7Caption(color: gt7TextMuted, size: 9),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: verdictColour.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  verdict,
                  style: gt7Caption(color: verdictColour, size: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _marker(
                'WHEEL',
                hasWheel ? '${wheelDeg.toStringAsFixed(1)}°' : '—',
                gt7SlotA,
                note: !rate.isNaN ? '${rate.toStringAsFixed(2)} rad/s' : null,
              ),
              const Spacer(),
              _marker(
                'NOSE',
                hasNose ? '${noseDeg.abs().toStringAsFixed(1)}°' : '—',
                _noseColour,
                note: hasNose
                    ? (slip! > 0 ? 'LEFT OF TRAVEL' : 'RIGHT OF TRAVEL')
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
            child: CustomPaint(
              size: const Size(double.infinity, 30),
              painter: _AttitudePainter(
                wheel: wheelFraction,
                nose: noseFraction,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// What the two markers add up to, in one word.
  ///
  /// A heuristic, and deliberately a cautious one: the wheel is where the driver
  /// points and the nose is where the car ends up, so a nose turned further into
  /// the corner than the wheels is the rear letting go, and a nose turned out of
  /// it while the wheels are in is the front. It says nothing at all until the
  /// car is actually sliding - under 1.5 degrees the two numbers are noise around
  /// zero, and a verdict there would be invented rather than read.
  (String, Color) _verdict({
    required double wheelDeg,
    required double noseDeg,
    required bool hasWheel,
    required bool hasNose,
  }) {
    if (!hasWheel || !hasNose) return ('—', gt7TextMuted);
    if (noseDeg.abs() < 1.5) return ('GRIP', gt7Gain);
    if (wheelDeg.abs() < 1.0) return ('SLIDING', gt7Warn);
    return wheelDeg.sign == noseDeg.sign
        ? ('OVERSTEER', _noseColour)
        : ('UNDERSTEER', gt7SlotA);
  }

  Widget _marker(String label, String value, Color colour, {String? note}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(width: 8, height: 2, color: colour),
            const SizedBox(width: 5),
            Text(label, style: gt7Caption(color: gt7TextMuted, size: 8)),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: gt7Digital(size: 15, color: colour)),
            if (note != null) ...[
              const SizedBox(width: 8),
              Text(
                note,
                maxLines: 1,
                style: gt7Caption(color: gt7TextMuted, size: 8),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The shared axis: the input bar and the wheel dot on the line, the slip band
/// under it, and the nose ring below that, so no two marks ever hide one another.
class _AttitudePainter extends CustomPainter {
  const _AttitudePainter({required this.wheel, required this.nose});

  /// -1 (full left) … +1 (full right); null when the channel has no value.
  final double? wheel;
  final double? nose;

  static const double _lineY = 9;
  static const double _bandY = 15;
  static const double _noseY = 26;
  static const Color _noseColour = Color(0xFFF0883E);

  @override
  void paint(Canvas canvas, Size size) {
    final centreX = size.width / 2;
    double at(double fraction) => centreX + (size.width / 2) * fraction;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i <= 6; i++) {
      final x = size.width * i / 6;
      final tall = i == 3;
      canvas.drawLine(
        Offset(x, _lineY - (tall ? 7 : 3)),
        Offset(x, _lineY + (tall ? 7 : 3)),
        track,
      );
    }

    canvas.drawLine(
      Offset(0, _lineY),
      Offset(size.width, _lineY),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    final wheelValue = wheel;
    final noseValue = nose;

    // The slip: the space between the two markers, drawn first so both sit on it.
    if (wheelValue != null && noseValue != null) {
      final from = at(wheelValue);
      final to = at(noseValue);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            from < to ? from : to,
            _bandY,
            from < to ? to : from,
            _bandY + 4,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = _noseColour.withValues(alpha: 0.45),
      );
    }

    if (wheelValue != null) {
      // The input bar grows from the centre, the way a steering input reads.
      canvas.drawLine(
        Offset(centreX, _lineY),
        Offset(at(wheelValue), _lineY),
        Paint()
          ..color = gt7SlotA
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(at(wheelValue), _lineY),
        3.5,
        Paint()..color = Colors.white,
      );
    }

    if (noseValue != null) {
      canvas.drawCircle(
        Offset(at(noseValue), _noseY),
        3.5,
        Paint()
          ..color = _noseColour
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(_AttitudePainter old) =>
      old.wheel != wheel || old.nose != nose;
}

