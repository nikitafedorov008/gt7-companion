import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/services/gtsh_rank_service.dart';

void main() {
  group('GtshRankService parsing', () {
    final svc = GtshRankService();

    test('includes both running and future cards from sample page', () {
      final html = File(
        'test/fixtures/gtsh_rank_sample.html',
      ).readAsStringSync();
      final doc = html_parser.parse(html);
      final list = svc.parsePage(doc);

      // sample page contains three "next week" cards followed by two running
      // entries; the parser used to drop the next-week cards, now they should
      // be retained.
      expect(list.length, greaterThanOrEqualTo(5));

      // the first few items should correspond to the next-week entries we
      // injected at the top of the fixture.
      final first = list[0];
      expect(first.trackName, 'Grand Valley - Highway 1');
      expect(first.label, 'A');
      expect(first.tyreCode, 'SM');
      expect(first.status, 'next');
      expect(first.carImage, isNull);

      final second = list[1];
      expect(second.trackName, 'Autodromo Nazionale Monza');
      expect(second.label, 'B');
      expect(second.tyreCode, 'RH');
      expect(second.status, 'next');
      expect(second.carImage, isNull);

      // make sure at least one running event still appears later in the list
      final running = list.firstWhere(
        (r) => r.trackName == 'Eiger Nordwand',
        orElse: () => throw StateError('running race not found'),
      );
      expect(running.label, 'A');
      expect(running.tyreCode, 'SS');
      expect(running.status, 'running');
      expect(running.carImage, contains('/images/car/451.png'));
    });
  });
}
