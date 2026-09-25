import 'dart:convert' show jsonDecode;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/telemetry/track_trace.dart';

/// One circuit from the community course database.
@immutable
class TrackInfo {
  const TrackInfo({
    required this.id,
    required this.name,
    required this.length,
    this.corners,
    this.elevation,
    this.longestStraight,
    this.oval = false,
    this.reverse = false,
    this.category = '',
  });

  final String id;
  final String name;

  /// Lap length in metres, as the database records it.
  final int length;
  final int? corners;
  final double? elevation;
  final int? longestStraight;
  final bool oval;
  final bool reverse;
  final String category;
}

/// The result of comparing a driven lap with the database.
@immutable
class TrackMatch {
  const TrackMatch({
    required this.track,
    required this.confidence,
    required this.candidates,
    this.ambiguousWith,
  });

  final TrackInfo track;

  /// 0..1: how much of the available evidence agrees.
  final double confidence;

  /// How many circuits were close enough to be considered at all.
  final int candidates;

  /// Another circuit that fits almost as well, when there is one. GT7 sends no
  /// track id, so two layouts of the same circuit (or two similar lengths) can
  /// be indistinguishable from one lap.
  final TrackInfo? ambiguousWith;

  bool get isConfident => confidence >= 0.6 && ambiguousWith == null;
}

/// Names the circuit from the lap the app measured.
///
/// GT7's packet has **no track id** - the community asked for years and it was
/// never added - so the only way to say where the car is, is to measure the lap
/// and look it up. The database is `assets/tracks/tracks.json`, generated from
/// ddm999/gt7info's `course.csv` by `tools/fetch_gt7_tracks.py`.
///
/// It is inference, not telemetry, so it only ever speaks when the evidence is
/// strong: a length inside 6%, an elevation span and a corner count that agree,
/// and no second circuit fitting nearly as well.
class TrackCatalog extends ChangeNotifier {
  static const String _asset = 'assets/tracks/tracks.json';

  /// How far the measured lap length may be from the recorded one.
  static const double _lengthTolerance = 0.06;

  Map<String, TrackInfo> _tracks = const {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  int get trackCount => _tracks.length;

  Future<void> load() async {
    if (_isLoaded) return;
    try {
      final raw = await rootBundle.loadString(_asset);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _tracks = decoded.map((id, value) {
        final track = value as Map<String, dynamic>;
        return MapEntry(
          id,
          TrackInfo(
            id: id,
            name: (track['name'] as String?) ?? '',
            length: (track['length'] as num?)?.toInt() ?? 0,
            corners: (track['corners'] as num?)?.toInt(),
            elevation: (track['elevation'] as num?)?.toDouble(),
            longestStraight: (track['straight'] as num?)?.toInt(),
            oval: track['oval'] == true,
            reverse: track['reverse'] == true,
            category: (track['category'] as String?) ?? '',
          ),
        );
      }).map((_, track) => MapEntry(track.id, track));
      _isLoaded = true;
    } catch (error) {
      debugPrint('TrackCatalog: could not load the course database: $error');
    } finally {
      notifyListeners();
    }
  }

  /// The best fitting circuit for [signature], or null when nothing is close
  /// enough to be worth claiming.
  TrackMatch? identify(TrackSignature signature) {
    if (!_isLoaded || signature.lapDistance <= 200) return null;

    final scored = <({TrackInfo track, double penalty})>[];
    for (final track in _tracks.values) {
      if (track.length <= 0) continue;
      final lengthError =
          (track.length - signature.lapDistance).abs() / track.length;
      if (lengthError > _lengthTolerance) continue;

      var penalty = lengthError * 0.55;
      var weight = 0.55;

      final elevation = track.elevation;
      if (elevation != null && elevation > 0 && signature.elevationRange > 0) {
        final error =
            (elevation - signature.elevationRange).abs() / elevation;
        penalty += error.clamp(0.0, 1.0) * 0.25;
        weight += 0.25;
      }

      final corners = track.corners;
      if (corners != null && corners > 0 && signature.corners > 0) {
        final error = (corners - signature.corners).abs() / corners;
        penalty += error.clamp(0.0, 1.0) * 0.20;
        weight += 0.20;
      }

      scored.add((track: track, penalty: penalty / weight));
    }

    if (scored.isEmpty) return null;
    scored.sort((a, b) => a.penalty.compareTo(b.penalty));

    // A 15% penalty leaves nothing: the lap is simply not in the database, or
    // it is a layout the database does not carry.
    const rejectAbove = 0.15;
    final best = scored.first;
    if (best.penalty > rejectAbove) return null;

    final runnerUp = scored.length > 1 ? scored[1] : null;
    final ambiguous = runnerUp != null &&
            (runnerUp.penalty - best.penalty) < 0.03 &&
            runnerUp.track.name != best.track.name
        ? runnerUp.track
        : null;

    return TrackMatch(
      track: best.track,
      confidence: (1 - best.penalty / rejectAbove).clamp(0.0, 1.0),
      candidates: scored.length,
      ambiguousWith: ambiguous,
    );
  }
}
