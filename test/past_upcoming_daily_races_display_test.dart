import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gt7_companion/widgets/past_daily_races_display.dart';
import 'package:gt7_companion/widgets/upcoming_daily_races_display.dart';
import 'package:gt7_companion/repositories/sport_repository.dart';
import 'package:gt7_companion/models/unified_daily_race.dart';
import 'package:gt7_companion/models/daily_race.dart';
import 'package:gt7_companion/models/gtsh_race.dart';

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
  testWidgets('UpcomingDailyRacesDisplay shows only upcoming races', (
    tester,
  ) async {
    final future = UnifiedDailyRace(
      dgEdge: DailyRaceSummary(
        id: 'future',
        title: 'Future',
        url: 'u',
        trackName: 'FutureTrack',
        isActive: false,
        isEnded: false,
      ),
      gtsh: null,
      trackName: 'FutureTrack',
    );
    final current = UnifiedDailyRace(
      dgEdge: DailyRaceSummary(
        id: 'current',
        title: 'Current',
        url: 'u',
        trackName: 'CurrentTrack',
        isActive: true,
        isEnded: false,
      ),
      gtsh: null,
      trackName: 'CurrentTrack',
    );
    final past = UnifiedDailyRace(
      dgEdge: DailyRaceSummary(
        id: 'past',
        title: 'Past',
        url: 'u',
        trackName: 'PastTrack',
        isActive: false,
        isEnded: true,
      ),
      gtsh: null,
      trackName: 'PastTrack',
    );

    final repo = FakeSportRepository([future, current, past]);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SportRepository>.value(
          value: repo,
          child: const Scaffold(body: UpcomingDailyRacesDisplay()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('FutureTrack'), findsOneWidget);
    expect(find.text('CurrentTrack'), findsNothing);
    expect(find.text('PastTrack'), findsNothing);
  });

  testWidgets(
    'UpcomingDailyRacesDisplay ignores GTSh "next" status when DG‑Edge indicates running',
    (tester) async {
      final currentButMismatched = UnifiedDailyRace(
        dgEdge: DailyRaceSummary(
          id: 'current',
          title: 'Current',
          url: 'u',
          trackName: 'CurrentTrack',
          isActive:
              false, // upstream may be wrong, but status indicates running
          isEnded: false,
          status: 'RUNNING',
        ),
        gtsh: GtshRace(
          label: 'A',
          trackName: 'CurrentTrack',
          tyreCode: 'RM',
          status: 'next',
          carImage: null,
          fuelMultiplier: null,
          tyrewearMultiplier: null,
          pitStops: '',
          bop: false,
          damage: '',
          startType: '',
          carSettings: false,
          wideFender: '',
        ),
        trackName: 'CurrentTrack',
      );

      final repo = FakeSportRepository([currentButMismatched]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SportRepository>.value(
            value: repo,
            child: const Scaffold(body: UpcomingDailyRacesDisplay()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CurrentTrack'), findsNothing);
    },
  );

  testWidgets(
    'UpcomingDailyRacesDisplay ignores DG‑Edge PENDING if isActive is true',
    (tester) async {
      final pending = UnifiedDailyRace(
        dgEdge: DailyRaceSummary(
          id: 'pending',
          title: 'Pending',
          url: 'u',
          trackName: 'PendingTrack',
          isActive: true,
          isEnded: false,
          status: 'PENDING',
        ),
        gtsh: null,
        trackName: 'PendingTrack',
      );

      final repo = FakeSportRepository([pending]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SportRepository>.value(
            value: repo,
            child: const Scaffold(body: UpcomingDailyRacesDisplay()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PendingTrack'), findsNothing);
    },
  );

  testWidgets('PastDailyRacesDisplay shows only past races', (tester) async {
    final future = UnifiedDailyRace(
      dgEdge: DailyRaceSummary(
        id: 'future',
        title: 'Future',
        url: 'u',
        trackName: 'FutureTrack',
        isActive: false,
        isEnded: false,
      ),
      gtsh: null,
      trackName: 'FutureTrack',
    );
    final current = UnifiedDailyRace(
      dgEdge: DailyRaceSummary(
        id: 'current',
        title: 'Current',
        url: 'u',
        trackName: 'CurrentTrack',
        isActive: true,
        isEnded: false,
      ),
      gtsh: null,
      trackName: 'CurrentTrack',
    );
    final past = UnifiedDailyRace(
      dgEdge: DailyRaceSummary(
        id: 'past',
        title: 'Past',
        url: 'u',
        trackName: 'PastTrack',
        isActive: false,
        isEnded: true,
      ),
      gtsh: null,
      trackName: 'PastTrack',
    );

    final repo = FakeSportRepository([future, current, past]);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SportRepository>.value(
          value: repo,
          child: const Scaffold(body: PastDailyRacesDisplay()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PastTrack'), findsOneWidget);
    expect(find.text('FutureTrack'), findsNothing);
    expect(find.text('CurrentTrack'), findsNothing);
  });
}
