# Implementation evidence — 2026-10-26

The approved proposal is implemented, including the user's subsequent directions to reuse the native-window safe-area utility and match the two supplied GT7 interface references more closely.

## Result

- Gray GT opens a left translucent menu with working Settings and Home rows.
- Settings uses a connected segmented strip, tall category tiles and a nested language page, with working Sound/About sections and close/back controls.
- One persisted System/Russian/English choice controls Flutter UI, Material controls, legacy label adapters, dates/readouts and the official Apex and Brand Central editions. Local feature language selectors are removed.
- `AppRouter` and its route-information/delegate config live in root State. Locale changes retain the current route and entered text. Old Apex-only preferences cannot override the application choice.
- `WindowNavigationSafeArea` now protects standalone headers and AppBars, including settings and the fullscreen gallery. The tab shell marks content already below its navbar; native controls are not reserved twice. System/native horizontal padding overlaps using max, fullscreen updates release native reservation, non-macOS platforms do not acquire a macOS inset.
- Longer translated timing, map, legend and telemetry headers wrap; painter captions receive a locale snapshot and repaint when it changes.

## Validation

- Full Flutter suite through Dart MCP: **482 passed, 1 skipped**. After the final menu gesture-key adjustment, the settings/native safe-area targeted suite also passed **25 tests**.
- Python: `python3 -m unittest discover -s test -p 'brand_central_parser_test.py'`: **3 passed**.
- Localization audit: **552 messages**, identical RU/EN keys and placeholder schemas, **141 static UI uses** checked. Dynamic templates and rendered screens have separate Flutter coverage.
- Analyzer snapshot: **0 errors, 23 warnings, 145 infos**; existing repository warnings remain. New settings/localization/native safe-area code was separately analyzed during implementation.
- GRACE selected final assertions: **0 errors**, heuristic Dart projection warnings remain.
- `git diff --check`: no whitespace errors (Git reports the existing CSV CRLF normalization notice).

## Live evidence

The complete ordinary App was run on macOS and the iPhone 17 Pro simulator through a temporary ignored `.dart_tool/live_settings.dart` entrypoint with Marionette, using production App/DI/routes and no fixture data. This avoids auto-running the demo telemetry while checking settings.

- macOS: GT → Settings → language category → RU/EN immediately updates the settings without closing it; close returns to the prior section. Brand Central showed Russian regions and official 580-car/77-marque counts.
- Apex: actual network-loaded Russian chapters changed to English chapters after the global language choice, returning to the same reader route.
- macOS hot restart restored English from preferences; iPhone full relaunch also restored English. System was restored after checks.
- Native widths 1280 and 600 inspected; both languages and 320–1920/1.5 text covered by widget tests. iPhone portrait checked with the new menu and category layout.
- Native settings headers begin after the reserved traffic-light area; content below the main navbar has no extra reservation.
- iPhone live scenario ended with no reported runtime errors.

Screenshots: `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/global-settings/`.

## Limits

Previously observed macOS debug renderer termination recurred during auto-demo checks; renderer repair remains outside the approved change. The settings/source/portrait checks were completed in the ordinary App without auto-demo. Static localization scanning cannot prove arbitrary external text coverage; source-provided names, identifiers, diagnostic details and unavailable translations retain their spelling as specified.

No commit or push was performed for this change.
