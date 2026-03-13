import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/services/dg_edge_service.dart';
import 'package:gt7_companion/services/gtsh_rank_service.dart';
import 'package:provider/provider.dart';

import 'package:gt7_companion/widgets/unified_daily_races_display.dart';
import 'package:gt7_companion/repositories/sport_repository.dart';
import 'package:gt7_companion/models/unified_daily_race.dart';
import 'package:gt7_companion/models/daily_race.dart';
import 'package:gt7_companion/models/gtsh_race.dart';

// minimal fake implementations to support repository-based ordering test
class FakeDgEdgeService extends DgEdgeService {
  final List<DailyRaceSummary> items;
  FakeDgEdgeService(this.items) : super();
  @override
  Future<List<DailyRaceSummary>> fetchDailiesPage(
    int page, {
    bool forceRefresh = false,
  }) async {
    if (page == 1) return items;
    return const [];
  }
}

class FakeGtshRankService extends GtshRankService {
  final List<GtshRace> items;
  FakeGtshRankService(this.items) : super();
  @override
  Future<List<GtshRace>> fetchRunningCards({bool forceRefresh = false}) async {
    return items;
  }
}

class FakeSportRepository extends ChangeNotifier implements SportRepository {
  final List<UnifiedDailyRace> items;
  bool _loading = false;
  String? _error;

  FakeSportRepository(this.items);

  @override
  List<UnifiedDailyRace> get dailyRaces => items;
  @override
  bool get isLoading => _loading;
  @override
  String? get error => _error;

  @override
  Future<void> fetchDailyRaces({bool forceRefresh = false}) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    _loading = false;
    notifyListeners();
  }
}

void main() {
  testWidgets('UnifiedDailyRacesDisplay shows up to 3 cards only', (
    tester,
  ) async {
    final combined = List.generate(5, (i) {
      if (i == 0) {
        final nullSummary = DailyRaceSummary(
          id: '0',
          title: 'Race ?0',
          url: 'https://example.com/race/0',
          trackName: null,
        );
        return UnifiedDailyRace.fromPair(nullSummary, null);
      }
      final summary = DailyRaceSummary(
        id: '${i + 1}',
        title: 'Race ${i + 1}',
        url: 'https://example.com/race/${i + 1}',
        trackName: 'Track${i + 1}',
        // no trackId to prevent network image fetch
      );
      return UnifiedDailyRace.fromPair(summary, null);
    });

    final fakeRepo = FakeSportRepository(combined);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SportRepository>.value(
          value: fakeRepo,
          child: const Scaffold(body: UnifiedDailyRacesDisplay()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // first combined entry has no track and should be dropped
    expect(find.text('Track2'), findsOneWidget);
    expect(find.text('Track3'), findsOneWidget);
    expect(find.text('Track4'), findsOneWidget);
    expect(find.text('Track5'), findsNothing);
  });

  test('UnifiedDailyRace.isUpcoming helper', () {
    final running = UnifiedDailyRace(
      dgEdge: DailyRaceSummary(
        id: '1',
        title: 'Run',
        url: 'u',
        trackName: 'Now',
        isActive: true,
        isEnded: false,
      ),
      gtsh: null,
      trackName: 'Now',
    );
    expect(running.isUpcoming, isFalse);

    final future = UnifiedDailyRace(
      dgEdge: DailyRaceSummary(
        id: '2',
        title: 'Future',
        url: 'u',
        trackName: 'Later',
        isActive: false,
        isEnded: false,
      ),
      gtsh: null,
      trackName: 'Later',
    );
    expect(future.isUpcoming, isTrue);

    final gtshNext = UnifiedDailyRace(
      dgEdge: null,
      gtsh: GtshRace(
        label: 'A',
        trackName: 'G',
        tyreCode: 'SM',
        status: 'next',
        pitStops: '-',
        bop: false,
        damage: '',
        startType: '',
        carSettings: false,
        wideFender: '',
      ),
      trackName: 'G',
    );
    expect(gtshNext.isUpcoming, isTrue);
  });

  testWidgets('future card shown before current card', (tester) async {
    // Use the real repository so sorting logic applies
    final currentSummary = DailyRaceSummary(
      id: '1',
      title: 'Now',
      url: 'u',
      trackName: 'Now',
      isActive: true,
      isEnded: false,
    );
    final futureSummary = DailyRaceSummary(
      id: '2',
      title: 'Future',
      url: 'u',
      trackName: 'Later',
      isActive: false,
      isEnded: false,
    );
    final dgService = FakeDgEdgeService([currentSummary, futureSummary]);
    final gtshService = FakeGtshRankService([]);
    final repo = SportRepositoryImpl(dgService, gtshService);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SportRepository>.value(
          value: repo,
          child: const Scaffold(body: UnifiedDailyRacesDisplay()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // verify ordering by x position
    final laterFinder = find.text('Later');
    final nowFinder = find.text('Now');
    expect(laterFinder, findsOneWidget);
    expect(nowFinder, findsOneWidget);
    final laterPos = tester.getTopLeft(laterFinder);
    final nowPos = tester.getTopLeft(nowFinder);
    expect(laterPos.dx, lessThan(nowPos.dx));
  });
}
