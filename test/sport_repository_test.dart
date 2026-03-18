import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/dg_edge/dg_edge_daily_race.dart';
import 'package:gt7_companion/models/gtsh_rank/gtsh_daily_race.dart';
import 'package:gt7_companion/services/dg_edge_service.dart';
import 'package:gt7_companion/services/gtsh_rank_service.dart';
import 'package:gt7_companion/repositories/sport_repository.dart';

class FakeDgEdgeService extends DgEdgeService {
  final List<DgEdgeDailyRace> items;
  FakeDgEdgeService(this.items) : super();

  @override
  Future<List<DgEdgeDailyRace>> fetchDailiesPage(
    int page, {
    bool forceRefresh = false,
  }) async {
    // we only ever ask for page=1 in the repo implementation
    if (page == 1) return items;
    return const [];
  }
}

class FakeGtshRankService extends GtshRankService {
  final List<GtshDailyRace> cards;
  FakeGtshRankService(this.cards) : super();

  @override
  Future<List<GtshDailyRace>> fetchRunningCards({bool forceRefresh = false}) async {
    return cards;
  }
}

void main() {
  group('SportRepository', () {
    test('merges items from both providers correctly', () async {
      // create matching summary & card
      final dg1 = DgEdgeDailyRace(
        id: '1',
        title: 'Daily A',
        url: 'url',
        trackName: 'TrackX',
      );
      final card1 = GtshDailyRace(
        label: 'A',
        trackName: 'TrackX',
        tyreCode: 'SS',
        status: 'running',
        carImage: 'https://gtsh-rank.com/images/car/123.png',
        pitStops: '-',
        bop: true,
        damage: 'Light',
        startType: 'Grid',
        carSettings: false,
        wideFender: 'No',
      );

      // dg only and gtsh only items
      final dg2 = DgEdgeDailyRace(
        id: '2',
        title: 'Daily B',
        url: 'url',
        trackName: 'SoloDG',
      );
      final card2 = GtshDailyRace(
        label: 'C',
        trackName: 'SoloGTSh',
        tyreCode: 'RH',
        status: 'running',
        pitStops: '-',
        bop: false,
        damage: 'None',
        startType: 'Rolling',
        carSettings: true,
        wideFender: 'Yes',
      );

      // item lacking any track information should be ignored later
      final dgNull = DgEdgeDailyRace(
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
      expect(list[0].carImage, contains('123.png'));

      // second pair should be dg2/card2
      expect(list[1].dgEdge, equals(dg2));
      expect(list[1].gtsh, equals(card2));
    });

    test('upcoming races are placed before current ones by _merge', () async {
      final futureSummary = DgEdgeDailyRace(
        id: 'f',
        title: 'Future',
        url: 'u',
        trackName: 'Later',
        isActive: false,
        isEnded: false,
      );
      final currentSummary = DgEdgeDailyRace(
        id: 'c',
        title: 'Current',
        url: 'u',
        trackName: 'Now',
        isActive: true,
        isEnded: false,
      );
      final nextCard = GtshDailyRace(
        label: 'A',
        trackName: 'Next',
        tyreCode: 'SM',
        status: 'next',
        pitStops: '-',
        bop: false,
        damage: '',
        startType: '',
        carSettings: false,
        wideFender: '',
      );
      final runningCard = GtshDailyRace(
        label: 'B',
        trackName: 'Now',
        tyreCode: 'RH',
        status: 'running',
        pitStops: '-',
        bop: false,
        damage: '',
        startType: '',
        carSettings: false,
        wideFender: '',
      );

      final sport = SportRepositoryImpl(
        FakeDgEdgeService([currentSummary, futureSummary]),
        FakeGtshRankService([runningCard, nextCard]),
      );

      await sport.fetchDailyRaces();
      final list = sport.dailyRaces;
      expect(list.first.isUpcoming, isTrue);
    });

    // remove previous sorting test
  });
}
