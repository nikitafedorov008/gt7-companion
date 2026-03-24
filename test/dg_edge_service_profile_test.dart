import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gt7_companion/services/dg_edge_service.dart';

void main() {
  group('DgEdgeService player profile endpoints', () {
    test('fetchPlayerEvents returns parsed data', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://admin.dg-edge.com/api/b.players.retrievePlayerEvents',
        );

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['onlineId'], 'nikitawolf008');
        expect(body['page'], 1);

        return http.Response(
          jsonEncode({
            'success': true,
            'payload': {
              'list': [
                {
                  'id': 508,
                  'eventType': 'TT',
                  'track': {'name': 'Circuit de Spa-Francorchamps'},
                  'car': {
                    'name': "911 GT3 R (992) '22",
                    'brand': {'name': 'Porsche'},
                  },
                  'playerResult': {
                    'globalPosition': 131962,
                    'countryPosition': 870,
                    'time': '02:23.085',
                    'timestamp': '2026-02-13 10:36:23',
                  },
                  'isActive': false,
                  'isEnded': true,
                },
              ],
              'pagination': {
                'actualPage': 1,
                'totalRecords': 58,
                'hasMore': true,
              },
            },
            'csrfToken': 'token',
          }),
          200,
        );
      });

      final svc = DgEdgeService(httpClient: client);
      final resp = await svc.fetchPlayerEvents('nikitawolf008');

      expect(resp.events.length, 1);
      expect(resp.pagination?.actualPage, 1);
      expect(resp.csrfToken, 'token');
      expect(resp.events.first.eventType, 'TT');
      expect(resp.events.first.trackName, 'Circuit de Spa-Francorchamps');
      expect(resp.events.first.carName, "911 GT3 R (992) '22");
      expect(resp.events.first.playerResult?.time, '02:23.085');
    });

    test('sendBannerImpressions returns true on success', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://admin.dg-edge.com/api/b.banners.impress',
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['impressions'], [34]);
        return http.Response(
          jsonEncode({'success': true, 'payload': true, 'csrfToken': 'token'}),
          200,
        );
      });

      final svc = DgEdgeService(httpClient: client);
      final result = await svc.sendBannerImpressions([34]);
      expect(result, isTrue);
    });
  });
}
