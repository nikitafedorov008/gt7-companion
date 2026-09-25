import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart' show immutable;

import 'telemetry_data.dart';

/// What the app can measure about a lap it has driven, for looking the circuit
/// up in the course database (see `TrackCatalog`).
@immutable
class TrackSignature {
  const TrackSignature({
    required this.lapDistance,
    required this.elevationRange,
    required this.corners,
  });

  /// Length of a completed lap, in metres, measured along the driven line.
  final double lapDistance;

  /// Highest minus lowest point of that lap, in metres.
  final double elevationRange;

  /// How many corners the shape has, counted from the curvature of the line.
  final int corners;
}

/// One recorded point of the route the car has driven.
class TraceSample {
  const TraceSample({
    required this.x,
    required this.z,
    required this.y,
    required this.speed,
    required this.brake,
    required this.lap,
    required this.time,
    required this.yaw,
    required this.fuel,
  });

  /// Track coordinates in metres: X/Z are the ground plane, Y is elevation.
  final double x;
  final double z;
  final double y;

  /// Speed in km/h at this point.
  final double speed;

  /// Brake pedal 0..1.
  final double brake;

  /// The lap this point belongs to, as the packet numbered it.
  final int lap;

  /// Time on the current lap in seconds.
  final double time;

  /// Fuel level in litres, as the packet reports it (0 for electric cars).
  final double fuel;

  /// The body yaw exactly as the packet reports it (rotation_y, documented as
  /// -1…1). Its scale is not published, so [TrackTrace] fits it against the
  /// direction of travel before anything is shown.
  final double yaw;

  /// Screen angle of the direction this sample was reached from, in radians.
  double travelFrom(TraceSample previous) =>
      math.atan2(-(z - previous.z), x - previous.x);
}

/// The route the car has driven, assembled from the positions GT7 reports in
/// every telemetry packet (packet "A", offsets 0x04/0x08/0x0C).
///
/// The packet only describes the player's car, so this is a track map built by
/// driving - there is no course geometry to download and no rivals on it.
///
/// Samples are thinned by distance, not by time: at 60 Hz a 300 km/h car moves
/// 1.4 m per packet, which would be ~25 000 points for one Nürburgring lap.
/// Keeping one point every [minStep] metres draws the same line with a few
/// thousand points.
class TrackTrace {
  TrackTrace({this.minStep = 2.5, this.teleportDistance = 500});

  /// Minimum distance between two recorded points, in metres.
  final double minStep;

  /// A gap larger than this means a new session or another track, so the trace
  /// starts over instead of drawing a line across the world.
  final double teleportDistance;

  final List<TraceSample> _samples = [];
  List<TraceSample>? _view;

  double _minX = 0, _maxX = 0, _minZ = 0, _maxZ = 0, _minY = 0, _maxY = 0;
  double _distance = 0;
  int _laps = 0;
  int _lastLap = -1;
  int _revision = 0;
  double _heading = 0;
  static const int _fitWindow = 240;
  int _fitRevision = -1;
  ({double scale, double offset, bool confident})? _fit;

  /// The recorded points, oldest first.
  List<TraceSample> get samples => _view ??= UnmodifiableListView(_samples);

  int get length => _samples.length;

  /// Bumped every time a point is appended or the trace is cleared; use it to
  /// invalidate anything derived from [samples] (paths, caches, pictures).
  int get revision => _revision;

  /// Top-down extent of everything recorded, in track metres. `left/right` are
  /// X, `top/bottom` are Z.
  Rect get bounds => Rect.fromLTRB(_minX, _minZ, _maxX, _maxZ);

  /// Distance covered since the trace started, in metres.
  double get distance => _distance;

  double? _lapStartFuel;
  final List<double> _lapFuel = [];
  final List<int> _lapStartIndex = [];
  final List<int> _lapDurationMs = [];
  double _lapStartDistance = 0;
  double _lastLapDistance = 0;

  /// Length of the last completed lap, measured along the driven line.
  double get lastLapDistance => _lastLapDistance;

  /// The fastest completed lap in this trace, as an index into the lap list
  /// (0 = the first lap that was closed). Null until a lap has a time.
  int? get bestLap {
    if (_lapDurationMs.isEmpty) return null;
    var best = 0;
    var found = false;
    for (var i = 0; i < _lapDurationMs.length; i++) {
      final duration = _lapDurationMs[i];
      if (duration <= 0) continue;
      if (!found || duration < _lapDurationMs[best]) {
        best = i;
        found = true;
      }
    }
    return found ? best : null;
  }

  /// How far into the current lap the car is, in metres.
  double get currentLapDistance => _distance - _lapStartDistance;

  /// Samples of the fastest lap, oldest first - the line to draw as a ghost.
  List<TraceSample> get bestLapSamples {
    final best = this.bestLap;
    if (best == null || best >= _lapStartIndex.length) return const [];
    final (start, end) = _lapRange(best);
    if (end <= start) return const [];
    return _samples.sublist(start, end);
  }

  /// The sample range of the [index]-th completed lap. A lap closes when the
  /// packet's lap counter changes, so the entry at `_lapStartIndex[index]` is
  /// where the lap after it began.
  (int, int) _lapRange(int index) {
    final start = index == 0 ? 0 : _lapStartIndex[index - 1];
    final end = index < _lapStartIndex.length ? _lapStartIndex[index] : _samples.length;
    return (start, end);
  }

  /// The difference between the current lap and the fastest completed one at
  /// the same point on the track, in seconds. Negative means the car is ahead.
  ///
  /// This is the honest version of the delta the game shows: it compares two
  /// laps of *this* session at the *same* distance, so it needs no reference
  /// data from anywhere else. Null until a lap has been completed and the
  /// current one has some distance in it.
  double? deltaToBest() {
    final best = this.bestLap;
    if (best == null || best >= _lapStartIndex.length) return null;

    // Cache the best lap's (distance, time) pairs: only the best lap has to be
    // walked, and only when it changes.
    if (_bestCurveLap != best || _bestCurveRevision != _revision) {
      _bestCurveLap = best;
      _bestCurveRevision = _revision;
      _bestCurveDistance = [];
      _bestCurveTime = [];
      final (start, end) = _lapRange(best);
      var travelled = 0.0;
      for (var i = start; i < end; i++) {
        if (i > start) {
          travelled += _distanceBetween(
            _samples[i - 1].x,
            _samples[i - 1].z,
            _samples[i].x,
            _samples[i].z,
          );
        }
        _bestCurveDistance!.add(travelled);
        _bestCurveTime!.add(_samples[i].time);
      }
    }

    final distance = currentLapDistance;
    final curve = _bestCurveDistance;
    final times = _bestCurveTime;
    if (curve == null || times == null || curve.length < 3) return null;
    if (distance <= 20) return null;
    // The two laps are measured independently, so the current one can be a few
    // metres past the end of the best one: compare at the last point it has
    // rather than dropping the delta exactly when it matters.
    final target = math.min(distance, curve.last - 0.5);

    // Interpolate the best lap's time at this distance.
    var low = 0;
    var high = curve.length - 1;
    while (low < high - 1) {
      final mid = (low + high) ~/ 2;
      if (curve[mid] <= target) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final span = curve[high] - curve[low];
    final t = span <= 0 ? 0.0 : (target - curve[low]) / span;
    final bestTime = times[low] + (times[high] - times[low]) * t;
    return _samples.last.time - bestTime;
  }

  int? _bestCurveLap;
  int _bestCurveRevision = -1;
  List<double>? _bestCurveDistance;
  List<double>? _bestCurveTime;

  void _closeLap(double fuelNow, int lastLapMs) {
    _lapDurationMs.add(lastLapMs);
    // Where the lap that just began starts: the two lists stay parallel, so
    // _lapDurationMs[k] always describes the samples of _lapRange(k).
    _lapStartIndex.add(_samples.length);
    final lapDistance = _distance - _lapStartDistance;
    if (lapDistance > 200) _lastLapDistance = lapDistance;
    _lapStartDistance = _distance;
    final start = _lapStartFuel;
    if (start == null) return;
    final used = start - fuelNow;
    // Only plausible laps: a refuel or a reset makes the difference nonsense.
    if (used <= 0 || used > 100) return;
    _lapFuel.add(used);
    if (_lapFuel.length > 5) _lapFuel.removeAt(0);
  }

  /// Fuel used on the last completed lap, in litres. Null until two laps of
  /// fuel data exist.
  double? get lastLapFuel => _lapFuel.isEmpty ? null : _lapFuel.last;

  /// Typical fuel per lap, the median of the last few completed laps. Null
  /// until there is at least one.
  double? get fuelPerLap {
    if (_lapFuel.isEmpty) return null;
    final sorted = [..._lapFuel]..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// How many more laps the tank holds at [fuelPerLap]. Null without a
  /// measurement or when the car uses no fuel (electric).
  double? get lapsRemaining {
    final perLap = fuelPerLap;
    if (perLap == null || perLap <= 0.01 || _samples.isEmpty) return null;
    return _samples.last.fuel / perLap;
  }

  /// Elevation covered, in metres.
  double get elevationRange => _samples.isEmpty ? 0 : _maxY - _minY;

  /// How many laps this trace covers, counting the one in progress: a driver
  /// who has just crossed the line for lap 2 sees 2.
  int get laps => _laps;

  /// Heading of the car in *screen* radians (atan2 of the last few metres of
  /// travel), which is what the map rotates by - no packet angle convention is
  /// assumed.
  double get heading => _heading;

  /// Whether there is enough of a route to draw.
  bool get hasRoute => _samples.length >= 2;

  void clear() {
    _samples.clear();
    _minX = _maxX = _minZ = _maxZ = _minY = _maxY = 0;
    _distance = 0;
    _laps = 0;
    _lastLap = -1;
    _heading = 0;
    _lapStartIndex.clear();
    _lapDurationMs.clear();
    _lapFuel.clear();
    _bestCurveLap = null;
    _fit = null;
    _fitRevision = -1;
    _revision++;
  }

  /// Appends the position in [telemetry] if the car has moved far enough since
  /// the previous point. Returns true when a point was recorded.
  bool add(TelemetryData telemetry) {
    final x = telemetry.posX;
    final z = telemetry.posZ;
    final y = telemetry.posY;
    if (!x.isFinite || !z.isFinite || !y.isFinite) return false;
    // The packet reports zeros until the game puts a car on a track.
    if (x == 0 && z == 0) return false;

    final last = _samples.isEmpty ? null : _samples.last;
    if (last != null) {
      final step = _distanceBetween(last.x, last.z, x, z);
      if (step < minStep) return false;
      if (step > teleportDistance) {
        clear();
        return add(telemetry);
      }
      _distance += step;
      _heading = math.atan2(-(z - last.z), x - last.x);
    }

    if (telemetry.currentLap != _lastLap) {
      if (_lastLap != -1) _closeLap(telemetry.fuel, telemetry.lastLapTime);
      _lastLap = telemetry.currentLap;
      _laps++;
      _lapStartFuel = telemetry.fuel;
    }

    _samples.add(
      TraceSample(
        x: x,
        z: z,
        y: y,
        speed: telemetry.speed,
        brake: telemetry.brake,
        lap: telemetry.currentLap,
        time: telemetry.curLapTime,
        yaw: telemetry.rotYaw,
        fuel: telemetry.fuel,
      ),
    );

    if (_samples.length == 1) {
      _minX = _maxX = x;
      _minZ = _maxZ = z;
      _minY = _maxY = y;
    } else {
      _minX = math.min(_minX, x);
      _maxX = math.max(_maxX, x);
      _minZ = math.min(_minZ, z);
      _maxZ = math.max(_maxZ, z);
      _minY = math.min(_minY, y);
      _maxY = math.max(_maxY, y);
    }

    _revision++;
    return true;
  }

  /// Index of the first sample of the lap currently being driven.
  int get currentLapStart {
    if (_samples.isEmpty) return 0;
    final lap = _samples.last.lap;
    for (var i = _samples.length - 1; i >= 0; i--) {
      if (_samples[i].lap != lap) return i + 1;
    }
    return 0;
  }

  /// Speed range across the recorded route, in km/h. Null while the car has
  /// not moved.
  (double min, double max)? get speedRange {
    if (_samples.isEmpty) return null;
    var lo = _samples.first.speed;
    var hi = lo;
    for (final sample in _samples) {
      lo = math.min(lo, sample.speed);
      hi = math.max(hi, sample.speed);
    }
    return (lo, hi);
  }

  // ---------------------------------------------------------------------------
  // Drift: where the car points versus where it is going
  // ---------------------------------------------------------------------------

  /// The packet's yaw is documented only as "-1 -> 1", so its unit is unknown
  /// *when 0x1C..0x2B are three angles*. If they are a unit quaternion the body
  /// angle is exact and no fit is needed - see [exactBodyHeading].
  ///
  /// (Continues below.)
  /// What is known is how the car moved: the direction of travel between two
  /// samples. While the car is not sliding the two agree, so the ratio between
  /// a change in travel direction and the matching change in yaw *is* the scale
  /// - and a fit on differences needs no offset either.
  ///
  /// Returns null until enough clean samples have been seen; the fit is cached
  /// and only refreshed when the trace changes.
  ({double scale, double offset, bool confident})? get _yawFit {
    // A quaternion rotation block makes this measurement unnecessary.
    if (_exactBodyHeading != null) return null;
    if (_fitRevision == _revision) return _fit;

    final samples = _samples;
    // The fit is a property of the track/car, not of one lap, so it is
    // recomputed rarely: every step of the window below.
    // Enough of a drive to measure anything: the window is a maximum, not a
    // minimum, so a short stint still gets an answer.
    if (samples.length < 40) return _fit = null;

    // Direction of travel for each sample, straight from the positions.
    final start = math.max(1, samples.length - _fitWindow);
    final travel = <double>[];
    for (var i = start; i < samples.length; i++) {
      travel.add(_wrap(samples[i].travelFrom(samples[i - 1])));
    }

    // A change in the direction of travel over a change in the reported yaw is
    // the unit of the yaw field - differences cancel the unknown offset. The
    // car has to be moving for either to mean anything.
    final scales = <double>[];
    for (var i = 1; i < travel.length; i++) {
      final sample = samples[start + i];
      if (sample.yaw.isNaN || sample.speed < 25) continue;
      final travelDelta = _wrap(travel[i] - travel[i - 1]);
      final yawDelta = sample.yaw - samples[start + i - 1].yaw;
      // Gentle corners are worth keeping: a 100 m radius taken at 55 m/s only
      // turns 0.025 rad between two samples, and a fit that ignores those never
      // gets enough evidence on a fast lap.
      if (yawDelta.abs() < 0.002 || travelDelta.abs() < 0.005) continue;
      if (travelDelta.abs() > 1.2) continue; // a jump, not a corner
      scales.add(travelDelta / yawDelta);
    }

    if (scales.length < 25) {
      _fitRevision = _revision;
      return _fit = null;
    }

    // Trim before measuring: a slide, a kerb or a knock makes a handful of
    // ratios meaningless, and they are always the minority. Keep what agrees
    // with the median and describe only that.
    scales.sort();
    final rough = scales[scales.length ~/ 2];
    final kept = rough == 0
        ? scales
        : scales
            .where((value) => (value - rough).abs() <= rough.abs() * 0.35)
            .toList();
    if (kept.length < 25) {
      _fitRevision = _revision;
      return _fit = null;
    }
    final scale = kept[kept.length ~/ 2];
    final spread = kept[(kept.length * 3) ~/ 4] - kept[kept.length ~/ 4];

    // The offset is the world direction the car points at yaw 0, taken as the
    // median over the window so a drift cannot drag it.
    final offsets = <double>[];
    for (var i = start; i < samples.length; i++) {
      final sample = samples[i];
      if (sample.yaw.isNaN || sample.speed < 25) continue;
      offsets.add(_wrap(i == 0 ? 0 : samples[i].travelFrom(samples[i - 1]) -
          scale * sample.yaw));
    }
    offsets.sort();
    final offset = offsets.isEmpty ? 0.0 : offsets[offsets.length ~/ 2];

    _fitRevision = _revision;
    return _fit = (
      scale: scale,
      offset: offset,
      // Confidence comes from the trimmed set being both big and tight: 25
      // good ratios out of a window, spread inside a quarter of the value.
      confident: kept.length >= 30 && spread.abs() < scale.abs() * 0.25,
    );
  }

  /// Whether the packet's yaw scale has been measured well enough to trust the
  /// drift angle. GT7 documents rotation_y only as -1…1, so this is measured
  /// from the drive instead of assumed.
  bool get hasDriftData =>
      _exactBodyHeading != null || (_yawFit?.confident ?? false);

  /// Body heading taken from a unit quaternion (packet rotation block), in the
  /// same screen radians the map uses. Exact, and available immediately.
  double? _exactBodyHeading;

  /// Set by the recorder when the packet's rotation block turned out to be a
  /// quaternion. In that case this is the exact body angle.
  set exactBodyHeading(double? value) => _exactBodyHeading = value;

  /// Where the car's body is pointing, in the same screen radians the map uses.
  /// Comes from the quaternion when there is one, otherwise from the fitted yaw
  /// scale once it is confident.
  double? get bodyHeading {
    if (_exactBodyHeading != null) return _exactBodyHeading;
    final fit = _yawFit;
    if (fit == null || !fit.confident || _samples.isEmpty) return null;
    final yaw = _samples.last.yaw;
    if (yaw.isNaN) return null;
    return _wrap(fit.scale * yaw + fit.offset);
  }

  /// The angle between where the car points and where it is going: zero while
  /// it grips, tens of degrees in a drift. Positive means the car is sliding
  /// with its nose to the left of the corner.
  double? get slipAngle {
    final body = bodyHeading;
    if (body == null || _samples.length < 2) return null;
    final travel = _samples.last.travelFrom(_samples[_samples.length - 2]);
    return _wrap(travel - body);
  }

  /// The measured unit of the packet's yaw field, in radians per packet unit.
  /// Around pi means the field is -1…1 for -180°…180°, which is what the
  /// community layout implies. Null when the rotation block is a quaternion.
  double? get yawScale => _yawFit?.scale;

  /// Everything about one lap that can be compared with a course database:
  /// its length, the height it covers and how many corners its shape has.
  ///
  /// Null until a lap has been driven.
  TrackSignature? get lapSignature {
    if (_samples.isEmpty || _lastLapDistance <= 200) return null;
    final lastLap = samples.where((s) => s.lap == samples.last.lap).toList();
    if (lastLap.length < 20) return null;

    var lowest = lastLap.first.y;
    var highest = lowest;
    for (final sample in lastLap) {
      lowest = math.min(lowest, sample.y);
      highest = math.max(highest, sample.y);
    }

    return TrackSignature(
      lapDistance: _lastLapDistance,
      elevationRange: highest - lowest,
      corners: _countCorners(lastLap),
    );
  }

  /// Counts corners the way a driver would: stretches where the line is turning
  /// in one direction and then the other. Nobody publishes how Polyphony counts
  /// them, so this is deliberately coarse - it is a tie-breaker for the track
  /// lookup, not a claim about the circuit.
  int _countCorners(List<TraceSample> lap) {
    // Curvature per metre, smoothed over roughly forty metres.
    final curvature = <double>[];
    for (var i = 1; i < lap.length; i++) {
      final step = _distanceBetween(
        lap[i - 1].x,
        lap[i - 1].z,
        lap[i].x,
        lap[i].z,
      );
      if (step <= 0) {
        curvature.add(0);
        continue;
      }
      final inAngle = math.atan2(
        -(lap[i].z - lap[i - 1].z),
        lap[i].x - lap[i - 1].x,
      );
      final outAngle = i + 1 < lap.length
          ? math.atan2(
              -(lap[i + 1].z - lap[i].z),
              lap[i + 1].x - lap[i].x,
            )
          : inAngle;
      curvature.add(_wrap(outAngle - inAngle) / step);
    }

    const window = 8;
    final smoothed = <double>[];
    for (var i = 0; i < curvature.length; i++) {
      var sum = 0.0;
      var count = 0;
      for (var k = -window; k <= window; k++) {
        final index = i + k;
        if (index < 0 || index >= curvature.length) continue;
        sum += curvature[index];
        count++;
      }
      smoothed.add(count == 0 ? 0 : sum / count);
    }

    // A corner is a stretch turning harder than a 200 m radius.
    const threshold = 1 / 200;
    var corners = 0;
    var inCorner = false;
    var length = 0;
    var direction = 0;

    for (var i = 0; i < smoothed.length; i++) {
      final value = smoothed[i];
      final turning = value.abs() > threshold;
      final sign = value > 0 ? 1 : -1;

      if (turning && (!inCorner || sign != direction)) {
        // A new corner, or a chicane where the direction flips.
        if (inCorner && length >= 12) corners++;
        inCorner = true;
        length = 0;
        direction = sign;
      } else if (turning) {
        length++;
      } else if (inCorner) {
        if (length >= 12) corners++;
        inCorner = false;
        length = 0;
      }
    }
    if (inCorner && length >= 12) corners++;

    return corners;
  }

  static double _wrap(double angle) {
    var a = angle;
    while (a > math.pi) {
      a -= 2 * math.pi;
    }
    while (a < -math.pi) {
      a += 2 * math.pi;
    }
    return a;
  }

  static double _distanceBetween(double x1, double z1, double x2, double z2) {
    final dx = x2 - x1;
    final dz = z2 - z1;
    return math.sqrt(dx * dx + dz * dz);
  }
}
