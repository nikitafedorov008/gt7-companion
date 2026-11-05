import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:gt7_companion/services/dg_edge_service.dart';

void main() {
  test('November DG-Edge cards retain identity, metadata and live state', () {
    final races = DgEdgeService().parseListPage(
      html.parse(
        File('test/fixtures/dailies_page_2026_11.html').readAsStringSync(),
      ),
      baseUrl: 'https://www.dg-edge.com',
    );
    expect(races, hasLength(4));
    final a = races.first;
    expect(a.id, '689');
    expect(a.rankingId, 'p_rt_1015199_001');
    expect(a.trackName, 'Dragon Trail - Gardens');
    expect(a.raceLetter, 'A');
    expect(a.weekLabel, 'Week 45/2026');
    expect(a.dateRange, '2 Nov – 9 Nov 2026');
    expect(a.isActive, isTrue);
    expect(a.tyreCode, 'CS');
    expect(a.laps, 5);
    expect(a.className, contains('Chevrolet'));
    final archived = races.last;
    expect(archived.isEnded, isTrue);
    expect(archived.playersCount, greaterThan(0));
    expect(archived.leadTimeMs, greaterThan(0));
    expect(archived.ratingsMatrix, isNotEmpty);
    expect(archived.ratedPlayersCount, archived.playersCount);
  });
}
