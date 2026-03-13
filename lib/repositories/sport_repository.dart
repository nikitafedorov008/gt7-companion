import 'package:flutter/foundation.dart';

import '../models/unified_daily_race.dart';
import '../models/daily_race.dart';
import '../models/gtsh_race.dart';
import '../services/dg_edge_service.dart';
import '../services/gtsh_rank_service.dart';

/// Abstract contract for a daily‑race repository. Allows multiple
/// implementations (network merge, cached, test stub, etc.).
abstract class SportRepository extends ChangeNotifier {
  /// Unified list of races combining both providers.
  List<UnifiedDailyRace> get dailyRaces;
  bool get isLoading;
  String? get error;

  /// Fetches and merges race data from underlying sources.
  Future<void> fetchDailyRaces({bool forceRefresh = false});
}

/// Default implementation that merges DG‑Edge and GTSh‑rank services.
class SportRepositoryImpl extends SportRepository {
  final DgEdgeService _dgEdge;
  final GtshRankService _gtsh;

  List<UnifiedDailyRace> _dailyRaces = [];
  bool _isLoading = false;
  String? _error;

  SportRepositoryImpl(this._dgEdge, this._gtsh);

  @override
  List<UnifiedDailyRace> get dailyRaces => _dailyRaces;
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
      final results = await Future.wait([
        _dgEdge.fetchDailiesPage(1),
        _gtsh.fetchRunningCards(forceRefresh: forceRefresh),
      ]);

      final dgItems = results[0] as List<DailyRaceSummary>;
      final gtshItems = results[1] as List<GtshRace>;
      debugPrint(
        'SportRepository: dg returned ${dgItems.length} items (page 1 only)',
      );
      debugPrint('SportRepository: gtsh returned ${gtshItems.length} items');

      _dailyRaces = _merge(dgItems, gtshItems);
      debugPrint('SportRepository: merged list size ${_dailyRaces.length}');
      _error = null;
    } catch (e) {
      _error = 'Failed to load daily races: $e';
      debugPrint('SportRepository error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<UnifiedDailyRace> _merge(
    List<DailyRaceSummary> dg,
    List<GtshRace> gtsh,
  ) {
    // Merge the upstream sources by pairing entries by index.  We intentionally
    // keep the complete list from each source so widgets that show "past" or
    // "upcoming" races have enough data to work with.
    final out = <UnifiedDailyRace>[];
    final maxLen = dg.length > gtsh.length ? dg.length : gtsh.length;

    for (var i = 0; i < maxLen; i++) {
      final dgItem = i < dg.length ? dg[i] : null;
      final gtshItem = i < gtsh.length ? gtsh[i] : null;
      final unified = UnifiedDailyRace.fromPair(dgItem, gtshItem);
      if (unified.trackName != null && unified.trackName!.isNotEmpty) {
        out.add(unified);
      }
    }

    // ensure upcoming/future races come first, then running/current, then past
    // (stable ordering keeps the upstream page order for items with the same
    // 'weight', preventing shuffling between future and current races).
    final weighted = out
        .asMap()
        .entries
        .map((e) => MapEntry(e.key, e.value))
        .toList();

    weighted.sort((a, b) {
      int weight(UnifiedDailyRace r) {
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

    return out;
  }
}
