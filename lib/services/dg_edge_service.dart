import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import '../models/daily_race.dart';

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

  Future<List<DailyRaceSummary>> fetchDailiesPage(
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
      if (list.isNotEmpty)
        debugPrint('  first item: ${list.first.id} - ${list.first.title}');
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

  // Parses a listing HTML document and returns best-effort summaries.
  List<DailyRaceSummary> parseListPage(
    dom.Document doc, {
    required String baseUrl,
  }) {
    // Candidate selectors (robust): look for anchors to /events/dailies/ and then the containing card
    final anchors = doc.querySelectorAll('a[href*="/events/dailies/"]');
    debugPrint(
      'DgEdgeService.parseListPage: found ${anchors.length} anchors[href*="/events/dailies/"]',
    );
    final seen = <String>{};
    final items = <DailyRaceSummary>[];
    for (final a in anchors) {
      final href = a.attributes['href'] ?? '';
      if (!RegExp(r'/events/dailies/[\w-]+').hasMatch(href)) continue;
      // Prefer the nearest ancestor that looks like a card/article
      dom.Element el = a;
      for (final sel in [
        '.card',
        '.event',
        'article',
        '.entry',
        '.post',
        '.listing-item',
      ]) {
        final parent = _closestAncestor(a, sel);
        if (parent != null) {
          el = parent;
          break;
        }
      }
      final summary = DailyRaceSummary.fromListElement(el, baseUrl: baseUrl);
      if (summary != null && seen.add(summary.id)) items.add(summary);
    }

    // Fallback: if nothing found, try common list containers
    if (items.isEmpty) {
      final candidates = doc.querySelectorAll(
        '.events-list, .dailies-list, .cards, .posts',
      );
      debugPrint(
        'DgEdgeService.parseListPage: fallback candidates ${candidates.length}',
      );
      for (final c in candidates) {
        for (final el in c.querySelectorAll('article, .card, .post, li')) {
          final s = DailyRaceSummary.fromListElement(el, baseUrl: baseUrl);
          if (s != null && seen.add(s.id)) items.add(s);
        }
      }
    }

    debugPrint(
      'DgEdgeService.parseListPage: returning ${items.length} summaries',
    );
    return items;
  }

  // package:html.Element does not provide a `closest` helper; implement a small, robust fallback
  dom.Element? _closestAncestor(dom.Element el, String selector) {
    dom.Node? cur = el;
    final isClass = selector.startsWith('.');
    final selName = isClass ? selector.substring(1) : selector.toLowerCase();

    while (cur is dom.Element) {
      final e = cur; // promoted to Element by the `is` check above
      if (isClass) {
        if (e.classes.contains(selName)) return e;
      } else {
        if (e.localName == selName) return e;
      }
      cur = cur.parent;
    }
    return null;
  }

  Map<String, String> _defaultHeaders() => {
    'User-Agent': 'gt7_companion/1.0 (+https://github.com)',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  };

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  /// Convenience: fetch multiple pages until an empty page or maxPages reached.
  Future<List<DailyRaceSummary>> fetchAllPages({int maxPages = 10}) async {
    final out = <DailyRaceSummary>[];
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
