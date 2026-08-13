import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:gt7_companion/models/dg_edge/dg_edge_daily_race.dart';
import 'package:gt7_companion/services/dg_edge_service.dart';

/// `test/fixtures/dailies_page_sample.html` is a real capture of
/// https://www.dg-edge.com/events/dailies/ trimmed to three cards plus the
/// pagination strip. The card attributes are preserved verbatim because they
/// are what the parser reads.
void main() {
  late List<DgEdgeDailyRace> races;

  setUpAll(() {
    final html = File(
      'test/fixtures/dailies_page_sample.html',
    ).readAsStringSync();
    races = DgEdgeService().parseListPage(
      html_parser.parse(html),
      baseUrl: 'https://www.dg-edge.com',
    );
  });

  group('DgEdgeService.parseListPage', () {
    test('returns one entry per race card', () {
      expect(races, hasLength(3));
      expect(races.map((r) => r.id), ['627', '628', '621']);
    });

    test('does not mistake pagination links for races', () {
      // The strip links to /events/dailies/page-N, matching the same URL shape
      // as a race. Selecting `.event.daily` rather than every anchor to that
      // path is what keeps them out; they used to be parsed as blank races.
      expect(races.any((r) => r.id.startsWith('page-')), isFalse);
      expect(races.every((r) => r.trackName?.isNotEmpty ?? false), isTrue);
    });
  });

  group('field extraction', () {
    test('reads the identifiers the merge depends on', () {
      final a = races.first;
      expect(a.rankingId, 'p_rt_1014514_001');
      expect(a.externalId, '1014514');
      expect(a.trackId, '3');
      expect(a.url, 'https://www.dg-edge.com/events/dailies/627');
    });

    test('derives race letter, week and track', () {
      final a = races.first;
      expect(a.raceLetter, 'A');
      expect(a.weekLabel, 'Week 33/2026');
      expect(a.dateRange, '10 August 2026 - 17 August 2026');
      expect(a.trackName, 'Special Stage Route X');
      // The previous parser produced a run-on of every visible string here:
      // "Daily ALive 68% Week 33/202610 August 2026 - …Special Stage Route XSS 1 x1 x1".
      expect(a.title, 'Daily A — Special Stage Route X');
    });

    test('reads the visible race settings', () {
      final b = races[1];
      expect(b.trackName, 'Fuji International Speedway');
      expect(b.carType?.type, CarType.GR3);
      expect(b.tyre, Tyre.RM);
      expect(b.laps, 6);
      expect(b.refuels, 1);
      expect(b.tyresAvailable, 1);
      expect(b.votesPercent, 88);
    });

    test('reads participation figures and reference times', () {
      final a = races.first;
      expect(a.playersCount, 20273);
      expect(a.leadTime, '4:25.614');
      expect(a.top100Time, '4:25.740');
      expect(a.wheelCount, 281);
      expect(a.padCount, 87);
    });

    test('decodes the rating and country histograms', () {
      final a = races.first;
      expect(a.ratingsMatrix['D_S'], 3323);
      expect(a.countriesMatrix['US'], 3259);
      // Each rated entry is one player, so the histogram must add up to the
      // headline figure — a cheap check that decoding dropped nothing.
      expect(a.ratedPlayersCount, a.playersCount);
    });

    test('distinguishes the live week from an archived one', () {
      expect(races.first.isActive, isTrue);
      expect(races.first.isEnded, isFalse);

      final past = races.last;
      expect(past.weekLabel, 'Week 32/2026');
      expect(past.isActive, isFalse);
      expect(past.trackName, 'Autodromo Nazionale Monza');
    });

    test('leaves a one-make race without a class rather than inventing one', () {
      // Daily A that week runs a specified car, so its card carries no
      // `.event-car-type` block at all.
      expect(races.first.carType, isNull);
    });
  });

  group('future cards', () {
    // No future card exists upstream at the time of writing — the site styles
    // `.event.card.is-future` but publishes none. This mirrors the real card
    // structure with the link removed, which is the documented difference.
    test('parses an unlinked card using its externalid', () {
      const html = '''
        <a class="event card daily is-future" externalid="123"
           rankingid="p_rt_123_001" trackid="9" status="PENDING" isended="false"
           metatitle="Week 34-2026 Daily A - Gran Turismo 7"
           metadescription="Example Track - GT7 Daily Race A - Week 34/2026">
          <div class="event-details card-body">
            <div class="event-time"><span>Week 34/2026</span><span>17 August 2026 - 24 August 2026</span></div>
            <div class="event-name h4">Example Track</div>
          </div>
        </a>
      ''';
      final list = DgEdgeService().parseListPage(
        html_parser.parse(html),
        baseUrl: 'https://www.dg-edge.com',
      );

      expect(list, hasLength(1));
      expect(list.first.id, '123');
      expect(list.first.trackName, 'Example Track');
      expect(list.first.raceLetter, 'A');
      expect(list.first.weekLabel, 'Week 34/2026');
      expect(list.first.status, 'PENDING');
      expect(list.first.isActive, isFalse);
      expect(list.first.isEnded, isFalse);
      // Unlinked, so the URL is rebuilt from the id.
      expect(list.first.url, 'https://www.dg-edge.com/events/dailies/123');
    });
  });

  group('formatLapTime', () {
    test('renders milliseconds the way the site prints them', () {
      expect(DgEdgeDailyRace.formatLapTime(265614), '4:25.614');
      expect(DgEdgeDailyRace.formatLapTime(97682), '1:37.682');
      expect(DgEdgeDailyRace.formatLapTime(45123), '45.123');
    });

    test('returns null for missing or zero times', () {
      expect(DgEdgeDailyRace.formatLapTime(null), isNull);
      expect(DgEdgeDailyRace.formatLapTime(0), isNull);
    });
  });

  group('DailyRaceDetail.fromDetailDocument', () {
    test('parses the detail sample', () {
      final html = File(
        'test/fixtures/dailies_detail_sample.html',
      ).readAsStringSync();
      final detail = DailyRaceDetail.fromDetailDocument(
        html_parser.parse(html),
        url: 'https://www.dg-edge.com/events/dailies/505',
      );

      expect(detail, isNotNull);
      expect(detail!.id, '505');
      expect(detail.title, contains('Nurburgring'));
      expect(detail.players, contains('PlayerOne — 1:34.567'));
      expect(detail.className, 'Gr.3');
      expect(detail.laps, 5);
      expect(detail.refuels, 1);
      expect(detail.tyreCompound, 'Hard');
      expect(detail.fuelAllowed, isTrue);
      expect(detail.reward, contains('30000'));
    });
  });
}
