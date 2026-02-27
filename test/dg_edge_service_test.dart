import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/services/dg_edge_service.dart';
import 'package:gt7_companion/models/daily_race.dart';

void main() {
  group('DgEdgeService parsing', () {
    final svc = DgEdgeService();

    test('parses list page sample', () {
      final html = File(
        'test/fixtures/dailies_page_sample.html',
      ).readAsStringSync();
      final doc = html_parser.parse(html);
      final list = svc.parseListPage(doc, baseUrl: 'https://www.dg-edge.com');

      expect(list.length, 2);
      expect(list[0].id, '505');
      expect(list[0].title, contains('Daily C'));
      expect(list[0].trackId, '315');
      expect(list[0].trackImage, contains('Track315.webp'));
      expect(list[0].trackBackgroundImage, contains('Back315.webp'));
      expect(list[0].trackLogotype, contains('Logo315.webp'));

      // explicit event/track fields
      expect(list[0].eventName, 'Daily C');
      expect(list[0].trackName, 'Tsukuba Circuit');
      expect(list[0].eventTime, isNull);

      expect(list[0].pitStops, isNull);
      expect(list[0].tyresAvailable, 6);
      expect(list[0].tyreCode, anyOf([null, 'RM', 'RH']));

      // new fields from wrapper
      expect(list[0].carType?.type, CarType.GR4);
      expect(list[0].carType?.display, 'GR.4');
      expect(list[0].laps, 12);
      expect(list[0].refuels, 1);
      expect(list[0].tyresAvailable, 6);
      expect(list[0].externalId, '1013599');
      expect(list[0].status, 'PENDING');
      expect(list[0].isActive, isTrue);
      expect(list[0].metaTitle, contains('Week 7-2026'));
    });

    test('parses detail sample', () {
      final html = File(
        'test/fixtures/dailies_detail_sample.html',
      ).readAsStringSync();
      final doc = html_parser.parse(html);
      final detail = DailyRaceDetail.fromDetailDocument(
        doc,
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
