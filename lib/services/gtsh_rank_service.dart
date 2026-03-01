import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import '../models/gtsh_race.dart';

/// Service responsible for scraping the GTSh-rank daily page and returning
/// currently-running race cards (the rows labelled A/B/C).
///
/// The API is intentionally minimal at the moment; callers may simply invoke
/// [fetchRunningCards] and use the results directly. The implementation mirrors
/// the style of [DgEdgeService], including a loading flag and error message so
/// that widgets may listen for changes.
class GtshRankService extends ChangeNotifier {
  static const String _base = 'https://gtsh-rank.com';
  static const Duration _timeout = Duration(seconds: 12);
  static const Duration _crawlDelay = Duration(milliseconds: 350);

  final http.Client _http;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  GtshRankService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  /// Fetch daily page and return list of running cards.
  Future<List<GtshRace>> fetchRunningCards({
    bool forceRefresh = false,
  }) async {
    _setLoading(true);
    try {
      final uri = Uri.parse('$_base/daily/');
      final resp = await _http
          .get(uri, headers: _defaultHeaders())
          .timeout(_timeout);
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      await Future.delayed(_crawlDelay);
      final document = html_parser.parse(resp.body);
      final list = parsePage(document);
      _error = null;
      return list;
    } catch (e) {
      _error = 'Failed to load GTSh rank page: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Parse a document into a list of `GtshRaceCard` items.
  ///
  /// Only `.race-card` elements containing a `.status.running` child are
  /// returned; other cards (next week, ended, etc) are ignored.
  List<GtshRace> parsePage(dom.Document doc) {
    final cards = <GtshRace>[];
    for (final el in doc.querySelectorAll('.race-card')) {
      // skip non-running entries early
      if (el.querySelector('.status.running') == null) continue;
      cards.add(GtshRace.fromElement(el));
    }
    return cards;
  }

  Map<String, String> _defaultHeaders() => {
    'User-Agent': 'gt7_companion/1.0 (+https://github.com)',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  };

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
