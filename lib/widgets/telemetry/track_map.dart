import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/telemetry/track_trace.dart';
import '../../theme/gt7_theme.dart';

/// Tip of the map plane used by the navigator view, in radians: about 43
/// degrees, which reads as a mini map tipped away from the camera.
const double kMapTilt = 0.75;

/// Draws the route the car has driven, the way a navigator draws a track: the
/// line comes from the coordinates in the telemetry packet, the car sits at the
/// end of it with its heading, and the colour of the line is the speed.
///
/// GT7 only ever reports the player's car, so there are no rivals and no
/// downloaded course geometry on this map - it is a trace, not a road.
class TrackMap extends StatefulWidget {
  const TrackMap({
    super.key,
    required this.trace,
    this.headingUp = false,
    this.colorBySpeed = true,
    this.padding = 10,
    this.showStartFinish = true,
    this.grid = true,
    this.showGhost = true,
    this.headingUpZoom = 2.6,
    this.tilt = 0,
  });

  final TrackTrace trace;

  /// Rotate the map so the car's heading points up (navigator style). When
  /// false the map stays north-up and the car's arrow turns instead.
  final bool headingUp;

  /// Colour the driven line by speed instead of a flat stroke.
  final bool colorBySpeed;

  final double padding;

  /// Mark where the lap in progress started.
  final bool showStartFinish;

  /// Faint metre grid, so distances on the map read as distances.
  final bool grid;

  /// Draw the fastest completed lap as a ghost under the current one.
  final bool showGhost;

  /// Magnification used in [headingUp] mode, where the car is centred and only
  /// the road around it is on screen.
  final double headingUpZoom;

  /// How far the map plane is tipped away from the camera, in radians. Zero is
  /// a flat top-down map; around 1.0 the far side of the circuit is
  /// foreshortened and further away, the way a game's mini map reads.
  final double tilt;

  @override
  State<TrackMap> createState() => _TrackMapState();
}

class _TrackMapState extends State<TrackMap> {
  int _cachedRevision = -1;
  Size _cachedSize = Size.zero;
  double _cachedTilt = 0;
  _MapGeometry? _geometry;

  /// Everything below is rebuilt only when a new point arrives or the widget
  /// changes size, never per frame.
  _MapGeometry? _geometryFor(Size size) {
    if (_geometry != null &&
        _cachedRevision == widget.trace.revision &&
        _cachedSize == size &&
        _cachedTilt == widget.tilt) {
      return _geometry;
    }
    if (!widget.trace.hasRoute || size.isEmpty) return _geometry = null;

    _cachedRevision = widget.trace.revision;
    _cachedSize = size;
    _cachedTilt = widget.tilt;
    return _geometry = _MapGeometry.build(
      trace: widget.trace,
      size: size,
      padding: widget.padding,
      tilt: widget.tilt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = _geometryFor(size);

        return CustomPaint(
          size: size,
          painter: _TrackMapPainter(
            geometry: geometry,
            trace: widget.trace,
            headingUp: widget.headingUp,
            colorBySpeed: widget.colorBySpeed,
            showStartFinish: widget.showStartFinish,
            grid: widget.grid,
            showGhost: widget.showGhost,
            padding: widget.padding,
            headingUpZoom: widget.headingUpZoom,
            tilt: widget.tilt,
          ),
        );
      },
    );
  }
}

/// The world-to-canvas transform plus the cached paths for one trace revision.
class _MapGeometry {
  _MapGeometry({
    required this.scale,
    required this.centerX,
    required this.centerZ,
    required this.tilt,
    required this.path,
    required this.ghost,
    required this.heat,
    required this.startFinish,
    required this.car,
    required this.bounds,
  });

  /// Pixels per metre, on the ground plane.
  final double scale;
  final double tilt;
  final double centerX;
  final double centerZ;
  final Path path;
  final Path ghost;
  final List<_HeatBucket> heat;
  final Offset? startFinish;
  final Offset car;
  final Rect bounds;

  static const List<Color> _ramp = [
    Color(0xFF3FB950), // slowest band: green
    Color(0xFF8FD44B),
    Color(0xFFE7CB3C), // yellow
    Color(0xFFF0883E), // orange
    Color(0xFFFA0F0B), // fastest band: red
  ];

  static _MapGeometry? build({
    required TrackTrace trace,
    required Size size,
    required double padding,
    required double tilt,
  }) {
    final bounds = trace.bounds;
    final spanX = math.max(bounds.width, 1.0);
    final spanZ = math.max(bounds.height, 1.0);
    final usableW = math.max(size.width - padding * 2, 1.0);
    final usableH = math.max(size.height - padding * 2, 1.0);
    // A tipped plane shows cos(tilt) of its depth, so the fit has to measure
    // the extent the way the camera sees it.
    final squash = math.cos(tilt).clamp(0.2, 1.0);
    final scale = math.min(usableW / spanX, usableH / (spanZ * squash));

    final centerX = bounds.left + spanX / 2;
    final centerZ = bounds.top + spanZ / 2;

    final path = Path();
    final heat = List.generate(_ramp.length, (_) => _HeatBucket());

    TraceSample? previous;
    for (final sample in trace.samples) {
      if (previous == null) {
        path.moveTo(sample.x, sample.z);
      } else {
        path.lineTo(sample.x, sample.z);
        // Speed bands are drawn as separate point pairs, which is what lets a
        // single polyline carry a colour per segment.
        heat[_band(sample.speed)]
            .add(previous.x, previous.z, sample.x, sample.z);
      }
      previous = sample;
    }

    final last = trace.samples.last;
    // The ghost: the fastest lap's own line, in world coordinates like the
    // rest, so it is transformed by the same matrix.
    final ghost = Path();
    var ghostStarted = false;
    for (final sample in trace.bestLapSamples) {
      if (!ghostStarted) {
        ghost.moveTo(sample.x, sample.z);
        ghostStarted = true;
      } else {
        ghost.lineTo(sample.x, sample.z);
      }
    }

    return _MapGeometry(
      scale: scale,
      centerX: centerX,
      centerZ: centerZ,
      tilt: tilt,
      path: path,
      ghost: ghost,
      heat: heat,
      startFinish: trace.hasRoute
          ? Offset(
              trace.samples[trace.currentLapStart].x,
              trace.samples[trace.currentLapStart].z,
            )
          : null,
      car: Offset(last.x, last.z),
      bounds: bounds,
    );
  }

  static int _band(double speed) {
    // Bands are wide enough to stay readable at a glance on a small panel.
    const edges = [60.0, 120.0, 180.0, 250.0];
    for (var i = 0; i < edges.length; i++) {
      if (speed < edges[i]) return i;
    }
    return edges.length;
  }

  static Color heatColor(int band) => _ramp[band.clamp(0, _ramp.length - 1)];

  /// The world-to-canvas transform.
  ///
  /// With no tilt this is a plain top-down map (x right, z down). With a tilt
  /// the ground plane is rotated away from the camera: the same matrix carries
  /// the foreshortening and a little perspective, so the far side of the
  /// circuit shrinks and leans back the way a game's mini map does.
  ///
  /// [spin] turns the *world* about [about] (the car, in navigator mode) before
  /// the camera tips it - the mini-map rotation - and [zoom] magnifies around
  /// the same point.
  Matrix4 worldMatrix(
    Size size, {
    double spin = 0,
    Offset? about,
    double zoom = 1,
    Offset? focus,
  }) {
    final centre = focus ?? Offset(size.width / 2, size.height / 2);
    final matrix = Matrix4.identity()
      ..translateByDouble(centre.dx, centre.dy, 0, 1);
    if (tilt != 0) {
      // Perspective has to read the depth the rotation is about to create, and
      // the sign puts the near edge (the bottom of the panel) closer to the
      // camera: the far side of the circuit shrinks.
      matrix.setEntry(3, 2, -0.0022);
    }
    matrix
      // Turning the plane away from the camera: the flip (-scale) keeps the
      // old top-down orientation, cos(tilt) is the foreshortening, and the
      // unrotated z the rotation creates becomes the depth.
      ..rotateX(tilt)
      ..scaleByDouble(scale * zoom, -scale * zoom, 1, 1);
    if (spin != 0) matrix.rotateZ(spin);
    final pivot = about ?? Offset(centerX, centerZ);
    matrix.translateByDouble(-pivot.dx, -pivot.dy, 0, 1);
    return matrix;
  }

  /// Projects a world coordinate to the canvas, perspective included.
  Offset toCanvas(
    Offset world,
    Size size, {
    double spin = 0,
    Offset? about,
    double zoom = 1,
    Offset? focus,
  }) =>
      MatrixUtils.transformPoint(
        worldMatrix(
          size,
          spin: spin,
          about: about,
          zoom: zoom,
          focus: focus,
        ),
        world,
      );
}

class _HeatBucket {
  final List<Offset> segments = [];

  void add(double x1, double z1, double x2, double z2) {
    segments
      ..add(Offset(x1, z1))
      ..add(Offset(x2, z2));
  }
}

class _TrackMapPainter extends CustomPainter {
  _TrackMapPainter({
    required this.geometry,
    required this.trace,
    required this.headingUp,
    required this.colorBySpeed,
    required this.showStartFinish,
    required this.grid,
    required this.showGhost,
    required this.padding,
    required this.headingUpZoom,
    required this.tilt,
  });

  final _MapGeometry? geometry;
  final TrackTrace trace;
  final bool headingUp;
  final bool colorBySpeed;
  final bool showStartFinish;
  final bool grid;
  final bool showGhost;
  final double padding;
  final double headingUpZoom;
  final double tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = this.geometry;

    if (grid) _paintGrid(canvas, size, geometry);
    if (geometry == null) return;

    // Navigator mode keeps the car centred and turns the *world* under it, so
    // the tilt stays a tilt: the plane is spun about its own vertical axis, not
    // the finished picture about the screen.
    final turned = headingUp && trace.hasRoute;
    final spin = turned ? (trace.heading + math.pi / 2) : 0.0;
    // A navigator puts the car low and leaves the panel to the road ahead.
    final focus = Offset(size.width / 2, size.height * 0.62);
    final matrix = geometry.worldMatrix(
      size,
      spin: spin,
      about: turned ? geometry.car : null,
      zoom: turned ? headingUpZoom : 1,
      focus: turned ? focus : null,
    );

    // In navigator mode the spin and the zoom were built around the car, so it
    // lands in the middle of the panel by construction.
    final carScreen =
        turned ? focus : geometry.toCanvas(geometry.car, size);

    canvas.save();
    canvas.transform(matrix.storage);

    // Casing first: a dark, slightly wider stroke under the route, which is
    // what makes a line read as a road on a map rather than as a scribble.
    canvas.drawPath(
      geometry.path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6 / geometry.scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: 0.55),
    );

    // The fastest lap of the session, in the HUD's purple, so the current line
    // can be compared against it corner by corner.
    if (showGhost) {
      canvas.drawPath(
        geometry.ghost,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7 / geometry.scale
          ..strokeCap = StrokeCap.round
          ..color = gt7Best.withValues(alpha: 0.85),
      );
    }

    // The history next, dim, so the lap in progress reads as the bright line.
    canvas.drawPath(
      geometry.path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 / geometry.scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = gt7TextMuted.withValues(alpha: 0.45),
    );

    if (colorBySpeed && trace.speedRange != null) {
      final range = trace.speedRange!;
      for (var band = 0; band < geometry.heat.length; band++) {
        final bucket = geometry.heat[band];
        if (bucket.segments.isEmpty) continue;
        canvas.drawPoints(
          ui.PointMode.lines,
          bucket.segments,
          Paint()
            ..strokeWidth = 1.8 / geometry.scale
            ..strokeCap = StrokeCap.round
            ..color = _MapGeometry.heatColor(band),
        );
      }
      if (range.$2 - range.$1 < 1) {
        // A car that has barely moved cannot be coloured by speed.
        canvas.drawPath(
          geometry.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 / geometry.scale
            ..color = gt7SlotA,
        );
      }
    } else {
      canvas.drawPath(
        geometry.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 / geometry.scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = gt7SlotA,
      );
    }

    if (showStartFinish && geometry.startFinish != null) {
      final start = geometry.startFinish!;
      canvas.drawCircle(
        start,
        2.2 / geometry.scale,
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: start,
          width: 5 / geometry.scale,
          height: 5 / geometry.scale,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6 / geometry.scale
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }

    canvas.restore();

    if (tilt != 0) _paintDepth(canvas, size);

    _paintCar(canvas, carScreen, size, geometry, matrix, turned, slip: trace.slipAngle ?? 0);
  }

  /// Screen angle of a world direction through the projection the route was
  /// drawn with: the tipped, spun plane foreshortens and turns it, so the car's
  /// arrow has to be measured the same way.
  double _projectedAngle(
    Matrix4 matrix,
    Offset origin,
    double worldAngle,
  ) {
    final a = MatrixUtils.transformPoint(matrix, origin);
    final b = MatrixUtils.transformPoint(
      matrix,
      Offset(
        origin.dx + math.cos(worldAngle),
        origin.dy + math.sin(worldAngle),
      ),
    );
    return math.atan2(b.dy - a.dy, b.dx - a.dx);
  }

  void _paintCar(
    Canvas canvas,
    Offset car,
    Size size,
    _MapGeometry geometry,
    Matrix4 matrix,
    bool turned, {
    required double slip,
  }) {
    // The trace reports a screen angle (atan2(-dz, dx)), so the world direction
    // behind it is (cos, -sin).
    double travelWorld(double screen) => -screen;
    final travelScreen = trace.hasRoute ? trace.heading : -math.pi / 2;
    final travel = turned
        ? -math.pi / 2
        : _projectedAngle(matrix, geometry.car, travelWorld(travelScreen));

    // When the packet's yaw could be scaled (see TrackTrace.bodyHeading) the
    // triangle is the car's *body*, turned by the slip angle away from the
    // direction it is actually travelling - so a drift is visible as the gap
    // between the two.
    final bodyHeading = trace.bodyHeading;
    final body = bodyHeading == null
        ? (turned ? -math.pi / 2 + slip : travel)
        : _projectedAngle(matrix, geometry.car, travelWorld(bodyHeading));
    final drifting = slip.abs() > 0.09; // ~5 degrees

    // Direction of travel: a thin tick, so the drift angle has a reference.
    if (bodyHeading != null) {
      canvas.save();
      canvas.translate(car.dx, car.dy);
      canvas.rotate(travel);
      canvas.drawLine(
        Offset.zero,
        const Offset(15, 0),
        Paint()
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.35),
      );
      canvas.restore();
    }

    canvas.save();
    canvas.translate(car.dx, car.dy);
    canvas.rotate(body);
    final arrow = Path()
      ..moveTo(7, 0)
      ..lineTo(-4, 5)
      ..lineTo(-4, -5)
      ..close();
    canvas.drawPath(
      arrow,
      Paint()
        ..color = drifting
            ? const Color(0xFFF0883E)
            : Colors.white.withValues(alpha: 0.92),
    );
    canvas.restore();

    canvas.drawCircle(
      car,
      1.8,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  /// Shades the far half of a tipped map: geometry alone says "squashed",
  /// shading says "further away".
  void _paintDepth(Canvas canvas, Size size) {
    final shade = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.05),
        Offset(0, size.height * 0.85),
        [
          Colors.black.withValues(alpha: 0.62),
          Colors.black.withValues(alpha: 0.0),
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shade);
  }

  void _paintGrid(Canvas canvas, Size size, _MapGeometry? geometry) {
    final paint = Paint()
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.045);

    if (geometry == null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = Colors.white.withValues(alpha: 0.05),
      );
      return;
    }

    // A grid every 100 m, measured from the track origin, so the map carries a
    // scale; it disappears once the map is too zoomed out for it to mean
    // anything.
    final step = 100 * geometry.scale;
    if (step < 6) return;

    final origin = geometry.toCanvas(Offset.zero, size);
    for (var x = origin.dx % step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = origin.dy % step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_TrackMapPainter old) {
    return old.geometry != geometry ||
        old.trace.revision != trace.revision ||
        old.headingUp != headingUp ||
        old.colorBySpeed != colorBySpeed ||
        old.showStartFinish != showStartFinish ||
        old.grid != grid ||
        old.showGhost != showGhost ||
        old.padding != padding ||
        old.headingUpZoom != headingUpZoom;
  }
}
