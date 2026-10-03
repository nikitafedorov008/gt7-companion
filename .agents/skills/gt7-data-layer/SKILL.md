---
name: gt7-data-layer
description: How models, repositories and services are written in GT7 Companion - manual JSON factories, presentation getters, enum parsers, repository contracts, error and caching conventions. Use when adding a data source, a model, a repository method or a service call.
---

# GT7 Companion — data layer

Evidence: [`docs/CODE_STYLE.md`](../../../docs/CODE_STYLE.md) sections J–K.
Scope: author-written layers (not telemetry, not profile).

## Models (`lib/models/<source>/`)

- Plain Dart, **no codegen** (no `freezed`, no `json_serializable`, no `part`) — mapping is hand-written.
- `final` fields plus one named constructor with all parameters; `const` constructor in the newer layer.
- Mapping is a factory: `factory X.fromJson(Map<String, dynamic> json)`. Source-specific variants are named
  after the source (`GTDBCar.fromUsedCarJson`, `Gt7Stats.fromApi`, `DailyRace.fromPair`, `fromElement` for DOM).
- Unwrap the API envelope inside the model, with a fallback for the flat shape:
  `final r = json['result'] as Map<String, dynamic>? ?? json;`
- Null policy in new code: `(json['race'] as num?)?.toInt() ?? 0`, helper `static int _int(Object? v, {int fallback = 0})`,
  `fallback: -1` for "unknown". Do not use bare `json['x'] ?? ''` without a cast in new models.
- Parsing of dates/numbers happens in the model, not in the UI (`DateTime.parse(...)` under a null guard,
  `formatLapTime`).
- Presentation getters are allowed and expected: `displayPrice`, `isSoldOut`, `statusText`, `carImageUrl`
  with priority order explained in comments. Business rules that need several sources are not.
- No `==`/`hashCode` anywhere; `copyWith` is an exception; `toString()` is common in the form
  `'ClassName(field: $value)'`; `@immutable` is declared explicitly.
- Enums carry no fields; logic lives in `extension X on Enum` with `static X? parse(String?)` that returns
  `null` for unknown input instead of guessing. Code→value tables are `static const Map<...>` with a note
  saying what confirmed them.

## Repositories (`lib/repositories/`)

```dart
abstract class SportRepository extends ChangeNotifier {
  List<DailyRace> get dailyRaces;
  bool get isLoading;
  String? get error;
  Future<void> fetchDailyRaces({bool forceRefresh = false});
}
class SportRepositoryImpl extends SportRepository { ... }
```

- Repository = composition of services + domain merge/dedup/sort. **No HTTP and no JSON decoding here.**
- Errors are state, not exceptions: set `_error` / `_errorMessage`, and always
  `finally { _isLoading = false; notifyListeners(); }`.
- A partial failure must not lose the good half: independent `try` blocks per source, collect per-source
  errors, set the aggregate `_error` only when everything is empty.
- Log with `debugPrint('ClassName: what happened $data')`.
- Member order: dependencies → private state → getters → constructor → public methods → private helpers →
  filter getters last.
- Caching is manual boolean flags (`_isLoaded`) plus a guard `if (!forceRefresh && _data != null) return;`.
  There is no TTL anywhere — do not add one silently.

## Services (`lib/services/`)

- One external source per service. Skeleton: `_isLoading` + `_error` + getters + `Future<T> fetchX({bool forceRefresh})`.
- Call shape: `_setLoading(true)` → `if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}')`
  → `catch (e) { _error = '...: $e'; rethrow; }` → `finally { _setLoading(false); }`.
  `rethrow` is for HTML scrapers whose caller (repository) catches it.
- Inject the client with a default: `DgEdgeService({http.Client? httpClient}) : _http = httpClient ?? http.Client();`
  — never call static `http.get/post` (three legacy services do; do not copy that).
- Timeouts and politeness live in class constants: `static const Duration _timeout = Duration(seconds: 12);`
  `static const Duration _crawlDelay = Duration(milliseconds: 350); // be polite`.
- Platform differences use `switch (defaultTargetPlatform)` with graceful degradation and a log line, not
  bare `Platform.isX` checks.
- Never log secrets: use the masking helpers on `Gt7AuthTrace`.

## Before you finish

- `flutter analyze` is clean.
- No new `print`; use `debugPrint` with the class-name prefix.
- Nothing in the UI caught a raw exception — errors surface through `_error` on a `ChangeNotifier`.
