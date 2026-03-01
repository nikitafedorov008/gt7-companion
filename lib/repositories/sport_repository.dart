import 'package:flutter/foundation.dart';

import '../models/combined_daily_race.dart';
import '../models/daily_race.dart';
import '../models/gtsh_race.dart';
import '../services/dg_edge_service.dart';
import '../services/gtsh_rank_service.dart';

/// Abstract contract for a daily‑race repository. Allows multiple
/// implementations (network merge, cached, test stub, etc.).
abstract class SportRepository extends ChangeNotifier {
  List<CombinedDailyRace> get dailyRaces;
  bool get isLoading;
  String? get error;

  /// Fetches and merges race data from underlying sources.
  Future<void> fetchDailyRaces({bool forceRefresh = false});
}

/// Default implementation that merges DG‑Edge and GTSh‑rank services.
class SportRepositoryImpl extends SportRepository {
  final DgEdgeService _dgEdge;
  final GtshRankService _gtsh;

  List<CombinedDailyRace> _dailyRaces = [];
  bool _isLoading = false;
  String? _error;

  SportRepositoryImpl(this._dgEdge, this._gtsh);

  @override
  List<CombinedDailyRace> get dailyRaces => _dailyRaces;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get error => _error;

  @override
  Future<void> fetchDailyRaces({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // DG‑Edge does not support forceRefresh on fetchAllPages
      final results = await Future.wait([
        _dgEdge.fetchAllPages(),
        _gtsh.fetchRunningCards(forceRefresh: forceRefresh),
      ]);

      final dgItems = results[0] as List<DailyRaceSummary>;
      final gtshItems = results[1] as List<GtshRace>;

      _dailyRaces = _merge(dgItems, gtshItems);
      _error = null;
    } catch (e) {
      _error = 'Failed to load daily races: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<CombinedDailyRace> _merge(
    List<DailyRaceSummary> dg,
    List<GtshRace> gtsh,
  ) {
    final map = <String, CombinedDailyRace>{};

    String keyForLabelAndTrack(String? label, String? track) {
      if (label == null || track == null) return track ?? '';
      return '${label.toUpperCase()}_${track.toLowerCase()}';
    }

    for (final item in dg) {
      final labelMatch = RegExp(
        r'Daily\s+([A-Z])',
        caseSensitive: false,
      ).firstMatch(item.title);
      final label = labelMatch?.group(1)?.toUpperCase();
      final key = keyForLabelAndTrack(label, item.trackName);
      map[key] = CombinedDailyRace(dgEdge: item, gtsh: null);
    }

    for (final card in gtsh) {
      final key = keyForLabelAndTrack(card.label, card.trackName);
      final existing = map[key];
      if (existing != null) {
        map[key] = CombinedDailyRace(dgEdge: existing.dgEdge, gtsh: card);
      } else {
        map[key] = CombinedDailyRace(dgEdge: null, gtsh: card);
      }
    }

    final out = map.values.toList();
    // sort by track name then label for determinism
    out.sort((a, b) {
      final ta = a.trackName ?? '';
      final tb = b.trackName ?? '';
      final cmp = ta.compareTo(tb);
      if (cmp != 0) return cmp;
      return (a.label ?? '').compareTo(b.label ?? '');
    });
    return out;
  }
}
