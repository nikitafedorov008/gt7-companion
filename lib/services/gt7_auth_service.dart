import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'gt7_auth_trace.dart';

/// Manages GT7 authentication via PSN OAuth through an embedded WebView.
///
/// Flow:
/// 1. Open WebView on `gran-turismo.com/ru/gt7/user/signin/`
/// 2. User logs in via PSN (real browser — anti-bot doesn't trigger)
/// 3. After login, URL changes away from `/signin/`
/// 4. Extract JSESSIONID cookie from WebView
/// 5. Make our own HTTP request to `/gt7/info/api/token/` with the cookie
/// 6. Parse and store the access_token
///
/// The token lives ~50 minutes; the JSESSIONID cookie lives much longer. So
/// step 5 is repeatable on its own — see [exchangeSessionForToken] — and the
/// WebView is only needed for the very first sign-in.
class Gt7AuthService extends ChangeNotifier {
  Gt7AuthService();

  static const String _tokenKey = 'gt7_access_token';
  static const String _tokenExpireKey = 'gt7_access_token_expire';
  static const String _userIdKey = 'gt7_user_id';

  static const String _gt7BaseUrl = 'https://www.gran-turismo.com';
  static const String _signInUrl = '$_gt7BaseUrl/ru/gt7/user/signin/';
  static const String _tokenEndpoint = '$_gt7BaseUrl/ru/gt7/info/api/token/';

  /// Renew this long before the token actually expires.
  ///
  /// The endpoint hands out tokens with a ~50 minute lifetime, so a request
  /// fired just under the wire can still arrive expired.
  static const Duration _refreshMargin = Duration(minutes: 5);

  String? _accessToken;
  int? _accessTokenExpire;
  String? _userId;
  bool _isLoading = false;
  String? _error;
  Future<bool>? _inFlightRefresh;

  /// Current access token (null if not authenticated).
  String? get accessToken => _accessToken;

  /// Whether the user is authenticated with a non-expired token.
  ///
  /// `access_token_expire` is a Unix timestamp in **milliseconds** — verified
  /// against a live response — so it compares directly to
  /// [DateTime.millisecondsSinceEpoch].
  bool get isAuthenticated =>
      _accessToken != null &&
      _accessTokenExpire != null &&
      DateTime.now().millisecondsSinceEpoch < _accessTokenExpire!;

  /// Whether the token is gone, expired, or close enough to expiry that it
  /// should be renewed before the next request.
  bool get _needsRefresh =>
      _accessToken == null ||
      _accessTokenExpire == null ||
      DateTime.now().millisecondsSinceEpoch >
          _accessTokenExpire! - _refreshMargin.inMilliseconds;

  /// Time left on the current token, or null if there is none.
  Duration? get timeUntilExpiry => _accessTokenExpire == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          _accessTokenExpire!,
        ).difference(DateTime.now());

  /// GT7 user ID.
  String? get userId => _userId;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// URL to show in the WebView — GT7 sign-in page (which redirects to PSN OAuth).
  String get signInUrl => _signInUrl;

  /// Wipe every trace of the browsing session so the next visit to the sign-in
  /// page really is signed out.
  ///
  /// Deleting cookies alone is not enough: the site restores its session from
  /// `localStorage`/`IndexedDB`, and the HTTP cache can serve an authenticated
  /// page straight back. Each store is cleared through a different API, and
  /// those APIs are platform-split:
  ///
  /// - `deleteAllData()` is Android-only
  /// - `removeDataModifiedSince()` is iOS/macOS-only
  /// - both throw `UnimplementedError` elsewhere (Windows, Linux)
  ///
  /// So every step is attempted independently — one unsupported store must not
  /// stop the others from being cleared.
  Future<void> clearBrowsingData({bool includeToken = true}) async {
    final trace = Gt7AuthTrace.instance;

    Future<void> step(String name, Future<void> Function() action) async {
      try {
        await action();
        trace.log(TraceKind.cookie, 'cleared: $name');
      } catch (e) {
        trace.log(TraceKind.error, 'clear failed: $name', {
          'error': e.toString(),
        });
      }
    }

    await step(
      'cookies',
      () => CookieManager.instance().deleteAllCookies(),
    );
    await step(
      'http cache',
      () => InAppWebViewController.clearAllCache(),
    );

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await step(
          'web storage (android)',
          () => WebStorageManager.instance().deleteAllData(),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        await step(
          'website data (apple)',
          () => WebStorageManager.instance().removeDataModifiedSince(
            dataTypes: WebsiteDataType.ALL.toSet(),
            // Epoch — "everything ever stored".
            date: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        trace.log(
          TraceKind.cookie,
          'web storage clear unsupported on $defaultTargetPlatform — '
          'cookies and cache only',
        );
    }

    if (includeToken) {
      await _clearToken();
      notifyListeners();
    }
  }

  /// Whether the given [url] indicates a successful login.
  ///
  /// After PSN OAuth, the redirect chain is:
  /// 1. PSN → gran-turismo.com/ru/signin/?target=gt7&code=...
  /// 2. → gran-turismo.com/ru/gt7/user/ (or /gt7/user/mymenu/...)
  bool isLoginSuccessful(String url) {
    return (url.contains('/gt7/user/') && !url.contains('/gt7/user/signin')) ||
        (url.contains('/ru/signin/') && url.contains('code='));
  }

  /// Initialize — load the saved token, renewing it if it has gone stale.
  ///
  /// The JSESSIONID cookie lives in the shared cookie jar and outlives the
  /// ~50 minute token, so an expired token usually means a silent renewal,
  /// not a new login.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    _accessTokenExpire = prefs.getInt(_tokenExpireKey);
    _userId = prefs.getString(_userIdKey);

    Gt7AuthTrace.instance.log(TraceKind.token, 'init: loaded stored token', {
      'hasToken': _accessToken != null,
      'expiresIn': timeUntilExpiry?.toString(),
      'needsRefresh': _needsRefresh,
    });

    if (_needsRefresh && !await ensureFreshToken()) {
      await _clearToken();
    }
    notifyListeners();
  }

  /// Return a usable token, renewing from the session cookie when needed.
  ///
  /// Concurrent callers share one in-flight renewal instead of each firing
  /// their own request at the token endpoint.
  Future<bool> ensureFreshToken() {
    if (!_needsRefresh) return Future.value(true);
    return _inFlightRefresh ??= exchangeSessionForToken().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  /// Exchange the stored JSESSIONID for a fresh access token.
  ///
  /// Needs no WebView: the cookie jar is process-wide, so this works after a
  /// login and equally on a later launch when the session cookie is still
  /// valid but the token has expired.
  Future<bool> exchangeSessionForToken() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final trace = Gt7AuthTrace.instance;

    try {
      trace.log(TraceKind.token, 'exchangeSessionForToken: reading cookie jar');
      // 1. Read cookies from the WebView for gran-turismo.com
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri(_gt7BaseUrl),
      );
      trace.log(TraceKind.token, 'cookies for $_gt7BaseUrl', {
        'count': cookies.length,
        'names': cookies.map((c) => c.name).join(', '),
      });

      final jsessionid = cookies
          .where((c) => c.name == 'JSESSIONID')
          .map((c) => c.value)
          .firstOrNull;

      if (jsessionid == null) {
        _error = 'JSESSIONID cookie not found. Login may have failed.';
        trace.log(TraceKind.error, 'JSESSIONID missing — aborting exchange');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Make our own HTTP request to the token endpoint
      trace.log(TraceKind.token, 'GET $_tokenEndpoint', {
        'JSESSIONID': Gt7AuthTrace.mask(jsessionid),
      });
      final response = await http.get(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Cookie': 'JSESSIONID=$jsessionid',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/151.0.0.0 Safari/537.36',
          'Referer': '$_gt7BaseUrl/ru/gt7/user/discover/',
        },
      );
      trace.log(TraceKind.token, 'token endpoint responded', {
        'status': response.statusCode,
        'contentType': response.headers['content-type'],
        'bodyLength': response.body.length,
      });

      if (response.statusCode != 200) {
        _error = 'Token endpoint returned ${response.statusCode}';
        trace.log(TraceKind.error, 'non-200 from token endpoint', {
          'bodyPreview': response.body.substring(
            0,
            response.body.length > 300 ? 300 : response.body.length,
          ),
        });
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Parse the token response
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Log the full shape with secrets masked — this is what tells us which
      // fields the endpoint actually returns and in what units.
      trace.log(TraceKind.token, 'token payload', {
        'keys': data.keys.join(', '),
        for (final e in data.entries)
          e.key: _isSecretField(e.key)
              ? Gt7AuthTrace.mask(e.value?.toString())
              : e.value,
      });

      if (data['is_signed_in'] != true) {
        _error = 'Not signed in according to token endpoint.';
        trace.log(TraceKind.error, 'is_signed_in is not true');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _accessToken = data['access_token'] as String?;
      _accessTokenExpire = data['access_token_expire'] as int?;
      _userId = data['user_id'] as String?;

      _traceExpiryUnits(trace, _accessTokenExpire);

      if (_accessToken == null) {
        _error = 'No access_token in response.';
        trace.log(TraceKind.error, 'no access_token field in payload');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 4. Persist to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _accessToken!);
      await prefs.setInt(_tokenExpireKey, _accessTokenExpire ?? 0);
      if (_userId != null) {
        await prefs.setString(_userIdKey, _userId!);
      }

      trace.log(TraceKind.token, 'token persisted to SharedPreferences', {
        'userId': _userId,
        'isAuthenticated': isAuthenticated,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      _error = 'Failed to extract token: $e';
      trace.log(TraceKind.error, 'exchange threw', {
        'error': e.toString(),
        'stack': st.toString().split('\n').take(4).join(' | '),
      });
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  static bool _isSecretField(String key) =>
      key.contains('token') && !key.contains('expire');

  /// Report whether `access_token_expire` looks like milliseconds or seconds.
  ///
  /// [isAuthenticated] compares it against `millisecondsSinceEpoch`; if the
  /// endpoint returns seconds, that comparison is always false and the stored
  /// token is discarded on every launch.
  static void _traceExpiryUnits(Gt7AuthTrace trace, int? expire) {
    if (expire == null) {
      trace.log(TraceKind.error, 'access_token_expire is null');
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final asMs = DateTime.fromMillisecondsSinceEpoch(expire);
    final asSec = DateTime.fromMillisecondsSinceEpoch(expire * 1000);
    final looksLikeSeconds = expire < nowMs ~/ 100;

    trace.log(TraceKind.token, 'access_token_expire units check', {
      'raw': expire,
      'nowMs': nowMs,
      'ifMilliseconds': '$asMs (in ${asMs.difference(DateTime.now()).inMinutes} min)',
      'ifSeconds': '$asSec (in ${asSec.difference(DateTime.now()).inMinutes} min)',
      'verdict': looksLikeSeconds
          ? 'LOOKS LIKE SECONDS — isAuthenticated will always be false!'
          : 'looks like milliseconds — current comparison is correct',
    });
  }

  /// Force a token renewal from the session cookie, ignoring the margin.
  Future<bool> refreshToken() => exchangeSessionForToken();

  /// Drop the stored token after the API rejected it.
  ///
  /// Called on a 401 so the UI falls back to the login prompt instead of
  /// showing stale data behind a token the server no longer accepts.
  Future<void> invalidateToken() async {
    Gt7AuthTrace.instance.log(TraceKind.error, 'token invalidated by a 401');
    await _clearToken();
    notifyListeners();
  }

  /// Log out — drop the token and wipe the browsing session.
  ///
  /// Without the full wipe the next sign-in silently resumes the old session,
  /// which is not what "log out" means to anyone pressing the button.
  Future<void> logout() async {
    await clearBrowsingData();
    notifyListeners();
  }

  Future<void> _clearToken() async {
    _accessToken = null;
    _accessTokenExpire = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpireKey);
    await prefs.remove(_userIdKey);
  }
}
