import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import '../repositories/gt7_auth_repository.dart';
import '../services/gt7_api_service.dart';
import '../services/gt7_auth_trace.dart';

/// Full-screen page with an embedded WebView for PSN login.
///
/// The user sees the standard GT7 sign-in page and logs in through PSN.
/// Once authenticated, the page automatically detects the redirect and
/// extracts the token — no manual button press needed.
///
/// Every step is traced into [Gt7AuthTrace]: navigations and redirects,
/// in-page `fetch`/`XHR`, clicks (with `isTrusted` so synthetic clicks are
/// distinguishable from real ones), form posts, cookie jar snapshots and the
/// final token exchange. Tap the bug icon in the app bar to read the trace on
/// device, or copy it to the clipboard.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Domains whose cookie jars are dumped at each navigation checkpoint.
  static const List<String> _cookieDomains = [
    'https://www.gran-turismo.com',
    'https://web-api.gt7.game.gran-turismo.com',
    'https://ca.account.sony.com',
    'https://my.account.sony.com',
    'https://auth.api.sonyentertainmentnetwork.com',
  ];

  /// Debounce applied to URL-change signals. The GT7 site is a SPA, so a
  /// single logical navigation can emit several of them back to back.
  static const Duration _fastCheck = Duration(milliseconds: 400);

  /// Last-resort sweep for URL changes no callback reported.
  static const Duration _fallbackCheck = Duration(seconds: 3);

  /// How many times to look for the sign-in link before concluding there is
  /// none. The GT7 page is a SPA, so the link can appear after `onLoadStop`.
  static const int _maxSignInClickAttempts = 6;
  static const Duration _signInClickRetryDelay = Duration(milliseconds: 500);

  /// Hosts whose pages the user is meant to see — the PSN sign-in screens.
  /// Everything else in the flow is plumbing and stays behind the loader.
  static final RegExp _authProviderHost = RegExp(
    r'(^|\.)account\.sony\.com$'
    r'|(^|\.)sonyentertainmentnetwork\.com$'
    r'|(^|\.)playstation\.com$',
    caseSensitive: false,
  );

  final Gt7AuthTrace _trace = Gt7AuthTrace.instance;

  InAppWebViewController? _webViewController;
  Timer? _checkTimer;
  DateTime? _pendingCheckAt;
  bool _extracting = false;
  bool _showTrace = false;

  /// Whether the current page is one the user should see.
  bool _onAuthProviderPage = false;

  /// Escape hatch from the loader, in case the flow stalls somewhere we did
  /// not anticipate and the user needs to see what the page is actually doing.
  bool _forceShowPage = false;

  /// True once the PSN screen has been shown, so the loader afterwards can say
  /// "finishing" rather than "connecting".
  bool _psnScreenSeen = false;

  String _status = 'Opening sign-in…';

  bool get _pageVisible => (_onAuthProviderPage && !_extracting) || _forceShowPage;

  @override
  void initState() {
    super.initState();
    _trace.start('PSN login flow');
    _trace.addListener(_onTraceChanged);
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _trace.removeListener(_onTraceChanged);
    super.dispose();
  }

  void _onTraceChanged() {
    if (mounted && _showTrace) setState(() {});
  }

  // ---------------------------------------------------------------------
  // What the user sees
  // ---------------------------------------------------------------------

  static bool _isAuthProviderUrl(String? url) {
    if (url == null) return false;
    final host = Uri.tryParse(url)?.host;
    return host != null && host.isNotEmpty && _authProviderHost.hasMatch(host);
  }

  /// Reveal the WebView on PSN pages, hide it everywhere else.
  ///
  /// Called from every signal that can change the URL — including the SPA's
  /// own history events, which produce no page load.
  void _updateVisibility(String? url) {
    if (!mounted) return;

    final onProvider = _isAuthProviderUrl(url);
    if (onProvider == _onAuthProviderPage) return;

    _trace.log(
      TraceKind.nav,
      onProvider ? 'showing PSN sign-in page' : 'hiding page behind loader',
      {'url': _shortUrl(url)},
    );

    setState(() {
      _onAuthProviderPage = onProvider;
      if (onProvider) {
        _psnScreenSeen = true;
      } else if (!_extracting) {
        _status = _psnScreenSeen
            ? 'Finishing sign-in…'
            : 'Connecting to PlayStation…';
      }
    });
  }

  // ---------------------------------------------------------------------
  // Tracing helpers
  // ---------------------------------------------------------------------

  /// Snapshot every cookie jar we care about, with values masked.
  Future<void> _dumpCookies(String checkpoint) async {
    for (final domain in _cookieDomains) {
      try {
        final cookies = await CookieManager.instance().getCookies(
          url: WebUri(domain),
        );
        if (cookies.isEmpty) continue;
        _trace.log(TraceKind.cookie, '$checkpoint — $domain', {
          'count': cookies.length,
          for (final c in cookies)
            c.name: '${Gt7AuthTrace.mask(c.value)}'
                '${c.isHttpOnly == true ? ' httpOnly' : ''}'
                '${c.isSecure == true ? ' secure' : ''}',
        });
      } catch (e) {
        _trace.log(TraceKind.error, 'cookie dump failed for $domain', {
          'error': e.toString(),
        });
      }
    }
  }

  /// Handle one message from the injected page script.
  void _onPageTrace(List<dynamic> args) {
    if (args.isEmpty) return;
    final payload = args.first;
    if (payload is! Map) return;

    final type = payload['t']?.toString() ?? 'unknown';
    final data = payload['d'];
    final href = payload['href']?.toString();
    final frame = payload['frame']?.toString();

    // In-page URL changes, reported by our own hooks. Same signal as
    // onUpdateVisitedHistory, but coming from JS it works on every platform,
    // including ones where that callback is not implemented. Handled before
    // the logging block so login detection does not depend on tracing.
    if (frame == 'main' &&
        (type.startsWith('history:') || type.startsWith('loc:'))) {
      _updateVisibility(href);
      _scheduleCheck('page:$type');
    }

    if (!Gt7AuthTrace.enabled) return;

    final kind = switch (type.split(':').first) {
      'fetch' || 'xhr' => TraceKind.js,
      'click' => TraceKind.click,
      'submit' => TraceKind.form,
      'dom' => TraceKind.dom,
      'cookie' => TraceKind.cookie,
      'loc' || 'history' || 'page' => TraceKind.nav,
      _ => TraceKind.js,
    };

    // Captured HTTP bodies are pulled out of the payload so they print on
    // their own lines instead of being escaped into the nested JSON blob.
    Object? rest = data;
    String? reqBody;
    String? resBody;
    if (data is Map) {
      final copy = Map<String, Object?>.from(data.cast<String, Object?>());
      reqBody = copy.remove('reqBody') as String?;
      resBody = copy.remove('resBody') as String?;
      rest = copy;
    }

    _trace.log(kind, 'page → $type', {
      if (frame != null && frame != 'main') 'frame': frame,
      'on': _shortUrl(href),
      'data': rest is Map || rest is List ? jsonEncode(rest) : rest,
      if (reqBody != null) 'reqBody': Gt7AuthTrace.redact(reqBody),
      if (resBody != null) 'resBody': Gt7AuthTrace.redact(resBody),
    });
  }

  /// Query parameters worth keeping on an ordinary URL.
  static const Set<String> _interestingParams = {
    'code',
    'state',
    'redirect_uri',
    'client_id',
    'response_type',
    'target',
    'scope',
    'error',
    'error_description',
  };

  /// Hosts and paths where the *whole* query string matters — an OAuth
  /// authorize URL is only reproducible if every parameter is known, including
  /// `code_challenge`, `nonce` and the Sony-specific ones.
  static final RegExp _authUrl = RegExp(
    r'account\.sony\.com'
    r'|sonyentertainmentnetwork\.com'
    r'|/oauth/|/authz/|/signin',
    caseSensitive: false,
  );

  /// Trim query strings down so the log stays readable, but keep the params
  /// that actually matter for the OAuth flow. Secret-looking values are masked
  /// whether or not they are kept in full.
  static String? _shortUrl(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final base = '${uri.scheme}://${uri.host}${uri.path}';
    if (!uri.hasQuery) return base;

    // Exact names only: `code` is a single-use credential and gets masked,
    // while `code_challenge` is public PKCE data we need in full.
    const alwaysMask = {
      'code',
      'state',
      'access_token',
      'id_token',
      'refresh_token',
    };

    final full = _authUrl.hasMatch(url);
    final kept = <String, String>{};
    for (final e in uri.queryParameters.entries) {
      if (!full && !_interestingParams.contains(e.key)) continue;
      if (alwaysMask.contains(e.key.toLowerCase())) {
        kept[e.key] = Gt7AuthTrace.mask(e.value);
        continue;
      }
      // redact() preserves the `key=` prefix, so strip exactly that much —
      // splitting on '=' would corrupt base64url values that end in padding.
      final redacted = Gt7AuthTrace.redact('${e.key}=${e.value}');
      kept[e.key] = redacted.substring(e.key.length + 1);
    }

    if (kept.isEmpty) {
      return '$base?…(${uri.queryParameters.length} params)';
    }
    final q = kept.entries.map((e) => '${e.key}=${e.value}').join('&');
    final omitted = uri.queryParameters.length - kept.length;
    return omitted > 0 ? '$base?$q  …(+$omitted more)' : '$base?$q';
  }

  // ---------------------------------------------------------------------
  // Login detection
  // ---------------------------------------------------------------------

  /// Queue a login check.
  ///
  /// The GT7 site swaps to the authenticated page with `history.replaceState`,
  /// which fires no page load at all — so the check is driven by URL-change
  /// signals rather than by load events, and several of them may arrive for
  /// one logical navigation. Only the earliest pending check survives: a later
  /// fallback never postpones a check that is already due sooner.
  void _scheduleCheck(String reason, {Duration delay = _fastCheck}) {
    if (_extracting) return;

    final dueAt = DateTime.now().add(delay);
    if (_pendingCheckAt != null && _pendingCheckAt!.isBefore(dueAt)) {
      _trace.log(TraceKind.nav, 'check already pending — $reason ignored', {
        'dueInMs': _pendingCheckAt!.difference(DateTime.now()).inMilliseconds,
      });
      return;
    }

    _checkTimer?.cancel();
    _pendingCheckAt = dueAt;
    _trace.log(TraceKind.nav, 'check scheduled', {
      'reason': reason,
      'inMs': delay.inMilliseconds,
    });
    _checkTimer = Timer(delay, () {
      _pendingCheckAt = null;
      if (mounted) _checkAndExtract(reason);
    });
  }

  /// Toggle page instrumentation on the PSN domains.
  ///
  /// The script is installed at document start, so the change only takes
  /// effect on a fresh load — the WebView is reloaded here rather than leaving
  /// the switch showing a state the page does not actually have.
  Future<void> _setInstrumentAuthPages(bool value) async {
    setState(() => Gt7AuthTrace.instrumentAuthProviderPages = value);
    _trace.log(
      TraceKind.nav,
      'PSN page instrumentation ${value ? 'ENABLED' : 'disabled'} — reloading',
    );
    await _webViewController?.reload();
  }

  /// Wipe the browsing session and reload the sign-in page from scratch.
  ///
  /// The site keeps the player signed in across app launches, so without this
  /// the sign-in page is never actually reachable once you have logged in once.
  Future<void> _resetSession() async {
    final authService = context.read<Gt7AuthRepositoryImpl>().authService;

    _checkTimer?.cancel();
    _pendingCheckAt = null;
    setState(() {
      _extracting = false;
      // Back to a clean slate: the loader should behave as on a first open,
      // not carry over "finishing" or a manually revealed page.
      _onAuthProviderPage = false;
      _forceShowPage = false;
      _psnScreenSeen = false;
      _status = 'Clearing session…';
    });

    _trace.log(TraceKind.cookie, '=== manual session reset ===');
    await authService.clearBrowsingData();
    await _dumpCookies('after session reset');

    await _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(authService.signInUrl)),
    );

    if (!mounted) return;
    setState(() => _status = 'Opening sign-in…');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session cleared — reloading sign-in page')),
    );
  }

  /// Check the current URL and extract token if login is detected.
  Future<void> _checkAndExtract(String reason) async {
    if (_webViewController == null || _extracting) return;

    final url = await _webViewController!.getUrl();
    if (url == null || !mounted) return;

    final urlString = url.toString();
    final repo = context.read<Gt7AuthRepositoryImpl>();
    final authService = repo.authService;
    final success = authService.isLoginSuccessful(urlString);

    _trace.log(TraceKind.nav, 'checkAndExtract($reason)', {
      'url': _shortUrl(urlString),
      'isLoginSuccessful': success,
    });

    if (!success) return;

    // Claim the extraction slot before the next await so a concurrent
    // onLoadStop/onProgressChanged cannot start a second exchange.
    _extracting = true;
    setState(() => _status = 'Login detected! Extracting token…');

    await _dumpCookies('before token exchange');

    final ok = await repo.onLoginSuccess();
    _trace.log(
      ok ? TraceKind.token : TraceKind.error,
      'token exchange ${ok ? 'succeeded' : 'failed'}',
      {'error': authService.error},
    );

    if (!mounted) return;

    if (ok) {
      setState(() => _status = 'Loading profile images…');

      final apiService = context.read<Gt7ApiService>();
      _trace.log(TraceKind.dom, 'scraping profile page for image URLs', {
        'profile': apiService.profile?.toString(),
      });
      await apiService.scrapeImageUrls(_webViewController!);
      _trace.log(TraceKind.dom, 'scrape finished', {
        'avatarUrl': apiService.profile?.avatarUrl,
        'coverUrl': apiService.profile?.coverUrl,
        'driverUrl': apiService.profile?.driverUrl,
      });

      if (!mounted) return;
      setState(() => _status = 'Success! Redirecting…');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _extracting = false;
        _status = 'Token extraction failed: ${authService.error ?? "unknown error"}';
      });
    }
  }

  // ---------------------------------------------------------------------
  // Sign-in link
  // ---------------------------------------------------------------------

  /// Click the sign-in link on the GT7 page, retrying while the SPA renders.
  ///
  /// The link is absent in two very different situations: the page has not
  /// finished building it yet, and the player is already signed in — in which
  /// case the site swaps itself to the profile page. Retrying tells the two
  /// apart; when the link never appears, the token check settles it.
  Future<void> _clickSignInLink(InAppWebViewController controller) async {
    for (var attempt = 1; attempt <= _maxSignInClickAttempts; attempt++) {
      if (!mounted || _extracting) return;

      final raw = await controller.evaluateJavascript(source: _signInClickJs);
      final result = _decodeJsResult(raw);

      if (result != null && result['matched'] != null) {
        _trace.log(TraceKind.click, 'sign-in link clicked', {
          'attempt': '$attempt/$_maxSignInClickAttempts',
          'selector': result['matched'],
          'element': jsonEncode(result['el']),
        });
        return;
      }

      _trace.log(TraceKind.click, 'no sign-in link yet', {
        'attempt': '$attempt/$_maxSignInClickAttempts',
        // On the last attempt, dump what the page does offer, so a changed
        // layout is visible in the trace rather than just "not found".
        'candidates': attempt == _maxSignInClickAttempts
            ? jsonEncode(result?['candidates'])
            : null,
      });

      await Future<void>.delayed(_signInClickRetryDelay);
    }

    if (!mounted || _extracting) return;
    _trace.log(
      TraceKind.click,
      'sign-in link never appeared — checking for an existing session',
    );
    _scheduleCheck('signInLink:absent', delay: Duration.zero);
  }

  static Map<String, dynamic>? _decodeJsResult(Object? raw) {
    if (raw == null) return null;
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authService = context.read<Gt7AuthRepositoryImpl>().authService;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in to PlayStation'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out of the site and reload',
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: _resetSession,
          ),
          IconButton(
            tooltip: 'Copy trace to clipboard',
            icon: const Icon(Icons.copy_all),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _trace.dump()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied ${_trace.length} trace lines')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Show trace',
            icon: Icon(_showTrace ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () => setState(() => _showTrace = !_showTrace),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(authService.signInUrl)),
            // Always injected — its history hooks drive login detection. Only
            // body capture is tied to tracing, and the script keeps itself off
            // Sony's sign-in pages, whose anti-bot sensors reject a session
            // with overridden native functions.
            initialUserScripts: UnmodifiableListView<UserScript>([
              UserScript(
                source: gt7TraceUserScript(
                  captureBodies: Gt7AuthTrace.enabled,
                  instrumentAuthProviderPages:
                      Gt7AuthTrace.instrumentAuthProviderPages,
                ),
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                forMainFrameOnly: false,
              ),
            ]),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              transparentBackground: false,
              useShouldOverrideUrlLoading: true,
              thirdPartyCookiesEnabled: true,
              sharedCookiesEnabled: true,
              // Tracing hooks — these callbacks are inert without their flag.
              useOnLoadResource: true,
              useOnNavigationResponse: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              controller.addJavaScriptHandler(
                handlerName: 'gt7trace',
                callback: _onPageTrace,
              );
              _trace.log(TraceKind.load, 'WebView created', {
                'initialUrl': authService.signInUrl,
              });
            },
            onLoadStart: (controller, url) async {
              _trace.log(TraceKind.load, 'onLoadStart', {
                'url': _shortUrl(url?.toString()),
              });
              _updateVisibility(url?.toString());
              await _dumpCookies('onLoadStart');
            },
            onPageCommitVisible: (controller, url) {
              _trace.log(TraceKind.load, 'onPageCommitVisible', {
                'url': _shortUrl(url?.toString()),
              });
            },
            onTitleChanged: (controller, title) {
              _trace.log(TraceKind.load, 'onTitleChanged', {'title': title});
            },
            // Primary login signal: fires for real navigations *and* for the
            // SPA's history.replaceState swap to the authenticated page.
            onUpdateVisitedHistory: (controller, url, isReload) {
              _trace.log(TraceKind.nav, 'onUpdateVisitedHistory', {
                'url': _shortUrl(url?.toString()),
                'isReload': isReload,
              });
              _updateVisibility(url?.toString());
              _scheduleCheck('onUpdateVisitedHistory');
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final req = navigationAction.request;
              _trace.log(TraceKind.nav, 'shouldOverrideUrlLoading → ALLOW', {
                'url': _shortUrl(req.url?.toString()),
                'method': req.method,
                'mainFrame': navigationAction.isForMainFrame,
                'isRedirect': navigationAction.isRedirect,
                'navigationType': navigationAction.navigationType?.toString(),
                'hasBody': req.body != null,
              });
              // Earliest signal there is — reveals the PSN screen as the
              // navigation to it starts, not after it finishes loading.
              if (navigationAction.isForMainFrame) {
                _updateVisibility(req.url?.toString());
              }
              return NavigationActionPolicy.ALLOW;
            },
            onNavigationResponse: (controller, navigationResponse) async {
              final res = navigationResponse.response;
              _trace.log(TraceKind.http, 'onNavigationResponse', {
                'url': _shortUrl(res?.url?.toString()),
                'status': res?.statusCode,
                'forMainFrame': navigationResponse.isForMainFrame,
                'setCookie': res?.headers?.entries
                    .where((h) => h.key.toLowerCase() == 'set-cookie')
                    .map((h) => Gt7AuthTrace.mask(h.value.toString()))
                    .join(' | '),
                'location': res?.headers?.entries
                    .where((h) => h.key.toLowerCase() == 'location')
                    .map((h) => h.value.toString())
                    .join(' | '),
              });
              return NavigationResponseAction.ALLOW;
            },
            onLoadResource: (controller, resource) {
              final url = resource.url?.toString() ?? '';
              if (url.isEmpty || Gt7AuthTrace.isBoringResource(url)) return;
              _trace.log(TraceKind.http, 'resource', {
                'url': _shortUrl(url),
                'initiator': resource.initiatorType,
                'ms': resource.duration?.round(),
              });
            },
            onReceivedError: (controller, request, error) {
              _trace.log(TraceKind.error, 'onReceivedError', {
                'url': _shortUrl(request.url.toString()),
                'type': error.type.toString(),
                'description': error.description,
              });
            },
            onReceivedHttpError: (controller, request, errorResponse) {
              _trace.log(TraceKind.error, 'onReceivedHttpError', {
                'url': _shortUrl(request.url.toString()),
                'status': errorResponse.statusCode,
                'reason': errorResponse.reasonPhrase,
              });
            },
            onLoadStop: (controller, url) async {
              if (url == null) return;
              _trace.log(TraceKind.load, 'onLoadStop', {
                'url': _shortUrl(url.toString()),
              });
              _updateVisibility(url.toString());
              await _dumpCookies('onLoadStop');

              _scheduleCheck('onLoadStop');

              // On the GT7 sign-in page, press the button for the user. This
              // retries in the background; the token check above runs anyway,
              // so an already-signed-in session is not held up by it.
              if (url.toString().contains('/gt7/user/signin')) {
                unawaited(_clickSignInLink(controller));
              }
            },
            onProgressChanged: (controller, progress) {
              if (progress != 100) return;
              _trace.log(TraceKind.load, 'onProgressChanged 100%');
              _scheduleCheck('onProgressChanged', delay: _fallbackCheck);
            },
            onConsoleMessage: (controller, consoleMessage) {
              _trace.log(TraceKind.console, consoleMessage.message, {
                'level': consoleMessage.messageLevel.toString(),
              });
            },
          ),

          // The WebView stays mounted and loading underneath; the loader
          // simply covers it. Only the PSN sign-in screens are uncovered —
          // the GT7 pages before and after it are plumbing.
          if (!_pageVisible && !_showTrace) _buildOverlay(),

          // Live trace panel
          if (_showTrace) _buildTracePanel(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    final theme = Theme.of(context);
    return Positioned.fill(
      // Opaque by construction: a translucent colour here would let the GT7
      // page show through, which is the thing being hidden.
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00D1E8)),
              const SizedBox(height: 20),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              // If the flow stalls somewhere unexpected — a captcha, a
              // consent screen, an error page — the loader would hide it
              // forever. This is the way out.
              const SizedBox(height: 28),
              TextButton(
                onPressed: () {
                  _trace.log(TraceKind.nav, 'user revealed the page manually');
                  setState(() => _forceShowPage = true);
                },
                child: const Text('Show the page'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTracePanel() {
    final entries = _trace.entries.reversed.toList();
    return Positioned.fill(
      child: Container(
        color: const Color(0xF00E1116),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${entries.length} events  ·  newest first',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _trace.clear(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            // Tracing the PSN pages trips their anti-bot sensors, so signing
            // in while this is on will fail at the credential POST. It exists
            // to study that flow, not to use it.
            SwitchListTile(
              dense: true,
              value: Gt7AuthTrace.instrumentAuthProviderPages,
              onChanged: _setInstrumentAuthPages,
              title: const Text(
                'Trace PSN sign-in pages',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              subtitle: const Text(
                'Anti-bot will reject the sign-in — research only',
                style: TextStyle(color: Color(0xFFFFD166), fontSize: 11),
              ),
            ),
            const Divider(height: 1, color: Colors.white24),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 12,
                  color: Colors.white12,
                ),
                itemBuilder: (context, i) => SelectableText(
                  entries[i].format(),
                  style: TextStyle(
                    color: _colorFor(entries[i].kind),
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorFor(TraceKind kind) => switch (kind) {
    TraceKind.error => const Color(0xFFFF6B6B),
    TraceKind.token => const Color(0xFF7CFFB2),
    TraceKind.click => const Color(0xFFFFD166),
    TraceKind.form => const Color(0xFFFFA9F9),
    TraceKind.nav => const Color(0xFF00D1E8),
    TraceKind.cookie => const Color(0xFFB49BFF),
    TraceKind.js => const Color(0xFF9BE7FF),
    TraceKind.console => Colors.white54,
    _ => Colors.white70,
  };

  /// Clicks the sign-in link and reports back as JSON, so the trace records
  /// *why* a given element was chosen — or what was on the page when none
  /// matched.
  static const String _signInClickJs = r'''
    (function () {
      function describe(el) {
        return {
          tag: el.tagName,
          href: el.getAttribute('href'),
          text: String(el.innerText || el.value || '').trim().slice(0, 60)
        };
      }

      var link = document.querySelector('a[href*="oauth/authorize"]');
      if (link) {
        var info = describe(link);
        link.click();
        return JSON.stringify({ matched: 'a[href*=oauth/authorize]', el: info });
      }

      var links = document.querySelectorAll('a');
      for (var i = 0; i < links.length; i++) {
        var t = links[i].textContent.trim();
        if (t === 'Вход' || t === 'Sign in' || t === 'Login') {
          var info2 = describe(links[i]);
          links[i].click();
          return JSON.stringify({ matched: 'text:' + t, el: info2 });
        }
      }

      // Nothing matched — report what *is* on the page so the trace explains it.
      var all = [];
      var nodes = document.querySelectorAll('a[href],button');
      for (var j = 0; j < nodes.length && all.length < 25; j++) {
        all.push(describe(nodes[j]));
      }
      return JSON.stringify({ matched: null, candidates: all });
    })()
  ''';
}
