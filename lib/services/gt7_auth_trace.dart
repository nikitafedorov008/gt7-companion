import 'package:flutter/foundation.dart';

/// Category of a trace entry — used for the prefix tag and for filtering.
enum TraceKind {
  nav, // shouldOverrideUrlLoading / redirect decisions
  load, // onLoadStart / onLoadStop / onPageCommitVisible
  http, // resource loads, HTTP errors, navigation responses
  js, // fetch / XHR intercepted inside the page
  click, // clicks captured in the page (with isTrusted)
  form, // form submissions
  dom, // DOM inspection dumps
  cookie, // cookie jar snapshots and document.cookie writes
  token, // the JSESSIONID -> access_token exchange
  console, // WebView console messages
  error,
}

extension on TraceKind {
  String get tag => switch (this) {
    TraceKind.nav => 'NAV',
    TraceKind.load => 'LOAD',
    TraceKind.http => 'HTTP',
    TraceKind.js => 'JS',
    TraceKind.click => 'CLICK',
    TraceKind.form => 'FORM',
    TraceKind.dom => 'DOM',
    TraceKind.cookie => 'COOKIE',
    TraceKind.token => 'TOKEN',
    TraceKind.console => 'CONSOLE',
    TraceKind.error => 'ERROR',
  };
}

class TraceEntry {
  TraceEntry({
    required this.at,
    required this.sinceStart,
    required this.kind,
    required this.message,
    this.data,
  });

  final DateTime at;
  final Duration sinceStart;
  final TraceKind kind;
  final String message;
  final Map<String, Object?>? data;

  String format() {
    final t = (sinceStart.inMilliseconds / 1000).toStringAsFixed(3).padLeft(8);
    final tag = kind.tag.padRight(7);
    final buf = StringBuffer('[+${t}s] $tag $message');
    if (data != null && data!.isNotEmpty) {
      for (final e in data!.entries) {
        if (e.value == null) continue;
        final v = e.value.toString();
        if (v.isEmpty) continue;
        buf.write('\n              ${e.key}: $v');
      }
    }
    return buf.toString();
  }
}

/// Collects a timestamped trace of everything that happens during the PSN
/// login flow: navigations, redirects, in-page fetch/XHR, clicks (real vs
/// synthetic), form posts, cookie jar snapshots and the final token exchange.
///
/// Sensitive values are masked via [mask] before they ever reach the log.
class Gt7AuthTrace extends ChangeNotifier {
  Gt7AuthTrace._();

  static final Gt7AuthTrace instance = Gt7AuthTrace._();

  /// Set to false to silence the whole subsystem.
  static bool enabled = kDebugMode;

  /// Install the page script on Sony's sign-in pages too.
  ///
  /// Off by default because it makes signing in fail — see
  /// [gt7TraceUserScript]. Turn it on only to study the PSN flow itself.
  static bool instrumentAuthProviderPages = false;

  /// Resource URLs matching this are not logged (static assets, noise).
  static final RegExp _boringResource = RegExp(
    r'\.(png|jpe?g|gif|webp|svg|ico|css|js|woff2?|ttf|mp4|m4a)(\?|$)',
    caseSensitive: false,
  );

  final List<TraceEntry> _entries = [];
  DateTime? _start;

  List<TraceEntry> get entries => List.unmodifiable(_entries);
  int get length => _entries.length;

  /// Mask a secret so the shape stays visible but the value does not leak.
  static String mask(String? value) {
    if (value == null) return '<null>';
    if (value.isEmpty) return '<empty>';
    if (value.length <= 12) return '***(len=${value.length})';
    return '${value.substring(0, 6)}…${value.substring(value.length - 4)} '
        '(len=${value.length})';
  }

  /// True for resources not worth logging.
  static bool isBoringResource(String url) => _boringResource.hasMatch(url);

  /// Field-name fragments that mark a value as secret.
  ///
  /// Covers account identifiers as well as credentials: the PSN sign-in body
  /// carries `username` next to `password`, and an email address in a log the
  /// user is about to paste somewhere is its own kind of leak.
  static const String _secretNamePattern =
      r'token|npsso|password|passwd|secret|session|jsessionid|credential|'
      r'authorization|otp|pin|code_verifier|client_secret|'
      r'username|user_name|email|signinid|signin_id|mail';

  /// JSON string fields whose *value* must never reach the log verbatim.
  ///
  /// Only string values match, so numeric fields such as
  /// `access_token_expire` stay readable — which is the whole point of
  /// capturing these bodies.
  static final RegExp _secretJsonField = RegExp(
    '"([A-Za-z0-9_]*(?:$_secretNamePattern)[A-Za-z0-9_]*)"\\s*:\\s*"([^"]*)"',
    caseSensitive: false,
  );

  /// The same, for `application/x-www-form-urlencoded` bodies and query
  /// strings. The PSN sign-in form posts credentials this way, and the JSON
  /// pattern above would sail straight past them.
  static final RegExp _secretFormField = RegExp(
    '(^|[&?])([A-Za-z0-9_.\\-\\[\\]]*(?:$_secretNamePattern)[A-Za-z0-9_.\\-\\[\\]]*)=([^&\\s]*)',
    caseSensitive: false,
  );

  /// Mask secret-looking fields inside a captured request/response body.
  ///
  /// Covers both encodings because a body is logged before anything knows its
  /// content type — and a missed password is not a recoverable mistake.
  static String redact(String body) => body
      .replaceAllMapped(
        _secretJsonField,
        (m) => '"${m[1]}":"${mask(m[2])}"',
      )
      .replaceAllMapped(
        _secretFormField,
        (m) => '${m[1]}${m[2]}=${mask(m[3])}',
      );

  void start(String label) {
    _entries.clear();
    _start = DateTime.now();
    log(TraceKind.load, '=== TRACE START: $label ===');
  }

  void log(TraceKind kind, String message, [Map<String, Object?>? data]) {
    if (!enabled) return;
    final now = DateTime.now();
    _start ??= now;
    final entry = TraceEntry(
      at: now,
      sinceStart: now.difference(_start!),
      kind: kind,
      message: message,
      data: data,
    );
    _entries.add(entry);
    debugPrint('[gt7auth] ${entry.format()}');
    notifyListeners();
  }

  /// Whole trace as plain text — for clipboard export or a bug report.
  String dump() => _entries.map((e) => e.format()).join('\n');

  void clear() {
    _entries.clear();
    _start = null;
    notifyListeners();
  }
}

/// Build the page script for injection at document start.
///
/// This script is always injected, tracing on or off: its `history`/`location`
/// hooks are what tell the app that the SPA swapped to the authenticated page,
/// and login detection depends on them. [captureBodies] controls only the
/// debugging extra — recording request and response payloads — which must stay
/// off in release builds.
///
/// [instrumentAuthProviderPages] opts the Sony sign-in pages back in. Leave it
/// off: the script replaces `fetch`, `XMLHttpRequest.prototype.send`, the
/// `document.cookie` setter and `history.pushState`, and detecting exactly
/// those overrides is what the anti-bot sensors on those pages are for. A
/// traced sign-in gets a 403 from `/api/v1/ssocookie`. Turn it on only to
/// study the PSN flow, knowing the sign-in itself will likely fail.
String gt7TraceUserScript({
  required bool captureBodies,
  bool instrumentAuthProviderPages = false,
}) =>
    'window.__gt7CaptureBodies = $captureBodies;\n'
    'window.__gt7InstrumentAuthPages = $instrumentAuthProviderPages;\n'
    '$_kGt7TraceUserScript';

/// JavaScript injected at document start into every frame of the login flow.
///
/// Reports back through the `gt7trace` handler registered on the controller.
/// Messages are queued until the `flutter_inappwebview` bridge exists, so
/// nothing is lost when the script runs before the bridge is installed.
const String _kGt7TraceUserScript = r'''
(function () {
  if (window.__gt7TraceInstalled) return;
  window.__gt7TraceInstalled = true;

  // Anti-bot sensors on the Sony sign-in pages fingerprint the page for
  // exactly the kind of native-function overrides installed below, and a
  // flagged session gets a 403 on the credential POST. Stay out of them
  // unless explicitly asked.
  var AUTH_PROVIDER_HOST =
    /(^|\.)account\.sony\.com$|(^|\.)sonyentertainmentnetwork\.com$|(^|\.)playstation\.com$/i;
  if (!window.__gt7InstrumentAuthPages &&
      AUTH_PROVIDER_HOST.test(location.hostname)) {
    return;
  }

  var queue = [];

  // Only these hosts get their request/response bodies captured. Everything
  // else (analytics, static assets) is logged by URL alone. The Sony hosts
  // are here to expose the PSN OAuth exchange; every captured body still goes
  // through the Dart-side redactor before it is logged.
  var CAPTURE = new RegExp(
    'web-api\\.gt7\\.game\\.gran-turismo\\.com' +
    '|/info/api/token/' +
    '|ca\\.account\\.sony\\.com' +
    '|my\\.account\\.sony\\.com' +
    '|auth\\.api\\.sonyentertainmentnetwork\\.com' +
    '|/oauth/|/authz/|/signin'
  );
  var MAX_BODY = 4000;

  function wantsBody(url) {
    if (!window.__gt7CaptureBodies) return false;
    try { return CAPTURE.test(String(url)); } catch (e) { return false; }
  }

  function clip(text) {
    if (text == null) return null;
    var s = String(text);
    return s.length > MAX_BODY
      ? s.slice(0, MAX_BODY) + '…[+' + (s.length - MAX_BODY) + ' more]'
      : s;
  }

  function bridgeReady() {
    return !!(window.flutter_inappwebview && window.flutter_inappwebview.callHandler);
  }

  function deliver(payload) {
    try { window.flutter_inappwebview.callHandler('gt7trace', payload); return true; }
    catch (e) { return false; }
  }

  function send(type, data) {
    var payload = {
      t: type,
      d: data,
      href: location.href,
      frame: (window.top === window.self) ? 'main' : 'iframe'
    };
    if (bridgeReady() && deliver(payload)) return;
    queue.push(payload);
  }

  setInterval(function () {
    if (!queue.length || !bridgeReady()) return;
    var batch = queue.splice(0, queue.length);
    for (var i = 0; i < batch.length; i++) deliver(batch[i]);
  }, 150);

  send('page:init', { readyState: document.readyState, referrer: document.referrer });

  // --- fetch -------------------------------------------------------------
  try {
    var origFetch = window.fetch;
    if (origFetch && !origFetch.__gt7) {
      window.fetch = function (input, init) {
        var url = (typeof input === 'string') ? input : (input && input.url);
        var method = (init && init.method) || (input && input.method) || 'GET';
        var capture = wantsBody(url);
        send('fetch', {
          url: url,
          method: method,
          creds: init && init.credentials,
          reqBody: capture && init ? clip(init.body) : undefined
        });
        return origFetch.apply(this, arguments).then(function (res) {
          var info = {
            url: url, status: res.status,
            redirected: res.redirected, finalUrl: res.url
          };
          if (!capture) { send('fetch:done', info); return res; }
          // Read from a clone so the page still gets an unconsumed body.
          res.clone().text().then(function (body) {
            info.resBody = clip(body);
            send('fetch:done', info);
          }, function () { send('fetch:done', info); });
          return res;
        }, function (err) {
          send('fetch:error', { url: url, error: String(err) });
          throw err;
        });
      };
      window.fetch.__gt7 = true;
    }
  } catch (e) {}

  // --- XMLHttpRequest ----------------------------------------------------
  try {
    var open = XMLHttpRequest.prototype.open;
    var send_ = XMLHttpRequest.prototype.send;
    if (!open.__gt7) {
      XMLHttpRequest.prototype.open = function (m, u) {
        this.__gt7req = { method: m, url: u };
        return open.apply(this, arguments);
      };
      XMLHttpRequest.prototype.open.__gt7 = true;
      XMLHttpRequest.prototype.send = function (body) {
        var self = this;
        var req = self.__gt7req || {};
        var capture = wantsBody(req.url);
        send('xhr', {
          method: req.method,
          url: req.url,
          reqBody: capture ? clip(body) : undefined
        });
        self.addEventListener('loadend', function () {
          var info = {
            url: req.url, status: self.status, responseURL: self.responseURL
          };
          if (capture) {
            try {
              // responseText throws for non-text responseTypes; ignore those.
              info.resBody = clip(self.responseText);
            } catch (e) {}
          }
          send('xhr:done', info);
        });
        return send_.apply(this, arguments);
      };
    }
  } catch (e) {}

  // --- clicks (capture phase, before the page's own handlers) ------------
  document.addEventListener('click', function (ev) {
    try {
      var raw = ev.target;
      var el = (raw && raw.closest)
        ? (raw.closest('a,button,input[type=submit],[role=button]') || raw)
        : raw;
      send('click', {
        // isTrusted=false means the click came from JS (.click()), not a human
        isTrusted: ev.isTrusted,
        tag: el.tagName,
        id: el.id || null,
        cls: el.className ? String(el.className).slice(0, 100) : null,
        href: el.getAttribute ? el.getAttribute('href') : null,
        type: el.getAttribute ? el.getAttribute('type') : null,
        text: String(el.innerText || el.value || '').trim().slice(0, 80)
      });
    } catch (e) {}
  }, true);

  // --- form submissions --------------------------------------------------
  document.addEventListener('submit', function (ev) {
    try {
      var f = ev.target;
      var fields = [];
      for (var i = 0; i < f.elements.length; i++) {
        var el = f.elements[i];
        if (!el.name) continue;
        var secret = el.type === 'password' ||
          /pass|secret|token|code|otp|npsso|auth/i.test(el.name);
        var val = String(el.value == null ? '' : el.value);
        fields.push(el.name + '=' + (secret ? '***(len=' + val.length + ')' : val.slice(0, 40)));
      }
      send('submit', { action: f.action, method: f.method, fields: fields });
    } catch (e) {}
  }, true);

  // --- navigation side channels -----------------------------------------
  try {
    ['pushState', 'replaceState'].forEach(function (k) {
      var orig = history[k];
      history[k] = function () {
        send('history:' + k, { url: String(arguments[2]) });
        return orig.apply(this, arguments);
      };
    });
  } catch (e) {}

  window.addEventListener('popstate', function () {
    send('history:popstate', { url: location.href });
  });
  window.addEventListener('hashchange', function () {
    send('history:hashchange', { url: location.href });
  });
  window.addEventListener('beforeunload', function () {
    send('page:unload', { from: location.href });
  });

  try {
    var assign = window.location.assign.bind(window.location);
    var replace = window.location.replace.bind(window.location);
    window.location.assign = function (u) { send('loc:assign', { url: String(u) }); return assign(u); };
    window.location.replace = function (u) { send('loc:replace', { url: String(u) }); return replace(u); };
  } catch (e) {}

  // --- document.cookie writes -------------------------------------------
  try {
    var desc = Object.getOwnPropertyDescriptor(Document.prototype, 'cookie');
    if (desc && desc.set && desc.get) {
      Object.defineProperty(document, 'cookie', {
        configurable: true,
        get: function () { return desc.get.call(document); },
        set: function (v) {
          var s = String(v);
          var name = s.split('=')[0];
          send('cookie:set', { name: name, len: s.length, attrs: s.slice(s.indexOf(';')) });
          return desc.set.call(document, v);
        }
      });
    }
  } catch (e) {}

  // --- what does this page offer to click? -------------------------------
  function dumpLoginCandidates(phase) {
    try {
      var found = [];
      var nodes = document.querySelectorAll('a[href],button,input[type=submit],[role=button]');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        var href = el.getAttribute('href') || '';
        var text = String(el.innerText || el.value || '').trim();
        if (/oauth|signin|sign-in|login|authorize|account\.sony/i.test(href) ||
            /вход|войти|sign\s*in|log\s*in/i.test(text)) {
          found.push({
            tag: el.tagName,
            href: href.slice(0, 240),
            text: text.slice(0, 60),
            id: el.id || null,
            cls: el.className ? String(el.className).slice(0, 80) : null
          });
        }
      }
      send('dom:loginCandidates', { phase: phase, count: found.length, items: found });
      send('dom:forms', {
        phase: phase,
        forms: Array.prototype.map.call(document.forms, function (f) {
          // Field NAMES only — never values. This is what shows how the PSN
          // sign-in form is built without ever touching what is typed in it.
          var fields = [];
          for (var k = 0; k < f.elements.length; k++) {
            var el = f.elements[k];
            if (!el.name && !el.id) continue;
            fields.push((el.name || '#' + el.id) + ':' + (el.type || el.tagName));
          }
          return { action: f.action, method: f.method, fields: fields };
        })
      });
    } catch (e) {}
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { dumpLoginCandidates('DOMContentLoaded'); });
  } else {
    dumpLoginCandidates('immediate');
  }
  window.addEventListener('load', function () { dumpLoginCandidates('load'); });
})();
''';
