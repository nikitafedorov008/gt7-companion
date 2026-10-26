# Global settings and localization

Implemented for C-GLOBAL-SETTINGS-L10N, 2026-10-26. Subsequent user directions also cover native safe areas and closer styling to the two official GT7 screenshots.

## User-facing flow

Gray GT button → left translucent GT menu → Settings. Global/Sound/About share one segmented strip. Global presents working category tiles; Application language opens System/Russian/English. Closing settings returns to the previous route. Audio uses existing sound/music services and their stored preferences; About retains provenance, music credits and package licences.

Visual references inspected through Codex IAB:
- https://www.gran-turismo.com/images/c/i1KtJvmeaUdnz.jpg — connected tabs, flat tall category tiles, centered icons and descriptions.
- https://www.gran-turismo.com/images/c/i1JW0W38E4UVr.jpg — left translucent panel, left-aligned icon rows, separated return action.

Only functional companion settings appear; PS5 graphics, race difficulty and controller settings are not simulated.

## Ownership and coverage

| Area | Implementation |
| --- | --- |
| Preference | `AppSettingsService`, ordered local writes, invalid-value fallback, OS locale observer, unsupported-language fallback to English |
| Root | state-owned `AppRouter`, Flutter localization delegates, effective locale, restored preferences before interactive startup |
| Resources | `lib/l10n/app_en.arb`, `app_ru.arb`, generated typed getters/templates/plurals |
| Existing UI | `BuildContext.tr` adapter uses generated resources for existing data-driven labels; new settings also use typed getters |
| Main UI | Home, Services, Wishlist, Profile, login, navigation, dialogs and tooltips |
| Car sections | both dealers, GT Auto specifications/swaps/parts/build plan, Brand Central regions/catalogue/showroom/gallery |
| Races | cards, detail sheet, histogram captions, states/errors |
| Telemetry | connection/scanner, HUD/MFD, timing, motion/attitude/surfaces, graphs, map, elevation and painter labels |
| Formatting | localized header dates, locale-aware prices and numeric readouts; protocol IDs, lap-clock syntax and versions stay stable |
| Content | global locale binds Apex RU/US HTTP source and Brand Central RU/EN official metadata; local feature language buttons removed |
| Native chrome | `WindowNavigationSafeArea`, `WindowNavigationAppBar`, and shell scope; native and system horizontal insets overlap rather than add, nested bars consume once, fullscreen reservation releases |

Manufacturer/model names, API keys/serialized IDs, technical abbreviations, diagnostic traces, source credits and external text without a source translation retain their spelling. Official vehicle histories come from the corresponding official edition, not machine-generated translations.

## Maintenance

Use the FVM SDK. Add or update both ARB files, then:

1. `.fvm/flutter_sdk/bin/flutter gen-l10n`
2. `python3 tools/audit_localization.py --write-adapter` if adding an existing data-driven label to the adapter.
3. `.fvm/flutter_sdk/bin/dart format lib/l10n`
4. `python3 tools/audit_localization.py`

The audit checks matching keys/placeholder schemas, nonempty translations, adapter getter coverage and static `context.tr` literal uses, with a narrow logo/unit allowlist. Dynamic templates, source propagation, route retention and rendered layouts are verified by the Flutter tests; static scanning alone does not prove those behaviors.

## Regression coverage

- `test/app_settings_test.dart`: system fallback/OS changes, persistence/restoration/order, resource parity, real GT menu/settings navigation and retained route/input, category UI RU/EN 320–1920 with 1.5 text.
- `test/window_navigation_safe_area_test.dart`: macOS native/system overlap, nested consumption, fullscreen inset updates, standalone AppBar back button, iOS/Android/Windows/Linux isolation.
- `test/adaptive_navbar_test.dart`, `service_menu_test.dart`: both locales at existing width/scale matrix.
- `test/brand_central_test.dart`, `gt_auto_workshop_test.dart`: both locales across all existing responsive widths/sections.
- `test/telemetry_display_layout_test.dart`: data/HUD RU/EN 320–1920 at 1.5, including timing/header/legend wrapping and localized painter layout.
- `test/apex_display_test.dart`: shared-language HTTP source changes and removed local selector, reader/navigation/retry regressions.

Known unrelated macOS debug renderer instability was reproduced during live checks. A temporary ignored entrypoint in `.dart_tool` runs the complete ordinary App with Marionette and without auto-demo; it does not replace production `lib/main.dart`.
