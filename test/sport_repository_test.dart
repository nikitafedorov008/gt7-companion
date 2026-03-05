import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/daily_race.dart';
import 'package:gt7_companion/models/gtsh_race.dart';
import 'package:gt7_companion/models/unified_daily_race.dart';
import 'package:gt7_companion/services/dg_edge_service.dart';
import 'package:gt7_companion/services/gtsh_rank_service.dart';
import 'package:gt7_companion/repositories/sport_repository.dart';

class FakeDgEdgeService extends DgEdgeService {
  final List<DailyRaceSummary> items;
  FakeDgEdgeService(this.items) : super();

  @override
  Future<List<DailyRaceSummary>> fetchDailiesPage(
    int page, {
    bool forceRefresh = false,
  }) async {
    // we only ever ask for page=1 in the repo implementation
    if (page == 1) return items;
    return const [];
  }
}

class FakeGtshRankService extends GtshRankService {
  final List<GtshRace> cards;
  FakeGtshRankService(this.cards) : super();

  @override
  Future<List<GtshRace>> fetchRunningCards({bool forceRefresh = false}) async {
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

      // item lacking any track information should be ignored later
      final dgNull = DailyRaceSummary(
        id: 'nil',
        title:
            'Daily ?'
            'Unknown',
        url: 'url',
        trackName: null,
      );

      final sport = SportRepositoryImpl(
        FakeDgEdgeService([dg1, dg2, dgNull]),
        FakeGtshRankService([card1, card2]),
      );

      await sport.fetchDailyRaces();
      final list = sport.dailyRaces;

      // blank entry is dropped; we only pair by index so we'll get two
      // merged items (dgNull produces nothing).
      expect(list.length, 2);

      // index-based matching: first pair should contain dg1/card1
      expect(list[0].dgEdge, equals(dg1));
      expect(list[0].gtsh, equals(card1));
      expect(list[0].label, equals('A'));

      // second pair should be dg2/card2
      expect(list[1].dgEdge, equals(dg2));
      expect(list[1].gtsh, equals(card2));
    });

    // remove previous sorting test
  });
}
