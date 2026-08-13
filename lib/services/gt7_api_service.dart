import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

import '../models/gt7_sport_profile.dart';
import '../models/gt7_sport_race_stats.dart';
import '../models/gt7_stats.dart';
import '../models/gt7_stats_history.dart';
import '../models/gt7_user_profile.dart';
import '../models/gt7_user_stats.dart';
import 'gt7_auth_service.dart';
import 'gt7_auth_trace.dart';

/// Client for the GT7 web API at `web-api.gt7.game.gran-turismo.com`.
///
/// Uses the access_token obtained by [Gt7AuthService] to make authenticated
/// API calls. The endpoints and request bodies here were captured from the
/// official profile page — see [Gt7AuthTrace].
class Gt7ApiService extends ChangeNotifier {
  Gt7ApiService(this._authService);

  final Gt7AuthService _authService;

  static const String _apiBase = 'https://web-api.gt7.game.gran-turismo.com';

  Gt7UserProfile? _profile;
  Gt7SportProfile? _sportProfile;
  List<Gt7SportRaceStats> _sportRaces = const [];
  Gt7StatsHistory? _statsHistory;
  Gt7Stats? _fullStats;
  List<int> _collectionIds = const [];
  Gt7UserStats? _stats;
  bool _isLoading = false;
  String? _error;

  Gt7UserProfile? get profile => _profile;
  Gt7SportProfile? get sportProfile => _sportProfile;
  List<Gt7SportRaceStats> get sportRaces => _sportRaces;
  Gt7StatsHistory? get statsHistory => _statsHistory;
  Gt7Stats? get fullStats => _fullStats;
  List<int> get collectionIds => _collectionIds;
  Gt7UserStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer ${_authService.accessToken}',
    'Accept': 'application/json, text/plain, */*',
    'Content-Type': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/151.0.0.0 Safari/537.36',
    'Origin': 'https://www.gran-turismo.com',
    'Referer': 'https://www.gran-turismo.com/',
  };

  /// POST [path] and return the decoded JSON object, or null on failure.
  ///
  /// A 401 clears the stored token so the UI drops back to the login prompt
  /// instead of silently showing stale data.
  Future<Map<String, dynamic>?> _post(
    String path, {
    Map<String, dynamic>? body,
    bool allowRetry = true,
  }) async {
    final trace = Gt7AuthTrace.instance;
    try {
      final response = await http.post(
        Uri.parse('$_apiBase$path'),
        headers: _authHeaders,
        body: body == null ? null : jsonEncode(body),
      );

      // Guarded rather than left to log() — redacting a 4 KB body on every
      // request is pure waste once tracing is off.
      if (Gt7AuthTrace.enabled) {
        trace.log(TraceKind.http, 'POST $path', {
          'status': response.statusCode,
          'reqBody': body == null ? null : jsonEncode(body),
          'resBody': Gt7AuthTrace.redact(
            response.body.length > 4000
                ? '${response.body.substring(0, 4000)}'
                      '…[+${response.body.length - 4000} more]'
                : response.body,
          ),
        });
      }

      if (response.statusCode == 401) {
        // The token may have expired mid-flight. The session cookie usually
        // has not, so renew once and replay the request before giving up.
        if (allowRetry && await _authService.refreshToken()) {
          trace.log(TraceKind.token, '401 on $path — renewed, replaying');
          return _post(path, body: body, allowRetry: false);
        }
        _error = 'Session expired. Please log in again.';
        await _authService.invalidateToken();
        return null;
      }

      if (response.statusCode != 200) {
        _error = '$path failed: ${response.statusCode}';
        return null;
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      _error = '$path failed: $e';
      trace.log(TraceKind.error, 'POST $path threw', {'error': e.toString()});
      return null;
    }
  }

  /// Fetch the authenticated user's profile.
  Future<Gt7UserProfile?> fetchUserProfile() async {
    if (!await _authService.ensureFreshToken()) {
      _error = 'Not authenticated. Please log in first.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _loadUserProfile();

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Profile fetch without loading-state bookkeeping, so [fetchAll] can keep
  /// a single loading window across all of its requests.
  Future<Gt7UserProfile?> _loadUserProfile() async {
    final data = await _post('/user/get_user_profile');
    if (data == null) return null;

    final newProfile = Gt7UserProfile.fromJson(data);

    // Preserve image URLs scraped from the profile page — the API returns
    // only photo IDs, which cannot be turned back into UGC URLs.
    _profile = _profile == null
        ? newProfile
        : _withScrapedUrls(
            newProfile,
            avatarUrl: newProfile.avatarUrl ?? _profile!.avatarUrl,
            coverUrl: newProfile.coverUrl ?? _profile!.coverUrl,
            driverUrl: newProfile.driverUrl ?? _profile!.driverUrl,
          );

    notifyListeners();
    return _profile;
  }

  /// Fetch Sport-mode profile — driver rating, safety rating, race count.
  Future<Gt7SportProfile?> fetchSportProfile() async {
    final data = await _post('/user/get_sport_profile');
    if (data == null) return null;
    _sportProfile = Gt7SportProfile.fromJson(data);
    notifyListeners();
    return _sportProfile;
  }

  /// Fetch aggregated Sport race records for the given categories.
  Future<List<Gt7SportRaceStats>> fetchSportRaceStats({
    List<int> typeList = const [1, 2],
  }) async {
    final userId = _profile?.userId ?? _authService.userId;
    if (userId == null || userId.isEmpty) return const [];

    final data = await _post(
      '/stats/get_sport_race',
      body: {'user_id': userId, 'type_list': typeList},
    );
    if (data == null) return const [];

    _sportRaces = Gt7SportRaceStats.listFromJson(data);
    notifyListeners();
    return _sportRaces;
  }

  /// Fetch the per-day history for one month (defaults to the current one).
  Future<Gt7StatsHistory?> fetchStatsHistory({int? year, int? month}) async {
    final userId = _profile?.userId ?? _authService.userId;
    if (userId == null || userId.isEmpty) return null;

    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;

    final data = await _post(
      '/stats/get_history',
      body: {'user_id': userId, 'year': y, 'month': m},
    );
    if (data == null) return null;

    _statsHistory = Gt7StatsHistory.fromJson(data, year: y, month: m);
    notifyListeners();
    return _statsHistory;
  }

  /// Fetch lifetime statistics — mileage, cars bought, medals, followers.
  Future<Gt7Stats?> fetchStats({int? year, int? month}) async {
    final userId = _profile?.userId ?? _authService.userId;
    if (userId == null || userId.isEmpty) return null;

    final now = DateTime.now();
    final data = await _post(
      '/stats/get',
      body: {
        'user_id': userId,
        'year': year ?? now.year,
        'month': month ?? now.month,
      },
    );
    if (data == null) return null;

    _fullStats = Gt7Stats.fromJson(data);
    notifyListeners();
    return _fullStats;
  }

  /// Fetch the collection ID list.
  ///
  /// Returns roughly 2500 IDs on the reference account, while
  /// `car_life.buy_car_count` there is 229 — so this is *not* the owned-car
  /// count, and "cars purchased" is taken from [Gt7Stats] instead. What these
  /// IDs enumerate is still unidentified.
  Future<List<int>> fetchCollectionIds({int type = 0}) async {
    final data = await _post('/collection/get_id_list', body: {'type': type});
    final result = data?['result'];
    if (result is! List) return const [];

    _collectionIds = result.whereType<num>().map((n) => n.toInt()).toList();
    notifyListeners();
    return _collectionIds;
  }

  /// Load everything the profile screen needs, in one pass.
  Future<void> fetchAll() async {
    if (!await _authService.ensureFreshToken()) {
      _error = 'Not authenticated. Please log in first.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    await _loadUserProfile();
    await Future.wait([
      fetchSportProfile(),
      fetchSportRaceStats(),
      fetchStatsHistory(),
      fetchStats(),
      fetchCollectionIds(),
    ]);

    _stats = Gt7UserStats.fromApi(
      sportProfile: _sportProfile,
      sportRaces: _sportRaces,
      stats: _fullStats,
    );

    Gt7AuthTrace.instance.log(TraceKind.http, 'fetchAll complete', {
      'stats': _stats.toString(),
      'lifetime': _fullStats.toString(),
      'monthKm': _statsHistory?.totalKm.toStringAsFixed(1),
      'collectionIds': _collectionIds.length,
    });

    _isLoading = false;
    notifyListeners();
  }

  /// Scrape UGC image URLs from the GT7 profile page using the WebView.
  ///
  /// The API returns only photo IDs, while the page HTML carries the full UGC
  /// URLs including an opaque hash that cannot be derived from an ID. Ratings
  /// and counters are *not* scraped — those come from the API above.
  Future<void> scrapeImageUrls(InAppWebViewController controller) async {
    final profile = _profile;
    if (profile == null) {
      debugPrint('[Gt7Api] scrapeImageUrls: profile is null, skipping');
      return;
    }

    try {
      await controller.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(
            'https://www.gran-turismo.com/ru/gt7/user/mymenu/'
            '${profile.userId}/profile',
          ),
        ),
      );

      await Future<void>.delayed(const Duration(seconds: 5));

      final result = await controller.evaluateJavascript(source: r'''
        (function () {
          var urls = [];
          document.querySelectorAll('img').forEach(function (img) {
            if (img.src && img.src.includes('ugc.gt7')) urls.push(img.src);
          });
          document.querySelectorAll('*').forEach(function (el) {
            var bg = getComputedStyle(el).backgroundImage;
            if (bg && bg !== 'none' && bg.includes('ugc.gt7')) {
              var m = bg.match(/url\(["']?([^"')]+)["']?\)/);
              if (m) urls.push(m[1]);
            }
          });
          var html = document.documentElement.outerHTML;
          var matches = html.match(
            /https?:\/\/ugc\.gt7\.game\.gran-turismo\.com\/[^"')\s]+/g);
          if (matches) matches.forEach(function (u) {
            if (urls.indexOf(u) === -1) urls.push(u);
          });
          return JSON.stringify([...new Set(urls)]);
        })()
      ''');

      if (result == null) return;

      final ugcUrls = (jsonDecode(result as String) as List<dynamic>)
          .cast<String>()
          .where((u) => u.contains('ugc.gt7'))
          .map((u) => u.replaceAll('&quot;', '').replaceAll('&amp;', '&').trim())
          .where((u) => u.isNotEmpty)
          .toList();

      Gt7AuthTrace.instance.log(TraceKind.dom, 'UGC image URLs found', {
        'count': ugcUrls.length,
      });

      String? avatarUrl;
      String? coverUrl;
      String? driverUrl;
      for (final url in ugcUrls) {
        if (url.contains(profile.avatarPhotoId.toString())) {
          avatarUrl = url;
        } else if (url.contains(profile.coverPhotoId.toString())) {
          coverUrl = url;
        } else if (url.contains(profile.driverPhotoId.toString())) {
          driverUrl = url;
        }
      }

      _profile = _withScrapedUrls(
        profile,
        avatarUrl: avatarUrl ?? profile.avatarUrl,
        coverUrl: coverUrl ?? profile.coverUrl,
        driverUrl: driverUrl ?? profile.driverUrl,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[Gt7Api] Failed to scrape image URLs: $e');
    }
  }

  static Gt7UserProfile _withScrapedUrls(
    Gt7UserProfile base, {
    String? avatarUrl,
    String? coverUrl,
    String? driverUrl,
  }) {
    return Gt7UserProfile(
      nickName: base.nickName,
      npOnlineId: base.npOnlineId,
      aboutMe: base.aboutMe,
      greeting: base.greeting,
      greetingPostRace: base.greetingPostRace,
      countryCode: base.countryCode,
      avatarPhotoId: base.avatarPhotoId,
      coverPhotoId: base.coverPhotoId,
      driverPhotoId: base.driverPhotoId,
      userId: base.userId,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      driverUrl: driverUrl,
    );
  }

  /// Clear cached data (e.g. on logout).
  void clear() {
    _profile = null;
    _sportProfile = null;
    _sportRaces = const [];
    _statsHistory = null;
    _fullStats = null;
    _collectionIds = const [];
    _stats = null;
    _error = null;
    notifyListeners();
  }
}
