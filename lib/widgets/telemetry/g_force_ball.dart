import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/telemetry/telemetry_data.dart';
import '../../theme/gt7_theme.dart';
import 'car_model_3d.dart';
import 'surface_codes.dart';

/// The dial size at which it earns its labels: the four channel readouts around
/// the circle and the value arcs on the rim. Below this the same information is
/// text in the panel beside it, and the dial would only smear it.
const double kGForceBallLabelledSize = 300;

/// The width of the band the four channel readouts sit in, between the circle
/// and the edge of the widget.
///
/// It has to hold a label, its value and its hint, laid out around the circle:
/// the widest value is about 52 px at the size below, and the top block sits
/// 52 px above the rim. Everything that depends on it - the radius, and the dial
/// size at which the wheelbase label still fits inside the circle - is derived
/// from this one number, so shrinking the text to grow the circle is a single
/// edit rather than four.
const double kGForceBallLabelBand = 72;

/// The dial size at which the wheelbase dimension fits *inside* the circle.
///
/// The dimension's number does not scale with the dial - text at 7 and 10 px is
/// text at 7 and 10 px - so on a small labelled dial it would grow out through
/// the rim. Below this size the number stays in the readouts beside the dial,
/// and `MotionPanel` asks this constant rather than repeating the threshold.
const double kGForceBallWheelbaseSize = 2 * (100 + kGForceBallLabelBand);

/// The radius that leaves the dimension's label room inside the rim: the
/// labelled dial gives up [kGForceBallLabelBand] to the text band before the
/// radius even starts.
const double _minWheelbaseRadius =
    kGForceBallWheelbaseSize / 2 - kGForceBallLabelBand;

/// A round, pseudo-3D load indicator.
///
/// The idea is the old racing "g-ball": the load the car is under is a vector,
/// and a vector is easier to read as a ball rolling around a dial than as two
/// numbers. What the packet adds is the two other halves of the picture:
///
///  * `sway` / `surge` (packet `B` and up) are the lateral and longitudinal
///    accelerations in m/s², so the ball's position is measured, not estimated;
///  * the rotation block is the body's real attitude, so the car in the middle
///    *leans and pitches* by the angles the game reports, not by a guess - and
///    when the packet carries no quaternion the lean falls back to the load,
///    which is what a driver would expect to see anyway;
///  * `heave` is the vertical acceleration, used to make the car breathe over
///    bumps instead of standing perfectly still.
///
/// Around the dial are the axes: lateral to the sides, longitudinal up and
/// down, with the session's peaks marked on them. The floor is drawn as a
/// perspective grid so the ball reads as sitting *on* the plane rather than
/// sliding across a flat dial.
class GForceBall extends StatefulWidget {
  const GForceBall({
    super.key,
    required this.telemetry,
    this.size = 260,
    this.trailSeconds = 3.0,
    this.labels = true,
  });

  final TelemetryData telemetry;

  /// Diameter of the dial, in pixels.
  final double size;

  /// How much of the ball's recent path to keep, in seconds of driving.
  final double trailSeconds;

  /// Draw the channel readouts around the circle, each in its own colour, and
  /// the matching value arcs on the rim. Switched off automatically on a dial
  /// too small to carry text.
  final bool labels;

  @override
  State<GForceBall> createState() => _GForceBallState();
}

class _GForceBallState extends State<GForceBall> {
  /// Recent (lateral, longitudinal) positions in g, newest last.
  final List<Offset> _trail = [];

  int _lastPacket = -1;
  double _peakLateral = 0;
  double _peakLongitudinal = 0;

  /// Smoothed vertical offset from `heave`, in g: the car's breathing.
  double _heave = 0;

  @override
  void didUpdateWidget(GForceBall oldWidget) {
    super.didUpdateWidget(oldWidget);
    final telemetry = widget.telemetry;
    if (telemetry.packetId == _lastPacket) return;
    _lastPacket = telemetry.packetId;

    final lateral = telemetry.lateralG;
    final longitudinal = telemetry.longitudinalG;
    if (lateral == null || longitudinal == null) return;

    _trail.add(Offset(lateral, longitudinal));
    // Keep the trail bounded by time, assuming the 60 Hz feed the game sends.
    final keep = (widget.trailSeconds * 60).round().clamp(30, 600);
    if (_trail.length > keep) _trail.removeRange(0, _trail.length - keep);

    _peakLateral = math.max(_peakLateral, lateral.abs());
    _peakLongitudinal = math.max(_peakLongitudinal, longitudinal.abs());

    final heave = telemetry.heave;
    if (!heave.isNaN) {
      // A light low-pass, so the car shivers rather than teleports.
      _heave = _heave * 0.82 + (heave / 9.80665).clamp(-1.5, 1.5) * 0.18;
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = widget.telemetry;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _GForcePainter(
          // Below this the text would be noise rather than information.
          withLabels: widget.labels && widget.size >= kGForceBallLabelledSize,
          lateral: telemetry.lateralG,
          longitudinal: telemetry.longitudinalG,
          heave: _heave,
          roll: telemetry.bodyRollRadians,
          pitch: telemetry.bodyPitchRadians,
          wheelColours: gt7WheelSurfaceColours(telemetry.surfaceTypes),
          // Packet C's wheelbase, drawn on the car as a dimension line. Zero
          // when the console is answering A or B.
          wheelbase: telemetry.leftWheelbaseMeters,
          wheelAngle: telemetry.steeringRadians,
          // Separate angles for the two front wheels: GT7 sends them in packet
          // C, and they differ by design (Ackermann).
          leftWheelAngle: telemetry.frontWheelAngleLeft.isNaN
              ? null
              : telemetry.frontWheelAngleLeft,
          rightWheelAngle: telemetry.frontWheelAngleRight.isNaN
              ? null
              : telemetry.frontWheelAngleRight,
          wheelSource: telemetry.steeringSource,
          trail: _trail,
          peakLateral: _peakLateral,
          peakLongitudinal: _peakLongitudinal,
          packetType: telemetry.packetType,
          hasData: telemetry.hasMotionData,
        ),
      ),
    );
  }
}

/// The surface under each tyre, as a colour, in the order the 3D model lists
/// its wheels - front-left, front-right, rear-left, rear-right - or null when
/// the packet carries no surface data at all.
///
/// Tarmac maps to null: nothing is tinted, and the tyre keeps its own colour.
/// A kerb does tint, because a kerb is a different surface and the driver can
/// feel it.
List<Color?>? gt7WheelSurfaceColours(String surfaceTypes) {
  if (surfaceTypes.length < 4) return null;
  final colours = <Color?>[];
  var tinted = false;
  for (var i = 0; i < 4; i++) {
    final code = surfaceTypes[i];
    if (code == 'T') {
      colours.add(null);
      continue;
    }
    colours.add(gt7SurfaceColour(code));
    tinted = true;
  }
  // All four wheels on tarmac is not information, so the car stays plain.
  return tinted ? colours : null;
}

/// Where a readout sits relative to its anchor.
enum _AlignX { left, centre, right }

class _GForcePainter extends CustomPainter {
  _GForcePainter({
    required this.lateral,
    required this.longitudinal,
    required this.heave,
    required this.roll,
    required this.pitch,
    required this.wheelColours,
    required this.wheelbase,
    required this.wheelAngle,
    required this.leftWheelAngle,
    required this.rightWheelAngle,
    required this.wheelSource,
    required this.trail,
    required this.peakLateral,
    required this.peakLongitudinal,
    required this.packetType,
    required this.hasData,
    required this.withLabels,
  });

  final double? lateral;
  final double? longitudinal;
  final double heave;
  final double? roll;
  final double? pitch;
  final List<Color?>? wheelColours;

  /// The distance between the axles, in metres, as packet `C` reports it.
  final double wheelbase;
  final double? wheelAngle;
  final double? leftWheelAngle;
  final double? rightWheelAngle;
  final String? wheelSource;
  final List<Offset> trail;
  final double peakLateral;
  final double peakLongitudinal;
  final String packetType;
  final bool hasData;
  final bool withLabels;

  /// How many g the dial shows from the centre to the rim.
  static const double _fullScale = 3.0;

  /// One colour per channel: the side load is the dial's own blue, acceleration
  /// and braking are the green and red the rest of the HUD uses for gain and
  /// loss, and the two body angles have their own to stay distinguishable.
  static const Color _lateralColour = gt7SlotA;
  static const Color _accelColour = Color(0xFF3FB950);
  static const Color _brakeColour = gt7Warn;
  static const Color _rollColour = Color(0xFFB07CE8);
  static const Color _pitchColour = gt7SlotB;

  /// How far the camera looks down on the car, and the vertical squash of the
  /// floor grid that has to agree with it or the car floats off its own plane:
  /// a ground-plane distance projects as `sin(tilt)`, so the two are the same
  /// number twice.
  ///
  /// 24 degrees is deliberate. It is low enough to read as "behind the car"
  /// rather than as a plan drawing (which is what the first version was, and
  /// what gave away the tyres: from high above they hide under the body), and
  /// still high enough to show the body's volume and the two front wheels, so a
  /// surface colour painted on a tyre can actually be seen.
  static const double _cameraTilt = 0.42;
  static const double _squash = 0.408;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    // With readouts around it the circle gives up a band for the text; without
    // them it can use the whole square.
    final radius = math.min(size.width, size.height) / 2 -
        (withLabels ? kGForceBallLabelBand : 2);

    _paintRim(canvas, centre, radius);
    if (withLabels) _paintValueArcs(canvas, centre, radius);
    _paintFloor(canvas, centre, radius);
    _paintAxes(canvas, centre, radius);

    if (!hasData) {
      _paintNoData(canvas, centre, radius);
      return;
    }

    _paintTrail(canvas, centre, radius);
    _paintBall(canvas, centre, radius);
    _paintCar(canvas, centre, radius);

    if (withLabels) _paintChannels(canvas, centre, radius);
  }

  /// The rim carries the two load channels as coloured arcs, so the circle
  /// itself shows the numbers instead of only decorating the readouts:
  ///
  ///  * the lateral arc starts at twelve o'clock and swings towards three for a
  ///    load to the right and towards nine for one to the left - the same way
  ///    the ball moves;
  ///  * the longitudinal arc starts at three o'clock and swings up towards
  ///    twelve under acceleration, down towards six under braking.
  ///
  /// A quarter of the circle is a full scale of three g.
  void _paintValueArcs(Canvas canvas, Offset centre, double radius) {
    final lateralValue = lateral;
    final longitudinalValue = longitudinal;
    final arcRadius = radius - 3;
    final arcRect = Rect.fromCircle(center: centre, radius: arcRadius);
    final sweepMax = math.pi / 2;

    if (lateralValue != null) {
      // From the top: right of the car swings clockwise, left anticlockwise.
      // Flutter measures arcs from three o'clock with positive angles going
      // clockwise, so the top is -pi/2.
      final sweep = (lateralValue / _fullScale).clamp(-1.0, 1.0) * sweepMax;
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = _lateralColour,
      );
    }

    if (longitudinalValue != null) {
      // From three o'clock: accelerating swings up (negative angles in
      // Flutter's convention), braking swings down.
      final sweep =
          -(longitudinalValue / _fullScale).clamp(-1.0, 1.0) * sweepMax;
      canvas.drawArc(
        arcRect,
        0,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = longitudinalValue >= 0 ? _accelColour : _brakeColour,
      );
    }
  }

  /// The readouts, one per quarter, each with its own colour.
  void _paintChannels(Canvas canvas, Offset centre, double radius) {
    final longitudinalValue = longitudinal;
    final rollValue = roll;
    final pitchValue = pitch;

    // Left: how hard the car is being pushed sideways.
    _block(
      canvas,
      anchor: Offset(centre.dx - radius - 14, centre.dy - 34),
      alignX: _AlignX.right,
      label: 'LATERAL',
      value: lateral == null
          ? '—'
          : '${lateral!.abs().toStringAsFixed(2)} g',
      hint: lateral == null
          ? 'NOT IN THIS PACKET'
          : (lateral! >= 0 ? 'TO THE RIGHT' : 'TO THE LEFT'),
      colour: _lateralColour,
    );

    // Top: acceleration and braking share the channel, and the colour says
    // which one is happening.
    final accelerating = (longitudinalValue ?? 0) >= 0;
    _block(
      canvas,
      anchor: Offset(centre.dx, centre.dy - radius - 52),
      alignX: _AlignX.centre,
      label: 'LONGITUDINAL',
      value: longitudinalValue == null
          ? '—'
          : '${longitudinalValue.abs().toStringAsFixed(2)} g',
      hint: longitudinalValue == null
          ? 'NOT IN THIS PACKET'
          : (accelerating ? 'ACCELERATING' : 'BRAKING'),
      colour: longitudinalValue == null
          ? gt7TextMuted
          : (accelerating ? _accelColour : _brakeColour),
    );

    // Right: the two attitude angles.
    _block(
      canvas,
      anchor: Offset(centre.dx + radius + 14, centre.dy - 34),
      alignX: _AlignX.left,
      label: 'BODY ROLL',
      value: rollValue == null
          ? '—'
          : '${(rollValue * 180 / math.pi).abs().toStringAsFixed(1)}°',
      hint: rollValue == null
          ? 'PACKET A HAS NO ATTITUDE'
          : (rollValue >= 0 ? 'LEANING RIGHT' : 'LEANING LEFT'),
      colour: _rollColour,
    );

    // Bottom: the same for pitch, which is the angle the nose sits at.
    _block(
      canvas,
      anchor: Offset(centre.dx, centre.dy + radius + 10),
      alignX: _AlignX.centre,
      label: 'BODY PITCH',
      value: pitchValue == null
          ? '—'
          : '${(pitchValue * 180 / math.pi).abs().toStringAsFixed(1)}°',
      hint: pitchValue == null
          ? 'PACKET A HAS NO ATTITUDE'
          : (pitchValue >= 0 ? 'NOSE UP' : 'NOSE DOWN'),
      colour: _pitchColour,
    );
  }

  /// One readout: a colour rule, the label, the number and what it means.
  void _block(
    Canvas canvas, {
    required Offset anchor,
    required _AlignX alignX,
    required String label,
    required String value,
    required String hint,
    required Color colour,
  }) {
    final labelPainter = _painter(
      label,
      gt7Caption(color: gt7TextMuted, size: 8),
    );
    final valuePainter = _painter(value, gt7Digital(size: 15, color: colour));
    final hintPainter = _painter(
      hint,
      gt7Caption(color: gt7TextMuted.withValues(alpha: 0.75), size: 6),
    );

    final width = [
      labelPainter.width + 12,
      valuePainter.width,
      hintPainter.width,
    ].reduce(math.max);

    final x = switch (alignX) {
      _AlignX.left => anchor.dx,
      _AlignX.centre => anchor.dx - width / 2,
      _AlignX.right => anchor.dx - width,
    };

    // A short rule in the channel's colour, then the label beside it.
    final ruleY = anchor.dy + labelPainter.height / 2;
    canvas.drawLine(
      Offset(x, ruleY),
      Offset(x + 8, ruleY),
      Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = colour,
    );
    labelPainter.paint(canvas, Offset(x + 12, anchor.dy));

    final valueY = anchor.dy + labelPainter.height + 3;
    final valueX = switch (alignX) {
      _AlignX.left => x,
      _AlignX.centre => anchor.dx - valuePainter.width / 2,
      _AlignX.right => anchor.dx - valuePainter.width,
    };
    valuePainter.paint(canvas, Offset(valueX, valueY));

    hintPainter.paint(
      canvas,
      Offset(
        switch (alignX) {
          _AlignX.left => x,
          _AlignX.centre => anchor.dx - hintPainter.width / 2,
          _AlignX.right => anchor.dx - hintPainter.width,
        },
        valueY + valuePainter.height + 2,
      ),
    );
  }

  TextPainter _painter(String text, TextStyle style) =>
      TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

  /// Rim, tick marks and the peak markers.
  void _paintRim(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      centre,
      radius * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    for (var g = 1; g <= _fullScale; g++) {
      final r = radius * (g / _fullScale);
      canvas.drawCircle(
        centre,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = g == 1 || g == 2 ? 0.8 : 0.5
          ..color = Colors.white.withValues(alpha: g.isEven ? 0.14 : 0.08),
      );
    }

    // Peak marks: how hard the session has been, in each direction.
    final peak = Paint()..color = gt7Warn.withValues(alpha: 0.9);
    void mark(double value, Offset direction) {
      if (value <= 0.05) return;
      final at = centre +
          Offset(
            direction.dx * radius * (value / _fullScale).clamp(0.0, 1.0),
            direction.dy * radius * (value / _fullScale).clamp(0.0, 1.0),
          );
      canvas.drawCircle(at, 2.4, peak);
    }

    mark(peakLateral, const Offset(1, 0));
    mark(peakLateral, const Offset(-1, 0));
    mark(peakLongitudinal, const Offset(0, -1));
    mark(peakLongitudinal, const Offset(0, 1));

    _text(canvas, 'LAT', centre + Offset(radius - 26, -6), _lateralColour);
    _text(canvas, 'ACC', centre + Offset(-32, -radius * _squash + 2), _accelColour);
    _text(canvas, 'BRK', centre + Offset(-32, radius * _squash - 12), _brakeColour);
    _text(
      canvas,
      '${_fullScale.toStringAsFixed(0)} g',
      centre + Offset(6, -radius + 4),
      gt7TextMuted.withValues(alpha: 0.5),
      size: 7,
    );
  }

  /// The floor: concentric ellipses and radial spokes, which is what makes the
  /// dial read as a plane seen from above and behind.
  void _paintFloor(Canvas canvas, Offset centre, double radius) {
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = gt7SlotA.withValues(alpha: 0.13);

    for (var i = 1; i <= 3; i++) {
      final r = radius * i / 3;
      canvas.drawOval(
        Rect.fromCenter(
          center: centre,
          width: r * 2,
          height: r * 2 * _squash,
        ),
        grid,
      );
    }

    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      canvas.drawLine(
        centre,
        centre +
            Offset(
              math.cos(angle) * radius,
              math.sin(angle) * radius * _squash,
            ),
        grid..color = gt7SlotA.withValues(alpha: 0.07),
      );
    }
  }

  void _paintAxes(Canvas canvas, Offset centre, double radius) {
    final axis = Paint()
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.16);

    canvas.drawLine(
      centre + Offset(-radius, 0),
      centre + Offset(radius, 0),
      axis,
    );
    canvas.drawLine(
      centre + Offset(0, -radius * _squash),
      centre + Offset(0, radius * _squash),
      axis,
    );

    for (var g = 1; g <= _fullScale; g++) {
      final x = radius * g / _fullScale;
      canvas.drawLine(
        centre + Offset(x, -3),
        centre + Offset(x, 3),
        axis,
      );
      canvas.drawLine(
        centre + Offset(-x, -3),
        centre + Offset(-x, 3),
        axis,
      );
      final y = radius * _squash * g / _fullScale;
      canvas.drawLine(centre + Offset(-3, y), centre + Offset(3, y), axis);
      canvas.drawLine(centre + Offset(-3, -y), centre + Offset(3, -y), axis);
    }
  }

  /// The recent path of the load, fading out behind the ball.
  void _paintTrail(Canvas canvas, Offset centre, double radius) {
    if (trail.length < 2) return;
    for (var i = 1; i < trail.length; i++) {
      final t = i / trail.length;
      canvas.drawLine(
        _toCanvas(trail[i - 1], centre, radius),
        _toCanvas(trail[i], centre, radius),
        Paint()
          ..strokeWidth = 1.6 * t + 0.4
          ..strokeCap = StrokeCap.round
          ..color = gt7SlotA.withValues(alpha: 0.05 + 0.35 * t),
      );
    }
  }

  /// The ball itself: a lit sphere with a shadow on the floor under it.
  void _paintBall(Canvas canvas, Offset centre, double radius) {
    final at = _toCanvas(Offset(lateral ?? 0, longitudinal ?? 0), centre, radius);
    final r = 9.0 + 2.0 * (1 - _normalised(at, centre, radius).dy);

    // Shadow, squashed, offset by how high the ball sits.
    canvas.drawOval(
      Rect.fromCenter(
        center: at + const Offset(2, 6),
        width: r * 1.9,
        height: r * 0.9,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [
            Colors.white,
            gt7SlotA,
            gt7SlotA.withValues(alpha: 0.75),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
  }

  /// The car in the middle: a small 3D model that leans, pitches and steers by
  /// the numbers the packet reports.
  void _paintCar(Canvas canvas, Offset centre, double radius) {
    // Real attitude when the packet carries a quaternion; otherwise the load
    // itself stands in for the lean, which is the direction a car rolls.
    final rollAngle = roll ?? -(lateral ?? 0) * 0.045;
    final pitchAngle = pitch ?? (longitudinal ?? 0) * 0.035;

    // Metres to pixels: seen from behind a car is narrow and foreshortened, so
    // it needs a little more room than a side view did.
    // Big enough that a steering angle reads as a turned wheel rather than as a
    // pixel moving, and big enough for a tyre's surface colour to be seen: at
    // this size the car fills about half the dial.
    final scale = radius / 4.8;

    CarModel3D.paint(
      canvas,
      centre: centre + Offset(0, heave * 3),
      metresToPixels: scale,
      // In the model the nose is -z, which the camera already renders as "away",
      // so no half turn is needed: the rear wing sits nearest the viewer and the
      // nose points up the dial. The small angle makes it a three-quarter view,
      // the chase angle racing games use, which is the only way the front
      // wheels stay visible past the body.
      yaw: 0.32,
      cameraTilt: _cameraTilt,
      // The packet's convention: positive roll is the right-hand side down,
      // positive pitch is the nose up. The model's roll axis runs the other way
      // round, hence the sign.
      roll: -rollAngle,
      pitch: pitchAngle,
      steeringLeft: _leftWheelAngle,
      steeringRight: _rightWheelAngle,
      // The surface readout, drawn onto the car itself: each tyre takes the
      // colour of what it is standing on.
      wheelColours: wheelColours,
      body: const Color(0xFFE8ECEF),
      // A glass car: the body is a shell, so the dial's grid shows through it
      // and the volume reads from the edges rather than from a filled shape.
      opacity: 0.5,
    );

    _paintWheelbase(canvas, centre, radius);
  }

  /// The wheelbase, drawn on the car the way a technical drawing does it: a line
  /// down the left flank between the two axles, a tick at each, and the number.
  ///
  /// It is on the dial and not in the readouts because the number only means
  /// anything next to the car it describes - and the dial already has the axles
  /// on screen, so the line costs one label and explains itself.
  void _paintWheelbase(Canvas canvas, Offset centre, double radius) {
    if (!withLabels || radius < _minWheelbaseRadius || wheelbase <= 0) return;

    const yaw = 0.32;
    final scale = radius / 4.8;
    final carCentre = centre + Offset(0, heave * 3);

    Offset onGround(double x, double z) => CarModel3D.project(
          centre: carCentre,
          metresToPixels: scale,
          local: (x: x, y: 0.02, z: z),
          yaw: yaw,
          cameraTilt: _cameraTilt,
          onGround: true,
        );

    // Outboard of the right-hand tyres (the wheel centre is 0.80 m out and the
    // tyre is 0.34 m wide). The offset has to clear the car's *silhouette*, not
    // its geometry: the car is yawed 18 degrees, so the flank of a nearer point
    // is drawn further out than a further one, and a line at 1.02 m ran through
    // the rear corner. 1.45 m clears the whole car, tyres included.
    //
    // Drawn on the right rather than the left because that is the side the
    // camera is nearest to and the side the eye reads as "this car": on the left
    // the line sat behind the body from this viewing angle. The *number* is the
    // packet's left-hand wheelbase, which is what GT7 reports.
    const x = 1.45;
    const tick = 0.18;
    final frontZ = CarModel3D.frontRightWheel.z;
    final rearZ = CarModel3D.rearRightWheel.z;

    final line = Paint()
      ..color = gt7Text.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(onGround(x, frontZ), onGround(x, rearZ), line);
    for (final z in [frontZ, rearZ]) {
      canvas.drawLine(onGround(x - tick, z), onGround(x + tick, z), line);
    }

    // The number sits between the line and the dial's rim, left-aligned to the
    // line so it grows away from the car instead of into it.
    final middle = onGround(x, (frontZ + rearZ) / 2);
    final caption = _captionPainter(
      'WHEELBASE',
      gt7TextMuted.withValues(alpha: 0.9),
      7,
    );
    final value = _captionPainter(
      '${wheelbase.toStringAsFixed(2)} m',
      gt7Text,
      10,
    );
    final left = middle.dx + 10;
    final width = math.max(caption.width, value.width);
    final labelHeight = caption.height + value.height;

    // A plate behind the text, because the label shares the dial with the load
    // ball: at a right-hand load the ball sits exactly here, and a measurement
    // half-covered by the thing it measures is worse than no measurement.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left - 7,
          middle.dy - 11,
          width + 14,
          labelHeight + 8,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    caption.paint(canvas, Offset(left, middle.dy - 10));
    value.paint(canvas, Offset(left, middle.dy + 1));
  }

  /// How far each front wheel should visibly turn.
  ///
  /// The left and right wheels are separate, because they really are separate:
  /// packet `C` reports the two front wheel angles individually, which is the
  /// Ackermann geometry - the inner wheel turns sharper than the outer. When
  /// only one angle is available (packet `B` reports the steering wheel) both
  /// wheels take it, and when there is none (packet `A`) neither turns.
  ///
  /// Two corrections make this readable, and both are deliberate:
  ///
  ///  * packet `C` reports the road wheels themselves (about 10 degrees through
  ///    a corner, 35 at full lock) while packet `B` reports the steering wheel,
  ///    which turns several times as far - so `B` is scaled down to match what a
  ///    wheel does;
  ///  * the result is then *amplified* for the dial. At this size a car is
  ///    about 150 px long and a 10 degree wheel turn moves its edge by a
  ///    single pixel, which communicates nothing at a glance.
  double get _leftWheelAngle => _visible(named: leftWheelAngle);
  double get _rightWheelAngle => _visible(named: rightWheelAngle);

  double _visible({required double? named}) {
    final single = wheelAngle;
    final angle = named ?? single;
    if (angle == null) return 0;
    final roadWheel = named == null && wheelSource == 'B' ? angle * 0.3 : angle;
    return (roadWheel * 2.5).clamp(-0.6, 0.6);
  }

  void _paintNoData(Canvas canvas, Offset centre, double radius) {
    _text(
      canvas,
      'NO LOAD DATA',
      centre + Offset(-42, -8),
      gt7Warn.withValues(alpha: 0.85),
      size: 10,
    );
    _text(
      canvas,
      'PACKET $packetType HAS NO G — ASK FOR B OR C',
      centre + Offset(-88, 6),
      gt7TextMuted.withValues(alpha: 0.7),
      size: 8,
    );
  }

  /// g → canvas, with the longitudinal axis flipped so acceleration is up.
  ///
  /// The vector is clamped to the dial: a corner harder than the scale would
  /// otherwise push the ball out through the rim, which is exactly what a dial
  /// must never do.
  Offset _toCanvas(Offset g, Offset centre, double radius) {
    // Leave room for the ball's own radius, so it stays inside the ring.
    final limit = radius - 11;
    var dx = g.dx / _fullScale * radius;
    var dy = -g.dy / _fullScale * radius * _squash;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance > limit && distance > 0) {
      final scale = limit / distance;
      dx *= scale;
      dy *= scale;
    }
    return centre + Offset(dx, dy);
  }

  Offset _normalised(Offset at, Offset centre, double radius) {
    return Offset(
      (at.dx - centre.dx) / radius,
      (at.dy - centre.dy) / radius,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    Color color, {
    double size = 8,
  }) {
    _captionPainter(text, color, size).paint(canvas, at);
  }

  /// The same, but anchored by its right-hand edge - which is how a dimension
  /// label is placed against the line it belongs to, whatever it says.
  void _textRight(
    Canvas canvas,
    String text,
    Offset at,
    Color color, {
    double size = 8,
  }) {
    final painter = _captionPainter(text, color, size);
    painter.paint(canvas, Offset(at.dx - painter.width, at.dy));
  }

  TextPainter _captionPainter(String text, Color color, double size) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: gt7Caption(color: color, size: size),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(_GForcePainter old) => true;
}
