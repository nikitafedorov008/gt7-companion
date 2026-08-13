import 'package:flutter/foundation.dart';

import '../models/daily_races/daily_race.dart';
import '../models/dg_edge/dg_edge_daily_race.dart';
import '../models/gtsh_rank/gtsh_daily_race.dart';
import '../services/dg_edge_service.dart';
import '../services/gtsh_rank_service.dart';

/// Abstract contract for a daily‑race repository. Allows multiple
/// implementations (network merge, cached, test stub, etc.).
abstract class SportRepository extends ChangeNotifier {
  /// Unified list of races combining both providers.
  List<DailyRace> get dailyRaces;
  bool get isLoading;
  String? get error;

  /// Fetches and merges race data from underlying sources.
  Future<void> fetchDailyRaces({bool forceRefresh = false});
}

/// Default implementation that merges DG‑Edge and GTSh‑rank services.
class SportRepositoryImpl extends SportRepository {
  final DgEdgeService _dgEdge;
  final GtshRankService _gtsh;

  List<DailyRace> _dailyRaces = [];
  bool _isLoading = false;
  String? _error;

  SportRepositoryImpl(this._dgEdge, this._gtsh);

  @override
  List<DailyRace> get dailyRaces => _dailyRaces;
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
      // DG‑Edge only needs first page; the widget that originally used
      // `fetchAllPages` was fetching everything, but the requirement changed
      // to show only the first page.  `fetchDailiesPage(1)` already performs
      // a single network call.
      debugPrint(
        'SportRepository: starting fetchDailyRaces (forceRefresh=$forceRefresh)',
      );

      List<DgEdgeDailyRace> dgItems = [];
      List<GtshDailyRace> gtshItems = [];
      String? dgError;
      String? gtshError;

      try {
        dgItems = await _dgEdge.fetchDailiesPage(1);
        debugPrint(
          'SportRepository: dg returned ${dgItems.length} items (page 1 only)',
        );
      } catch (e, st) {
        dgError = e.toString();
        debugPrint('SportRepository: failed to fetch DG-Edge races: $e\n$st');
      }

      try {
        gtshItems = await _gtsh.fetchDailyCards(forceRefresh: forceRefresh);
        debugPrint('SportRepository: gtsh returned ${gtshItems.length} items');
      } catch (e, st) {
        gtshError = e.toString();
        debugPrint('SportRepository: failed to fetch GTSh ranks: $e\n$st');
      }

      if (dgItems.isEmpty && gtshItems.isEmpty) {
        _dailyRaces = [];
        _error =
            'Failed to load daily races'
            '${dgError != null ? ' (DG-Edge: $dgError)' : ''}'
            '${gtshError != null ? ' (GTSh: $gtshError)' : ''}';
      } else {
        _dailyRaces = _merge(dgItems, gtshItems);
        debugPrint('SportRepository: merged list size ${_dailyRaces.length}');
        _error = null;
      }
    } catch (e) {
      _error = 'Failed to load daily races: $e';
      debugPrint('SportRepository error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Normalised pairing key for a race, used when no ranking id is available.
  ///
  /// Track names differ slightly between the sources — DG-Edge says
  /// "Grand Valley" where GTSh says "Grand Valley - Highway 1" — so only the
  /// segment before the first dash is compared.
  static String? _fallbackKey(String? label, String? track) {
    if (label == null || label.isEmpty) return null;
    if (track == null || track.isEmpty) return null;
    final base = track.split(' - ').first.trim().toLowerCase();
    if (base.isEmpty) return null;
    return '${label.toUpperCase()}|$base';
  }

  List<DailyRace> _merge(List<DgEdgeDailyRace> dg, List<GtshDailyRace> gtsh) {
    // Pair on the game's own board id, which both sites publish: DG-Edge as
    // `rankingid`, GTSh as `data-board` (e.g. p_rt_1014514_001). Pairing by
    // list position, as this used to do, matched unrelated races — the two
    // sources cover different numbers of weeks.
    final gtshByRankingId = <String, GtshDailyRace>{};
    final gtshByFallback = <String, GtshDailyRace>{};
    for (final g in gtsh) {
      final id = g.rankingId;
      if (id != null && id.isNotEmpty) {
        gtshByRankingId.putIfAbsent(id, () => g);
      }
      final key = _fallbackKey(g.label, g.trackName);
      if (key != null) gtshByFallback.putIfAbsent(key, () => g);
    }

    final out = <DailyRace>[];
    final pairedGtsh = <GtshDailyRace>{};

    for (final d in dg) {
      GtshDailyRace? match;
      final rankingId = d.rankingId;
      if (rankingId != null && rankingId.isNotEmpty) {
        match = gtshByRankingId[rankingId];
      }
      match ??= gtshByFallback[_fallbackKey(d.raceLetter, d.trackName) ?? ''];

      if (match != null) pairedGtsh.add(match);
      final unified = DailyRace.fromPair(d, match);
      if (unified.trackName != null && unified.trackName!.isNotEmpty) {
        out.add(unified);
      }
    }

    // GTSh cards with no DG-Edge counterpart still belong in the list — the
    // two sites do not always publish the same weeks.
    for (final g in gtsh) {
      if (pairedGtsh.contains(g)) continue;
      final unified = DailyRace.fromPair(null, g);
      if (unified.trackName != null && unified.trackName!.isNotEmpty) {
        out.add(unified);
      }
    }

    debugPrint(
      'SportRepository._merge: ${dg.length} dg + ${gtsh.length} gtsh -> '
      '${out.length} races (${pairedGtsh.length} paired)',
    );

    // ensure upcoming/future races come first, then running/current, then past
    // (stable ordering keeps the upstream page order for items with the same
    // 'weight', preventing shuffling between future and current races).
    final weighted = out
        .asMap()
        .entries
        .map((e) => MapEntry(e.key, e.value))
        .toList();

    weighted.sort((a, b) {
      int weight(DailyRace r) {
        if (r.isUpcoming) return 0;
        if (r.isActive) return 1;
        if (r.isPast) return 2;
        return 1;
      }

      final wa = weight(a.value);
      final wb = weight(b.value);
      if (wa != wb) return wa - wb;
      // preserve original order for items with the same weight
      return a.key - b.key;
    });

    return weighted.map((e) => e.value).toList();
  }
}
