import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:gt7_companion/models/gtsh_rank/gtsh_daily_race.dart';
import 'package:gt7_companion/services/gtsh_rank_service.dart';

/// `test/fixtures/gtsh_rank_sample.html` is a real capture of
/// https://gtsh-rank.com/daily/ taken after the site's redesign, which renamed
/// the card from `.race-card` to `.daily-race-card` and replaced every inner
/// selector. The previous fixture still held the old markup, so the parser
/// returned nothing against the live site while these tests stayed green.
void main() {
  late List<GtshDailyRace> cards;

  setUpAll(() {
    final html = File('test/fixtures/gtsh_rank_sample.html').readAsStringSync();
    cards = GtshRankService().parsePage(html_parser.parse(html));
  });

  group('GtshRankService.parsePage', () {
    test('returns every card, archived ones included', () {
      // Past weeks are the reason this source is scraped, so archived cards
      // must not be filtered out the way the old parser did.
      expect(cards, hasLength(6));
      expect(cards.map((c) => c.status).toSet(), {'running', 'ended'});
      expect(cards.where((c) => c.status == 'running'), hasLength(3));
    });

    test('covers the full A/B/C rotation', () {
      expect(cards.take(3).map((c) => c.label), ['A', 'B', 'C']);
    });
  });

  group('field extraction', () {
    late GtshDailyRace a;
    late GtshDailyRace b;

    setUpAll(() {
      a = cards.first;
      b = cards[1];
    });

    test('reads the ranking id that pairs the card with DG-Edge', () {
      // The same identifier appears as `rankingid` on the DG-Edge card.
      expect(a.rankingId, 'p_rt_1014514_001');
      expect(b.rankingId, 'p_rt_1014518_001');
    });

    test('reads track, tyre and class', () {
      expect(a.trackName, 'Special Stage Route X');
      expect(a.tyreCode, 'SS');
      expect(a.category, isNull); // one-make race, no class badge

      expect(b.trackName, 'Fuji International Speedway');
      expect(b.tyreCode, 'RM');
      expect(b.category, 'Gr.3');
    });

    test('reads the race parameters from .daily-specs', () {
      expect(a.bop, isFalse);
      expect(a.carSettings, isTrue); // "Setup: Allowed"
      expect(a.damage, 'Light');
      expect(a.startType, 'Rolling');
      expect(a.fuelMultiplier, 1);
      expect(a.tyrewearMultiplier, 1);
      expect(a.pitStops, '-');
      // New in the redesign.
      expect(a.slipstream, 'Custom');

      expect(b.bop, isTrue);
      expect(b.damage, 'Med');
    });

    test('reads the world leader, new in the redesign', () {
      expect(a.leaderName, 'F4H Camo');
      expect(a.leaderCarName, "Pagani Huayra '13");
      expect(a.leaderAvatar, startsWith('https://gtsh-rank.com/images/'));
      expect(a.leaderCountryFlag, contains('/flags/'));
    });

    test('resolves relative image paths against the site host', () {
      expect(a.trackImage, 'https://gtsh-rank.com/images/course/1260.png');
      expect(a.carImage, startsWith('https://gtsh-rank.com/'));
    });

    test('reads the week from the date link', () {
      expect(a.weekStart, DateTime(2026, 8, 10));
      expect(a.weekUrl, contains('/daily/week/2026-08-10/'));
      expect(a.leaderboardUrl, contains('/daily/leaderboard'));
    });

    test('does not present the card clock as a lap time', () {
      // `.daily-time` reads 15:39 here while the real leader lap on this track
      // is 4:25.614 — it is the site's "updated at" clock, and naming it as a
      // lap time is how it would silently become wrong data on the card.
      expect(a.updatedAtLabel, '15:39');
    });
  });

  group('robustness', () {
    test('skips markup it no longer understands instead of emitting blanks', () {
      final list = GtshRankService().parsePage(
        html_parser.parse('<article class="daily-race-card"></article>'),
      );
      expect(list, isEmpty);
    });
  });
}
