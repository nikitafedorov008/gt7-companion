import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gt7_companion/widgets/unified_daily_races_display.dart';
import 'package:gt7_companion/repositories/sport_repository.dart';
import 'package:gt7_companion/services/dg_edge_service.dart';
import 'package:gt7_companion/services/gtsh_rank_service.dart';
import 'package:gt7_companion/models/daily_race.dart';
import 'package:gt7_companion/models/gtsh_race.dart';
import 'package:gt7_companion/models/unified_daily_race.dart';

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

void main() {
  testWidgets(
    'UnifiedDailyRacesDisplay shows merged data when using real repo',
    (tester) async {
      // prepare DG and GTSh items with overlapping track
      final dg1 = DailyRaceSummary(
        id: '1',
        title: 'Daily A',
        url: 'url',
        trackName: 'TrackX',
      );
      final dg2 = DailyRaceSummary(
        id: '2',
        title: 'Daily B',
        url: 'url',
        trackName: 'SoloDG',
      );
      final card1 = GtshRace(
        label: 'A',
        trackName: 'TrackX',
        tyreCode: 'SS',
        pitStops: '-',
        bop: true,
        damage: 'Light',
        startType: 'Grid',
        carSettings: false,
        wideFender: 'No',
      );
      final card2 = GtshRace(
        label: 'C',
        trackName: 'SoloGTSh',
        tyreCode: 'RH',
        pitStops: '-',
        bop: false,
        damage: 'None',
        startType: 'Rolling',
        carSettings: true,
        wideFender: 'Yes',
      );

      final dgService = FakeDgEdgeService([dg1, dg2]);
      final gtshService = FakeGtshRankService([card1, card2]);
      final repo = SportRepositoryImpl(dgService, gtshService);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<DgEdgeService>.value(value: dgService),
              ChangeNotifierProvider<GtshRankService>.value(value: gtshService),
              ChangeNotifierProvider<SportRepository>.value(value: repo),
            ],
            child: const Scaffold(body: UnifiedDailyRacesDisplay()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // pairing by index gives two merged entries; SoloDG name comes from
      // DG and SoloGTSh should not appear as separate card because it's paired
      // with dg2.
      expect(find.text('TrackX'), findsOneWidget);
      expect(find.text('SoloDG'), findsOneWidget);
      expect(find.text('SoloGTSh'), findsNothing);
    },
  );
}
