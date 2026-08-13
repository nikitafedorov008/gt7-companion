import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import '../models/dg_edge/dg_edge_daily_race.dart';
import '../models/dg_edge/dg_edge_player.dart';

/// Service to scrape DG-Edge daily events (list + detail pages).
///
/// Usage:
///   final svc = DgEdgeService();
///   final page = await svc.fetchDailiesPage(1);
///   final detail = await svc.fetchDailyDetail('/events/dailies/505');
class DgEdgeService extends ChangeNotifier {
  static const String _base = 'https://www.dg-edge.com';
  static const Duration _timeout = Duration(seconds: 12);
  static const Duration _crawlDelay = Duration(milliseconds: 350); // be polite

  final http.Client _http;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  DgEdgeService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  Future<List<DgEdgeDailyRace>> fetchDailiesPage(
    int page, {
    bool forceRefresh = false,
  }) async {
    _setLoading(true);
    try {
      final uri = Uri.parse(
        '$_base/events/dailies/${page == 1 ? '' : 'page-$page'}',
      );
      final resp = await _http
          .get(uri, headers: _defaultHeaders())
          .timeout(_timeout);
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      await Future.delayed(_crawlDelay);
      final document = html_parser.parse(resp.body);
      final list = parseListPage(document, baseUrl: _base);
      debugPrint(
        'DgEdgeService.fetchDailiesPage: HTTP ${resp.statusCode}, parsed ${list.length} items',
      );
      if (list.isNotEmpty) {
        debugPrint('  first item: ${list.first.id} - ${list.first.title}');
      }
      _error = null;
      return list;
    } catch (e) {
      _error = 'Failed to load dailies page $page: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches detail page for a daily race. Accepts either full URL or relative path.
  Future<DailyRaceDetail> fetchDailyDetail(String pathOrUrl) async {
    _setLoading(true);
    try {
      final uri = pathOrUrl.startsWith('http')
          ? Uri.parse(pathOrUrl)
          : Uri.parse('$_base$pathOrUrl');
      final resp = await _http
          .get(uri, headers: _defaultHeaders())
          .timeout(_timeout);
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      await Future.delayed(_crawlDelay);
      final doc = html_parser.parse(resp.body);
      final detail = DailyRaceDetail.fromDetailDocument(
        doc,
        url: uri.toString(),
      );
      if (detail == null) throw Exception('Failed to parse detail page');
      _error = null;
      return detail;
    } catch (e) {
      _error = 'Failed to load detail $pathOrUrl: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<DgEdgePlayerEventsResponse> fetchPlayerEvents(
    String onlineId, {
    int page = 1,
    String language = 'EN',
    int version = 162,
    String tz = 'Europe/Moscow',
  }) async {
    _setLoading(true);
    try {
      final uri = Uri.parse(
        'https://admin.dg-edge.com/api/b.players.retrievePlayerEvents',
      );
      final body = jsonEncode({
        'onlineId': onlineId,
        'page': page,
        'language': language,
        'version': version,
        'cookieVersion': null,
        'ajax_referer': '/players/$onlineId',
        'tz': tz,
      });

      final resp = await _http
          .post(uri, headers: _defaultJsonHeaders(), body: body)
          .timeout(_timeout);
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw Exception('DG-Edge player events request failed: ${resp.body}');
      }

      final response = DgEdgePlayerEventsResponse.fromJson(data);
      _error = null;
      return response;
    } catch (e) {
      _error = 'Failed to load player events $onlineId: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendBannerImpressions(
    List<int> impressions, {
    String language = 'EN',
    int version = 162,
    String tz = 'Europe/Moscow',
    String onlineId = '',
  }) async {
    _setLoading(true);
    try {
      final uri = Uri.parse('https://admin.dg-edge.com/api/b.banners.impress');
      final body = jsonEncode({
        'impressions': impressions,
        'language': language,
        'version': version,
        'cookieVersion': null,
        'ajax_referer': onlineId.isNotEmpty ? '/players/$onlineId' : '/players',
        'tz': tz,
      });

      final resp = await _http
          .post(uri, headers: _defaultJsonHeaders(), body: body)
          .timeout(_timeout);
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body);
      if (data is! Map || data['success'] != true) {
        throw Exception('DG-Edge banners impress failed: ${resp.body}');
      }

      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to send banner impressions: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Parses a listing HTML document and returns best-effort summaries.
  List<DgEdgeDailyRace> parseListPage(
    dom.Document doc, {
    required String baseUrl,
  }) {
    final seen = <String>{};
    final items = <DgEdgeDailyRace>[];

    // Race cards are `.event.daily` — active, past and (when scheduled ahead)
    // `.is-future`, which has no link yet. Selecting the card class directly
    // rather than every `/events/dailies/` anchor keeps the pagination strip
    // out: those `.page-link` anchors point at the same path and used to be
    // parsed as if they were races.
    final cards = doc.querySelectorAll('.event.daily');
    debugPrint('DgEdgeService.parseListPage: found ${cards.length} .event.daily cards');
    for (final el in cards) {
      if (el.classes.contains('page-link')) continue;
      final summary = DgEdgeDailyRace.fromListElement(el, baseUrl: baseUrl);
      if (summary != null && seen.add(summary.id)) items.add(summary);
    }

    // Fallback for markup variants that drop the `daily` class or wrap the
    // card in a grid column.
    if (items.isEmpty) {
      final fallbackCards = doc.querySelectorAll(
        '.event.is-future, .col-lg-4 .event, .events-list .event, .dailies-list .event',
      );
      debugPrint(
        'DgEdgeService.parseListPage: fallback cards ${fallbackCards.length}',
      );
      for (final el in fallbackCards) {
        if (el.classes.contains('page-link')) continue;
        final s = DgEdgeDailyRace.fromListElement(el, baseUrl: baseUrl);
        if (s != null && seen.add(s.id)) items.add(s);
      }
    }

    debugPrint(
      'DgEdgeService.parseListPage: returning ${items.length} summaries',
    );
    return items;
  }

  Map<String, String> _defaultHeaders() => {
    'User-Agent': 'gt7_companion/1.0 (+https://github.com)',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  };

  Map<String, String> _defaultJsonHeaders() => {
    'User-Agent': 'gt7_companion/1.0 (+https://github.com)',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Origin': _base,
    'Referer': '$_base/',
  };

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  /// Convenience: fetch multiple pages until an empty page or maxPages reached.
  Future<List<DgEdgeDailyRace>> fetchAllPages({int maxPages = 10}) async {
    final out = <DgEdgeDailyRace>[];
    for (var p = 1; p <= maxPages; p++) {
      try {
        final page = await fetchDailiesPage(p);
        if (page.isEmpty) break;
        out.addAll(page);
      } catch (e) {
        // stop on error
        break;
      }
    }
    return out;
  }
}
