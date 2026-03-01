import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/daily_race.dart';
import 'package:gt7_companion/models/gtsh_race.dart';
import 'package:gt7_companion/services/dg_edge_service.dart';
import 'package:gt7_companion/services/gtsh_rank_service.dart';
import 'package:gt7_companion/repositories/sport_repository.dart';

class FakeDgEdgeService extends DgEdgeService {
  final List<DailyRaceSummary> items;
  FakeDgEdgeService(this.items) : super();

  @override
  Future<List<DailyRaceSummary>> fetchAllPages({int maxPages = 10}) async {
    return items;
  }
}

class FakeGtshRankService extends GtshRankService {
  final List<GtshRace> cards;
  FakeGtshRankService(this.cards) : super();

  @override
  Future<List<GtshRace>> fetchRunningCards({
    bool forceRefresh = false,
  }) async {
    return cards;
  }
}

void main() {
  group('SportRepository', () {
    test('merges items from both providers correctly', () async {
      // create matching summary & card
      final dg1 = DailyRaceSummary(
        id: '1',
        title: 'Daily A',
        url: 'url',
        trackName: 'TrackX',
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

      // dg only and gtsh only items
      final dg2 = DailyRaceSummary(
        id: '2',
        title: 'Daily B',
        url: 'url',
        trackName: 'SoloDG',
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

      final sport = SportRepositoryImpl(
        FakeDgEdgeService([dg1, dg2]),
        FakeGtshRankService([card1, card2]),
      );

      await sport.fetchDailyRaces();
      final list = sport.dailyRaces;

      expect(list.length, 3);

      // find merged entry
      final merged = list.firstWhere((e) => e.trackName == 'TrackX');
      expect(merged.dgEdge, equals(dg1));
      expect(merged.gtsh, equals(card1));

      final onlyDg = list.firstWhere((e) => e.trackName == 'SoloDG');
      expect(onlyDg.dgEdge, equals(dg2));
      expect(onlyDg.gtsh, isNull);

      final onlyGtsh = list.firstWhere((e) => e.trackName == 'SoloGTSh');
      expect(onlyGtsh.gtsh, equals(card2));
      expect(onlyGtsh.dgEdge, isNull);
    });
  });
}
