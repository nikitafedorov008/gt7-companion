import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/services/gtsh_rank_service.dart';
import 'package:gt7_companion/models/gtsh_race.dart';

void main() {
  group('GtshRankService parsing', () {
    final svc = GtshRankService();

    test('finds running race cards from sample page', () {
      final html = File(
        'test/fixtures/gtsh_rank_sample.html',
      ).readAsStringSync();
      final doc = html_parser.parse(html);
      final list = svc.parsePage(doc);

      // only care about running entries
      expect(list.length, 2);

      expect(list.length, 2);

      final first = list[0];
      expect(first.trackName, 'Eiger Nordwand');
      expect(first.label, 'A');
      expect(first.tyreCode, 'SS');
      expect(first.bop, isFalse);
      expect(first.carSettings, isFalse);

      final second = list[1];
      expect(second.trackName, 'Watkins Glen Long Course');
      expect(second.label, 'B');
      expect(second.tyreCode, 'RH');
      expect(second.bop, isTrue);
    });
  });
}
