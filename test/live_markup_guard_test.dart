@Tags(['network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:gt7_companion/services/dg_edge_service.dart';
import 'package:gt7_companion/services/gtsh_rank_service.dart';

/// Checks that the two scraped sites still parse.
///
/// The fixtures in `test/fixtures/` freeze the markup as it was when captured,
/// which is exactly why the last redesign went unnoticed: GTSh renamed its
/// card class, the live parser started returning nothing, and the suite stayed
/// green against the old snapshot. This test closes that gap by parsing the
/// real pages.
///
/// It is skipped in the default run because it depends on third-party sites
/// and would turn CI red for reasons unrelated to this codebase. It is a
/// diagnostic, not a gate:
///
/// ```
/// flutter test --tags network --run-skipped
/// ```
///
/// Both flags are required — see the note in `dart_test.yaml`.
///
/// When it fails, re-capture the fixtures and update the parsers — do not
/// relax the assertions.
void main() {
  const userAgent = 'gt7_companion/1.0 (+https://github.com)';
  const timeout = Duration(seconds: 30);

  Future<String> fetch(String url) async {
    final resp = await http
        .get(Uri.parse(url), headers: {'User-Agent': userAgent})
        .timeout(timeout);
    expect(
      resp.statusCode,
      200,
      reason: '$url returned HTTP ${resp.statusCode}',
    );
    return resp.body;
  }

  test('DG-Edge dailies page still yields complete races', () async {
    final doc = html_parser.parse(
      await fetch('https://www.dg-edge.com/events/dailies/'),
    );
    final races = DgEdgeService().parseListPage(
      doc,
      baseUrl: 'https://www.dg-edge.com',
    );

    // One page carries several weeks of A/B/C; far fewer means the card
    // selector stopped matching.
    expect(races.length, greaterThanOrEqualTo(9));

    // Pagination anchors point at the same URL shape as races and must not
    // leak into the list.
    expect(races.any((r) => r.id.startsWith('page-')), isFalse);

    final first = races.first;
    expect(first.trackName, isNotEmpty);
    expect(
      first.rankingId,
      isNotNull,
      reason: 'rankingId is what pairs this source with GTSh',
    );
    expect(first.raceLetter, isNotNull);
    expect(first.weekLabel, contains('Week'));
    expect(first.playersCount, greaterThan(0));
    expect(first.leadTimeMs, greaterThan(0));

    // The rating histogram must account for every player, which only holds if
    // the JSON attribute decoded correctly.
    expect(first.ratingsMatrix, isNotEmpty);
    expect(first.ratedPlayersCount, first.playersCount);

    // At least one card should be the running week.
    expect(races.any((r) => r.isActive == true), isTrue);
  });

  test('GTSh-rank daily page still yields complete cards', () async {
    final doc = html_parser.parse(await fetch('https://gtsh-rank.com/daily/'));
    final cards = GtshRankService().parsePage(doc);

    expect(cards.length, greaterThanOrEqualTo(3));

    final first = cards.first;
    expect(first.trackName, isNotEmpty);
    expect(first.label, isNotEmpty);
    expect(first.tyreCode, isNotEmpty);
    expect(
      first.rankingId,
      isNotNull,
      reason: 'data-board is what pairs this source with DG-Edge',
    );
    // `.daily-specs` is the whole reason this source is scraped alongside
    // DG-Edge; an empty one means the block was renamed again.
    expect(first.startType, isNotEmpty);
    expect(first.damage, isNotEmpty);
    expect(cards.any((c) => c.status == 'running'), isTrue);
  });

  test('the two sources still share ranking ids', () async {
    final dgRaces = DgEdgeService().parseListPage(
      html_parser.parse(await fetch('https://www.dg-edge.com/events/dailies/')),
      baseUrl: 'https://www.dg-edge.com',
    );
    final gtCards = GtshRankService().parsePage(
      html_parser.parse(await fetch('https://gtsh-rank.com/daily/')),
    );

    final dgIds = dgRaces.map((r) => r.rankingId).whereType<String>().toSet();
    final gtIds = gtCards.map((c) => c.rankingId).whereType<String>().toSet();
    final shared = dgIds.intersection(gtIds);

    // If this empties out, the merge silently degrades to unpaired entries.
    expect(
      shared,
      isNotEmpty,
      reason:
          'no shared ranking ids — the merge key is gone.\n'
          'DG-Edge sample: ${dgIds.take(3)}\nGTSh sample: ${gtIds.take(3)}',
    );
  });
}
