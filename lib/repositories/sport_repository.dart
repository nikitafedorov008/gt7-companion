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
    // take up to first three entries from each source and pair them by index
    // (A/A, B/B, C/C).  Extra items beyond the third are ignored; entries
    // without a valid track name are filtered out.
    final topDg = dg.take(3).toList();
    final topGtsh = gtsh.take(3).toList();

    final out = <UnifiedDailyRace>[];
    final maxLen = topDg.length > topGtsh.length
        ? topDg.length
        : topGtsh.length;
    for (var i = 0; i < maxLen; i++) {
      final dgItem = i < topDg.length ? topDg[i] : null;
      final gtshItem = i < topGtsh.length ? topGtsh[i] : null;
      final unified = UnifiedDailyRace.fromPair(dgItem, gtshItem);
      if (unified.trackName != null && unified.trackName!.isNotEmpty) {
        out.add(unified);
      }
    }
    return out;
  }
}
