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
  }) async => page == 1 ? items : const [];
}

class FakeGtshRankService extends GtshRankService {
  final List<GtshDailyRace> cards;
  FakeGtshRankService(this.cards) : super();

  @override
  Future<List<GtshDailyRace>> fetchDailyCards({
    bool forceRefresh = false,
  }) async => cards;
}

class ThrowingDgEdgeService extends DgEdgeService {
  @override
  Future<List<DgEdgeDailyRace>> fetchDailiesPage(
    int page, {
    bool forceRefresh = false,
  }) async => throw Exception('boom');
}

DgEdgeDailyRace _dg({
  required String id,
  String? rankingId,
  String? trackName = 'TrackX',
  String? letter,
  bool? isActive,
  bool? isEnded,
}) => DgEdgeDailyRace(
  id: id,
  title: 'Daily ${letter ?? id}',
  url: 'https://www.dg-edge.com/events/dailies/$id',
  trackName: trackName,
  raceLetter: letter,
  rankingId: rankingId,
  isActive: isActive,
  isEnded: isEnded,
);

GtshDailyRace _gtsh({
  String label = 'A',
  String trackName = 'TrackX',
  String? rankingId,
  String status = 'running',
  String? carImage,
}) => GtshDailyRace(
  label: label,
  trackName: trackName,
  tyreCode: 'SS',
  status: status,
  rankingId: rankingId,
  carImage: carImage,
  pitStops: '-',
  bop: true,
  damage: 'Light',
  startType: 'Rolling',
  carSettings: false,
);

void main() {
  group('SportRepository merging', () {
    test('pairs the two sources on the shared ranking id', () async {
      // Both sites publish the game's own board id — DG-Edge as `rankingid`,
      // GTSh as `data-board`. Deliberately listed in opposite orders so that
      // positional pairing, which this used to do, would mismatch them.
      final dgA = _dg(id: '1', rankingId: 'p_rt_100_001', trackName: 'Monza');
      final dgB = _dg(id: '2', rankingId: 'p_rt_200_001', trackName: 'Fuji');
      final gtB = _gtsh(rankingId: 'p_rt_200_001', trackName: 'Fuji', label: 'B');
      final gtA = _gtsh(rankingId: 'p_rt_100_001', trackName: 'Monza');

      final sport = SportRepositoryImpl(
        FakeDgEdgeService([dgA, dgB]),
        FakeGtshRankService([gtB, gtA]),
      );
      await sport.fetchDailyRaces();

      final byTrack = {for (final r in sport.dailyRaces) r.trackName: r};
      expect(byTrack['Monza']!.gtsh, same(gtA));
      expect(byTrack['Fuji']!.gtsh, same(gtB));
    });

    test('falls back to race letter and track when no ranking id is set', () {
      // Track names differ slightly between the sites, so only the segment
      // before the dash is compared: "Grand Valley" vs "Grand Valley - Highway 1".
      final dg = _dg(id: '3', trackName: 'Grand Valley', letter: 'C');
      final gt = _gtsh(label: 'C', trackName: 'Grand Valley - Highway 1');

      final sport = SportRepositoryImpl(
        FakeDgEdgeService([dg]),
        FakeGtshRankService([gt]),
      );

      return sport.fetchDailyRaces().then((_) {
        expect(sport.dailyRaces, hasLength(1));
        expect(sport.dailyRaces.single.gtsh, same(gt));
      });
    });

    test('keeps entries that exist in only one source', () async {
      final dgOnly = _dg(id: '1', rankingId: 'p_rt_1_001', trackName: 'SoloDG');
      final gtOnly = _gtsh(rankingId: 'p_rt_9_001', trackName: 'SoloGTSh');

      final sport = SportRepositoryImpl(
        FakeDgEdgeService([dgOnly]),
        FakeGtshRankService([gtOnly]),
      );
      await sport.fetchDailyRaces();

      expect(sport.dailyRaces.map((r) => r.trackName), containsAll(<String>[
        'SoloDG',
        'SoloGTSh',
      ]));
      final solo = sport.dailyRaces.firstWhere((r) => r.trackName == 'SoloDG');
      expect(solo.gtsh, isNull);
    });

    test('drops entries with no track at all', () async {
      final sport = SportRepositoryImpl(
        FakeDgEdgeService([
          _dg(id: 'ok', rankingId: 'p_rt_1_001'),
          _dg(id: 'nil', trackName: null),
        ]),
        FakeGtshRankService(const []),
      );
      await sport.fetchDailyRaces();

      expect(sport.dailyRaces, hasLength(1));
      expect(sport.dailyRaces.single.dgEdge?.id, 'ok');
    });

    test('carries paired GTSh detail through to the unified race', () async {
      final dg = _dg(id: '1', rankingId: 'p_rt_1_001');
      final gt = _gtsh(
        rankingId: 'p_rt_1_001',
        carImage: 'https://gtsh-rank.com/images/car/123.png',
      );

      final sport = SportRepositoryImpl(
        FakeDgEdgeService([dg]),
        FakeGtshRankService([gt]),
      );
      await sport.fetchDailyRaces();

      final race = sport.dailyRaces.single;
      expect(race.label, 'A');
      expect(race.carImage, contains('123.png'));
      expect(race.damage, 'Light');
      expect(race.startType, 'Rolling');
    });
  });

  group('SportRepository ordering and failures', () {
    test('places upcoming races before current ones', () async {
      final current = _dg(
        id: 'c',
        rankingId: 'p_rt_c_001',
        trackName: 'Now',
        isActive: true,
        isEnded: false,
      );
      final future = _dg(
        id: 'f',
        rankingId: 'p_rt_f_001',
        trackName: 'Later',
        isActive: false,
        isEnded: false,
      );

      final sport = SportRepositoryImpl(
        FakeDgEdgeService([current, future]),
        FakeGtshRankService(const []),
      );
      await sport.fetchDailyRaces();

      expect(sport.dailyRaces.first.isUpcoming, isTrue);
      expect(sport.dailyRaces.first.trackName, 'Later');
    });

    test('still returns the surviving source when one fails', () async {
      final sport = SportRepositoryImpl(
        ThrowingDgEdgeService(),
        FakeGtshRankService([_gtsh(trackName: 'GTShOnly')]),
      );
      await sport.fetchDailyRaces();

      expect(sport.dailyRaces, hasLength(1));
      expect(sport.dailyRaces.single.trackName, 'GTShOnly');
      expect(sport.error, isNull);
    });

    test('reports an error only when both sources come back empty', () async {
      final sport = SportRepositoryImpl(
        ThrowingDgEdgeService(),
        FakeGtshRankService(const []),
      );
      await sport.fetchDailyRaces();

      expect(sport.dailyRaces, isEmpty);
      expect(sport.error, isNotNull);
    });
  });
}
