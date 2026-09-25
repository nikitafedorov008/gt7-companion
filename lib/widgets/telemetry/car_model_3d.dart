import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A miniature 3D car, drawn from boxes and real face normals.
///
/// This is not a drawing of a car, it is a very small renderer: eight vertices
/// per box, a rotation built from the attitude the packet reports, an
/// orthographic camera looking down at an angle, faces painted back to front,
/// and each face shaded by how it meets a light. The point of doing it properly
/// is that the car then *moves* correctly: a corner rolls the body onto its
/// outside wheels, braking pitches the nose down, and both are the numbers GT7
/// sends rather than an animation someone invented.
///
/// The wheels are a separate group from the body, because that is how a car
/// behaves: the body leans on its springs while the wheels stay flat on the
/// road.
class CarModel3D {
  const CarModel3D._();

  /// Render the car with its centre at [centre].
  ///
  /// [metresToPixels] sets the size: a 4.5 m car at 24 px/m is about 108 px
  /// long. [yaw] turns the car about its own vertical axis (radians, screen
  /// convention: 0 means the nose points right), [roll] and [pitch] are its
  /// attitude in radians, and [cameraTilt] is how far the camera looks down on
  /// it - about 0.95 rad is a three-quarter view from above, 1.45 is almost
  /// straight down.
  ///
  /// [opacity] below 1 draws the car as a glass shell: the far side is kept
  /// instead of being culled, so the body reads as a volume with an inside
  /// rather than a cut-out.
  ///
  /// [wheelColours] tints each tyre and paints the patch of ground it stands on,
  /// in the order of [wheels]: null leaves a wheel alone, which is what tarmac
  /// does. That is how the surface readout of the motion panel reaches the car
  /// itself - a wheel on grass is red in both places.
  ///
  /// Each front wheel steers about **its own** vertical axis, and the two may
  /// differ: GT7 reports the two front wheel angles separately in packet `C`,
  /// which is the Ackermann geometry - the inner wheel turns sharper. Rotating
  /// both about one axis instead would swing the wheels sideways like a cart
  /// and slide them forward and back.
  static void paint(
    Canvas canvas, {
    required Offset centre,
    required double metresToPixels,
    double yaw = 0,
    double roll = 0,
    double pitch = 0,
    double cameraTilt = 0.95,
    double steeringLeft = 0,
    double steeringRight = 0,
    List<Color?>? wheelColours,
    Color body = const Color(0xFFE8ECEF),
    double opacity = 1.0,
    bool groundShadow = true,
    bool outline = true,
  }) {
    final view = _View(cameraTilt, metresToPixels, centre);

    // Local frame: x to the car's right, y up, and **forward is -z** - the
    // right-handed convention, the same one a camera looks down. It matters:
    // with the nose on +z the whole car is a mirror image, which is what made
    // the wheels appear to steer away from the corner. The shapes are
    // extrusions rather than boxes: a rounded outline at the bottom, a tapered
    // one at the top, which gives a body its nose, shoulders and tail instead
    // of four square corners.
    // Contact patches first: the ground each tyre stands on, tinted by its
    // surface, drawn under the car so the tyres sit on top of it.
    final wheelBasis = wheelBasisFor(yaw);

    if (wheelColours != null) {
      for (var i = 0; i < wheels.length && i < wheelColours.length; i++) {
        final colour = wheelColours[i];
        if (colour == null) continue;
        _paintContactPatch(
            canvas,
            view,
            wheelBasis,
            wheels[i],
            colour: colour,
          steering: wheels[i].front
              ? -(wheels[i].centre.x < 0 ? steeringLeft : steeringRight)
              : 0,
        );
      }
    }

    // The wheels are built from one list, and the "rides on the road" flag
    // lives in the loop that walks it - not in four separate literals, where
    // one of them can quietly go missing (the rear-left wheel did, and spent a
    // day climbing with the body).
    final parts = <_Part>[
      for (var i = 0; i < wheels.length; i++)
        _Part(
          _Prism.cylinder(
            centre: _V3(
              wheels[i].centre.x,
              wheels[i].centre.y,
              wheels[i].centre.z,
            ),
            radius: wheels[i].radius,
            width: wheels[i].width,
            // A tyre on kerb, grass or snow takes that colour with it, and is
            // lit more strongly than a plain black one: the whole point is to
            // be seen at a glance, and a tinted tyre at the usual tyre shade
            // comes out a muddy maroon nobody can read on a dial.
            colour: wheelColours != null &&
                    i < wheelColours.length &&
                    wheelColours[i] != null
                ? Color.lerp(_tyre, wheelColours[i], 0.78)!
                : _tyre,
            shade: wheelColours != null && i < wheelColours.length &&
                    wheelColours[i] != null
                ? 0.85
                : 0.35,
          ),
          steering: wheels[i].front
              ? -(wheels[i].centre.x < 0 ? steeringLeft : steeringRight)
              : 0,
          onGround: true,
        ),
      // Body: a low, tapered shell, then the shoulders, then the rear wing.
      _Part(
        _Prism.rounded(
          // Narrower than the track on purpose: the tyres stand proud of the
          // body, which is both how a racing car looks and the only way a
          // surface colour painted on a tyre can be seen at all.
          bottom: const _Outline(width: 1.66, length: 4.4, radius: 0.5, y: 0.0),
          top: const _Outline(width: 1.5, length: 4.1, radius: 0.56, y: 0.62),
          colour: body,
        ),
      ),
      _Part(
        _Prism.rounded(
          bottom: const _Outline(width: 1.46, length: 3.5, radius: 0.44, y: 0.62, centreZ: 0.15),
          top: const _Outline(width: 1.24, length: 2.1, radius: 0.4, y: 1.06, centreZ: 0.35),
          colour: _windscreen,
          shade: 1.05,
        ),
      ),
      _Part(
        _Prism.rounded(
          bottom: const _Outline(width: 1.7, length: 0.34, radius: 0.12, y: 0.95, centreZ: 2.0),
          top: const _Outline(width: 1.7, length: 0.34, radius: 0.12, y: 1.05, centreZ: 2.0),
          colour: _windscreen,
          shade: 1.1,
        ),
      ),
    ];

    // The ground shadow is part of the picture: without it the car floats.
    final translucent = opacity < 0.999;

    if (groundShadow) {
      final shadow = _shadow(canvas, view, metresToPixels);
      if (shadow != null) {
        canvas.drawPath(
          shadow,
          Paint()
            ..color = Colors.black.withValues(
              alpha: translucent ? 0.28 : 0.45,
            ),
        );
      }
    }

    final faces = <_Face>[];

    // Wheels get the yaw and the steering but never the lean; the body gets all
    // three, because that is what a car on its springs does.
    final bodyBasis = _Basis(yaw: yaw, roll: roll, pitch: pitch);

    for (final part in parts) {
      faces.addAll(
        part.prism.faces(
          // Wheels ride on the road whatever the body is doing; only the body
          // leans and pitches. Tying this to the steering angle instead - as it
          // was - left the front wheels climbing with the body on a straight
          // and dropping back to the road once the wheel turned.
          part.onGround ? wheelBasis : bodyBasis,
          view,
          steer: part.steering,
          light: _light,
          // Wheels read better a little more solid than the glass body.
          opacity: part.onGround || translucent == false
              ? translucent
                  ? (opacity + 0.25).clamp(0.0, 1.0)
                  : 1.0
              : opacity,
          cull: !translucent,
        ),
      );
    }

    faces.sort((a, b) => a.depth.compareTo(b.depth)); // far first

    final fill = Paint()..style = PaintingStyle.fill;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = translucent ? 0.9 : 0.7
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: translucent ? 0.22 : 0.0);

    for (final face in faces) {
      fill.color = translucent
          ? face.colour.withValues(alpha: face.opacity)
          : face.colour;
      canvas.drawPath(face.path, fill);
      if (outline || translucent) canvas.drawPath(face.path, edge);
    }

  }

  /// The basis the wheels and their patches share.
  static _Basis wheelBasisFor(double yaw) =>
      _Basis(yaw: yaw, roll: 0, pitch: 0);

  /// The patch of ground a tyre stands on, tinted by the surface under it.
  ///
  /// Drawn as a rectangle in the wheel's own frame - so it turns with the
  /// steering, exactly as the tyre does - and laid flat on the road, which is
  /// what puts the motion panel's surface readout onto the car itself.
  static void _paintContactPatch(
    Canvas canvas,
    _View view,
    _Basis basis,
    ({
      String name,
      ({double x, double y, double z}) centre,
      double radius,
      double width,
      bool front,
    }) wheel, {
    required Color colour,
    required double steering,
  }) {
    final corners = _patchCorners(view, basis, wheel, steering);

    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    // A dark base first, so the colour reads against the dial's grid, then the
    // surface as a strong fill with an edge. All of it goes down before the
    // car: a patch outline drawn afterwards reads as if it were on the roof.
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );
    canvas.drawPath(
      path,
      Paint()..color = colour.withValues(alpha: 0.5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = colour,
    );
  }

  /// The four corners of a tyre's patch, in screen space, wound round the
  /// rectangle. Public so the geometry can be checked without a canvas.
  static List<Offset> contactPatchCorners({
    required Offset centre,
    required double metresToPixels,
    required double yaw,
    required int wheelIndex,
    double steering = 0,
    double cameraTilt = 0.95,
  }) {
    final view = _View(cameraTilt, metresToPixels, centre);
    return _patchCorners(
      view,
      wheelBasisFor(yaw),
      wheels[wheelIndex.clamp(0, wheels.length - 1)],
      steering,
    );
  }

  static List<Offset> _patchCorners(
    _View view,
    _Basis basis,
    ({
      String name,
      ({double x, double y, double z}) centre,
      double radius,
      double width,
      bool front,
    }) wheel,
    double steering,
  ) {
    // Slightly proud of the tyre so the colour shows around it, and 2 cm off
    // the road so it never fights the ground shadow for the same pixels.
    final halfWidth = wheel.width * 0.95;
    final halfLength = wheel.radius * 1.2;
    final cs = math.cos(steering), ss = math.sin(steering);

    Offset corner(double dx, double dz) {
      // Rotate about the wheel's own centre - a patch does not swing around
      // the car any more than the wheel does - then drop it onto the road.
      final x = dx * cs - dz * ss;
      final z = dx * ss + dz * cs;
      return view.project(
        _V3(wheel.centre.x + x, 0.02, wheel.centre.z + z),
        basis,
      );
    }

    return [
      corner(-halfWidth, -halfLength),
      corner(halfWidth, -halfLength),
      corner(halfWidth, halfLength),
      corner(-halfWidth, halfLength),
    ];
  }

  /// A soft ellipse under the car, sized to the footprint.
  static Path? _shadow(Canvas canvas, _View view, double scale) {
    const length = 4.4;
    const width = 1.9;
    final corners = <Offset>[
      for (final dz in [-length / 2, length / 2])
        for (final dx in [-width / 2, width / 2])
          view.project(_V3(dx, 0.02, dz), const _Basis.identity()),
    ];
    if (corners.length != 4) return null;
    var minX = corners.first.dx, maxX = minX, minY = corners.first.dy, maxY = minY;
    for (final corner in corners) {
      minX = math.min(minX, corner.dx);
      maxX = math.max(maxX, corner.dx);
      minY = math.min(minY, corner.dy);
      maxY = math.max(maxY, corner.dy);
    }
    return Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset((minX + maxX) / 2, (minY + maxY) / 2 + scale * 0.18),
          width: (maxX - minX) * 1.05,
          height: (maxY - minY) * 1.5,
        ),
      );
  }

  /// Where a point in the car's own frame lands on the canvas, using the very
  /// same projection the model is drawn with.
  ///
  /// [local] is in metres: x to the car's right, y up, z back (the nose is at
  /// negative z). [onGround] mirrors how the parts are placed and matters for
  /// the answer: a wheel keeps the car's heading and position but **not** its
  /// lean, so its projection ignores [roll] and [pitch], while the body takes
  /// both.
  ///
  /// Exposed for markers and for checking the geometry in tests; the painter
  /// uses it internally.
  static Offset project({
    required Offset centre,
    required double metresToPixels,
    required ({double x, double y, double z}) local,
    double yaw = 0,
    double roll = 0,
    double pitch = 0,
    double cameraTilt = 0.95,
    bool onGround = false,
  }) {
    final basis = _Basis(
      yaw: yaw,
      roll: onGround ? 0 : roll,
      pitch: onGround ? 0 : pitch,
    );
    return _View(cameraTilt, metresToPixels, centre).project(
      _V3(local.x, local.y, local.z),
      basis,
    );
  }

  /// Every wheel, in one place: the painter builds its geometry from this list,
  /// so a test that walks it is walking the car. Front is -z, right is +x.
  static const List<({
    String name,
    ({double x, double y, double z}) centre,
    double radius,
    double width,
    bool front,
  })> wheels = [
    (
      name: 'front-left',
      centre: frontLeftWheel,
      radius: 0.34,
      width: 0.34,
      front: true,
    ),
    (
      name: 'front-right',
      centre: frontRightWheel,
      radius: 0.34,
      width: 0.34,
      front: true,
    ),
    (
      name: 'rear-left',
      centre: rearLeftWheel,
      radius: 0.35,
      width: 0.36,
      front: false,
    ),
    (
      name: 'rear-right',
      centre: rearRightWheel,
      radius: 0.35,
      width: 0.36,
      front: false,
    ),
  ];

  /// The centre of the front-left wheel, in the car's own frame.
  static const ({double x, double y, double z}) frontLeftWheel =
      (x: -0.80, y: 0.34, z: -1.35);
  static const ({double x, double y, double z}) frontRightWheel =
      (x: 0.80, y: 0.34, z: -1.35);
  static const ({double x, double y, double z}) rearLeftWheel =
      (x: -0.80, y: 0.35, z: 1.32);
  static const ({double x, double y, double z}) rearRightWheel =
      (x: 0.80, y: 0.35, z: 1.32);

  /// A corner of the body's roof, for checking how the body moves.
  static const ({double x, double y, double z}) bodyRoofRight =
      (x: 0.89, y: 0.62, z: -2.05);

  static const Color _tyre = Color(0xFF1B1E22);
  static const Color _windscreen = Color(0xFF5A6470);
  static final _V3 _light = _V3(-0.35, 0.86, 0.36).normalised;
}

// ---------------------------------------------------------------------------
// Just enough linear algebra to render a box
// ---------------------------------------------------------------------------

class _V3 {
  const _V3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;

  _V3 get normalised {
    final length = math.sqrt(x * x + y * y + z * z);
    if (length < 1e-9) return const _V3(0, 1, 0);
    return _V3(x / length, y / length, z / length);
  }

  _V3 operator +(_V3 other) => _V3(x + other.x, y + other.y, z + other.z);

  double dot(_V3 other) => x * other.x + y * other.y + z * other.z;
}

/// The car's own orientation: yaw about its up axis, roll about its long axis,
/// pitch about its lateral axis.
class _Basis {
  _Basis({this.yaw = 0, this.roll = 0, this.pitch = 0});

  const _Basis.identity()
      : yaw = 0,
        roll = 0,
        pitch = 0;

  final double yaw;
  final double roll;
  final double pitch;

  /// Rotates a car-local point into world axes.
  _V3 apply(_V3 point) {
    // Pitch: nose up/down, about the car's right axis.
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final y1 = point.y * cp - point.z * sp;
    final z1 = point.y * sp + point.z * cp;

    // Roll: lean, about the car's long axis.
    final cr = math.cos(roll), sr = math.sin(roll);
    final x2 = point.x * cr - y1 * sr;
    final y2 = point.x * sr + y1 * cr;

    // Yaw: which way the car points, about the world's up axis.
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final x3 = x2 * cy - z1 * sy;
    final z3 = x2 * sy + z1 * cy;

    return _V3(x3, y2, z3);
  }
}

/// The camera: an orthographic view from above and behind, so the car reads as
/// a solid object rather than a plan.
class _View {
  _View(this.tilt, this.scale, this.centre);

  final double tilt;
  final double scale;
  final Offset centre;

  /// World point → canvas, given the car's basis.
  Offset project(_V3 point, _Basis basis) {
    final rotated = basis.apply(point);
    final ct = math.cos(tilt), st = math.sin(tilt);
    // Rotate about X: the ground plane tips towards the camera.
    final y = rotated.y * ct - rotated.z * st;
    // Screen: x right, y down; the depth decides only the painter's order.
    return centre + Offset(rotated.x * scale, -y * scale);
  }

  /// Depth of a point: larger is further from the camera.
  double depth(_V3 point, _Basis basis) {
    final rotated = basis.apply(point);
    final ct = math.cos(tilt), st = math.sin(tilt);
    return rotated.y * st + rotated.z * ct;
  }

  /// Camera-space normal of a face, for shading.
  _V3 normal(_V3 localNormal, _Basis basis) {
    final rotated = basis.apply(localNormal);
    final ct = math.cos(tilt), st = math.sin(tilt);
    return _V3(rotated.x, rotated.y * ct - rotated.z * st, rotated.y * st + rotated.z * ct)
        .normalised;
  }
}

/// One piece of the car: a shape, and how far that piece steers.
///
/// The angle belongs to the piece, not to the car, because every wheel turns
/// about its own axis - and because the two front wheels really do differ.
class _Part {
  const _Part(this.prism, {this.steering = 0, this.onGround = false});

  final _Prism prism;
  final double steering;

  /// True for the wheels: they keep the car's heading but never take its lean,
  /// because a car rolls on its springs while the tyres stay flat on the road.
  final bool onGround;
}

/// A silhouette at a given height: the cross-section an extrusion is built from.
class _Outline {
  const _Outline({
    required this.width,
    required this.length,
    required this.radius,
    required this.y,
    this.centreZ = 0,
  });

  final double width;
  final double length;
  final double radius;
  final double y;
  final double centreZ;

  /// The outline as points, running clockwise seen from above. Corners are
  /// arcs, so the shape has no square edges to give it away.
  ///
  /// Each corner sweeps the quadrant that faces *away* from the shape: the
  /// front-right one runs from the nose round to the right flank. Sweeping the
  /// inward quadrant instead - which is what this did at first - makes every
  /// edge dish inwards, and a car whose nose and tail are concave reads as a
  /// tent, not a body.
  List<_V3> points({int perCorner = 4}) {
    final halfWidth = width / 2 - radius;
    final halfLength = length / 2 - radius;
    final points = <_V3>[];

    void corner(double cx, double cz, double from) {
      for (var i = 0; i <= perCorner; i++) {
        final angle = from + (math.pi / 2) * (i / perCorner);
        points.add(
          _V3(
            cx + math.cos(angle) * radius,
            y,
            centreZ + cz + math.sin(angle) * radius,
          ),
        );
      }
    }

    // Nose is -z. Front-right: nose → right flank. Then round the car.
    corner(halfWidth, -halfLength, -math.pi / 2); // front right
    corner(halfWidth, halfLength, 0); // rear right
    corner(-halfWidth, halfLength, math.pi / 2); // rear left
    corner(-halfWidth, -halfLength, math.pi); // front left
    return points;
  }
}

/// An extruded shape: an outline at the bottom, one at the top, and the sides
/// between them. The two outlines may differ, which is what makes a taper.
class _Prism {
  const _Prism({
    required this.bottom,
    required this.top,
    required this.colour,
    this.shade = 1.0,
  });

  /// A tapered rounded box - the car's body and shoulders.
  factory _Prism.rounded({
    required _Outline bottom,
    required _Outline top,
    required Color colour,
    double shade = 1.0,
  }) {
    return _Prism(
      bottom: bottom.points(),
      top: top.points(),
      colour: colour,
      shade: shade,
    );
  }

  /// A cylinder lying on the car's lateral axis - a wheel.
  factory _Prism.cylinder({
    required _V3 centre,
    required double radius,
    required double width,
    required Color colour,
    double shade = 1.0,
    int segments = 12,
  }) {
    List<_V3> ring(double x) => [
          for (var i = 0; i < segments; i++)
            _V3(
              centre.x + x,
              centre.y + math.cos(i / segments * 2 * math.pi) * radius,
              centre.z + math.sin(i / segments * 2 * math.pi) * radius,
            ),
        ];

    return _Prism(
      bottom: ring(-width / 2),
      top: ring(width / 2),
      colour: colour,
      shade: shade,
    );
  }

  final List<_V3> bottom;
  final List<_V3> top;
  final Color colour;
  final double shade;

  List<_Face> faces(
    _Basis basis,
    _View view, {
    required double steer,
    required _V3 light,
    double opacity = 1.0,
    bool cull = true,
  }) {
    // Steering turns the shape about **its own** vertical axis: the pivot is
    // the shape's centre, so a wheel spins in place instead of orbiting the
    // car. Rotating about the car's axis would swing it out sideways and slide
    // it forwards, which is what a cart axle does, not a steering rack.
    final cs = math.cos(steer), ss = math.sin(steer);
    var pivotX = 0.0, pivotZ = 0.0;
    for (final point in bottom) {
      pivotX += point.x;
      pivotZ += point.z;
    }
    pivotX /= bottom.length;
    pivotZ /= bottom.length;

    _V3 steerPoint(_V3 point) {
      if (steer == 0) return point;
      final dx = point.x - pivotX;
      final dz = point.z - pivotZ;
      return _V3(
        pivotX + dx * cs - dz * ss,
        point.y,
        pivotZ + dx * ss + dz * cs,
      );
    }

    final bottomRing = bottom.map(steerPoint).toList();
    final topRing = top.map(steerPoint).toList();
    final count = bottomRing.length;
    final faces = <_Face>[];

    void addPolygon(List<_V3> ring, _V3 normal, bool isTop) {
      final path = Path();
      for (var i = 0; i < ring.length; i++) {
        final at = view.project(ring[i], basis);
        if (i == 0) {
          path.moveTo(at.dx, at.dy);
        } else {
          path.lineTo(at.dx, at.dy);
        }
      }
      path.close();

      var cx = 0.0, cy = 0.0, cz = 0.0;
      for (final point in ring) {
        cx += point.x;
        cy += point.y;
        cz += point.z;
      }
      final centroid = _V3(cx / ring.length, cy / ring.length, cz / ring.length);

      final worldNormal = view.normal(normal, basis);
      final away = worldNormal.z < -0.05;
      if (cull && away) return;

      final lambert = math.max(0.0, worldNormal.dot(light));
      final brightness = (0.22 + 0.78 * lambert) * shade;

      faces.add(
        _Face(
          path: path,
          colour: _brighten(colour, brightness),
          depth: view.depth(centroid, basis),
          opacity: (opacity * (away ? 0.55 : 1.0)).clamp(0.0, 1.0),
        ),
      );
      // A polygon as a path is fine for painting, but the normal of a tapered
      // face is not constant; using the centroid keeps it close enough at this
      // size, which is the trade a miniature renderer makes.
      // ignore: unused_local_variable
      final unused = isTop;
    }

    // Caps.
    addPolygon(topRing, const _V3(0, 1, 0), true);
    addPolygon(bottomRing, const _V3(0, -1, 0), false);

    // Sides: one quad per pair of neighbouring points.
    for (var i = 0; i < count; i++) {
      final j = (i + 1) % count;
      final a = bottomRing[i];
      final b = bottomRing[j];
      final c = topRing[j];
      final d = topRing[i];

      // Average the two edge normals, so the shading follows the curve.
      final edge = _V3(b.x - a.x, b.y - a.y, b.z - a.z);
      final up = _V3(0, 1, 0);
      final normal = _V3(
        edge.y * up.z - edge.z * up.y,
        edge.z * up.x - edge.x * up.z,
        edge.x * up.y - edge.y * up.x,
      ).normalised;

      final path = Path();
      final quad = [a, b, c, d];
      for (var k = 0; k < quad.length; k++) {
        final at = view.project(quad[k], basis);
        if (k == 0) {
          path.moveTo(at.dx, at.dy);
        } else {
          path.lineTo(at.dx, at.dy);
        }
      }
      path.close();

      final centroid = _V3(
        (a.x + b.x + c.x + d.x) / 4,
        (a.y + b.y + c.y + d.y) / 4,
        (a.z + b.z + c.z + d.z) / 4,
      );

      final worldNormal = view.normal(normal, basis);
      final away = worldNormal.z < -0.05;
      if (cull && away) continue;

      final lambert = math.max(0.0, worldNormal.dot(light));
      final brightness = (0.22 + 0.78 * lambert) * shade;

      faces.add(
        _Face(
          path: path,
          colour: _brighten(colour, brightness),
          depth: view.depth(centroid, basis),
          opacity: (opacity * (away ? 0.55 : 1.0)).clamp(0.0, 1.0),
        ),
      );
    }

    return faces;
  }
}

/// Scales a colour's brightness, keeping its hue.
Color _brighten(Color base, double brightness) {
  return Color.fromARGB(
    255,
    (base.r * 255 * brightness).clamp(0, 255).round(),
    (base.g * 255 * brightness).clamp(0, 255).round(),
    (base.b * 255 * brightness).clamp(0, 255).round(),
  );
}

class _Face {
  _Face({
    required this.path,
    required this.colour,
    required this.depth,
    this.opacity = 1.0,
  });

  final Path path;
  final Color colour;
  final double depth;
  final double opacity;
}
