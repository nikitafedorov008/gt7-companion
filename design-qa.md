# Telemetry connection design QA

final result: passed

## Target and captures

- Selected visual: second displayed Product Design concept, `/Users/nikitafedorov008/.codex/generated_images/01a16fa3-b3c5-7940-8ef0-df0224dab30a/exec-025d7864-6ba8-4261-ba85-251275173335.png` (1487 × 1058 pixels).
- Native macOS implementation: `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-connection/mac-home-final.png` (2000 × 1386 pixels, downsampled from the Retina Flutter capture). Actual logical viewport 1487 × 1030; the OS constrains window height.
- iPhone 17e: 390 logical points wide. `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-connection/phone-home-final.png` (924 × 2000 downsampled), `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-connection/phone-connection.png` (1170 × 2532 native simulator capture).
- Full comparison: `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-connection/design-comparison-full.jpg`. Captures normalized to 1487 pixels width with aspect ratio preserved; common top 1030 rows compared, excluding only the reference's extra bottom 28 rows.
- Focused comparison: `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-connection/design-comparison-panel.jpg`. Panels normalized to a common width, preserving their respective heights; no simulated rendering or image-generated app evidence.
- State: Russian, dark theme, Home, no console connection, no keyboard. Source service order, labels and race content differ from the existing product and were preserved outside the requested telemetry component.

## Comparison history

Initial comparison found P2 desktop hierarchy too small, title inherited legacy uppercase, overly transparent surface and insufficient leading visual space. Corrected the title via typed localization, made the panel graphite, increased desktop title and description, enlarged leading icon space, added a divider, and increased desktop padding. Recaptured and compared the final full view and panel together with the selected mock. Final wide panel is 226 logical points high; mobile uses a stacked layout.

No remaining P0/P1/P2 findings in the requested component. P3: uses the existing Material outlined devices pictogram instead of the mock's custom console illustration, and a flat theme-based white primary button rather than a raster glow. Generated illustration trials were not included in the product because their transparency was unsuitable. Existing header, animated home background and other Services were retained.

## Functional verification

- Actual Marionette taps on macOS and iPhone: main action opens connection dialog, settings opens, C selected, manual format selection and save/reopen, cancel, IP editing, demo, dashboard navigation, return Home and disconnect.
- macOS scanner opens the existing Find PlayStation dialog and closes back to connection settings.
- iPhone keyboard: scroll to submit, invalid IP stays in dialog; valid IP starts listener. `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-connection/phone-keyboard-validation.png` and `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-connection/phone-waiting.png`.
- Actual UDP log confirms `Sent heartbeat "C"` after submitting the iPhone connection form. Status displays waiting for telemetry rather than implying that valid game packets arrived. No live PlayStation stream was available to verify.
- Final Dart MCP runtime inspection: no errors reported for either app after the checked final flows. Earlier automation taps during transitions generated missing-element tool errors; the fresh final checks are clean. One earlier iPhone session logged an unlocated RenderFlex warning while exercising existing demo/navigation; it did not recur in the final connection flows, and the tested connection layout is clean.
- 142 Dart MCP tests pass across connection, existing telemetry/parser, settings/navigation and sound feedback suites. Includes RU/EN 320, 390, 600, 1100, 1280, 1440 widths, text scale 1.5 and keyboard insets. Connection-focused suite has 22 tests.
- Changed UI/test analysis has no issues. UDP analysis retains four pre-existing avoid_print informational diagnostics. Localization audit passes with 566 messages and equal RU/EN schemas.

## Scope and limits

This is a native Flutter implementation in the existing app, not a hosted web prototype. No publication, commit, push, new API, or production debug hooks. Live automation uses an ignored `.dart_tool` entrypoint; production main is unchanged. Real console telemetry correctness is outside this visual change and requires an available PlayStation.


## SVG/platform revision — 2026-11-03

final result: passed

User superseded the generic pictogram with SVG and requested PS4/PS5 logos. Then selected gamepad/TV from `exec-674c6ff6-a69e-41dc-ac4c-8d69b8e967f6.png` and the console from `exec-19b9358d-7092-4611-b5f0-ece7ce898c41.png`. These are contour references; noisy raster transparency is excluded. Current vector source: `assets/images/telemetry_connection.svg`; original GT logo vector paths are reused inside the monitor. Source notes: `assets/images/telemetry_graphics_sources.md`.

Final native screenshots (same session visualization directory as above): `telemetry-connection/mac-svg-platforms.png` (2000×1281, logical 1280×820) and `telemetry-connection/phone-svg-platforms.png` (924×2000, logical width 390). `connection-art-preview.png` is an unretouched region crop from the final macOS capture. The SVG reference supersedes the earlier P3 generic-icon note. Both platforms have readable, accessible, noninteractive wordmarks below the connection content; no clipping found. The row wraps at smaller tested widths. No remaining P0/P1/P2 findings in this revision.

Verification: 22 connection tests pass including RU/EN phone/desktop and text scale 1.5; SVG XML is valid and vector-only; changed widget analysis clean; resource audit passes with 567 messages. Both final app runtime inspections show no errors. Verification was muted through an ignored in-memory-preferences entrypoint, without changing user's saved audio settings. Test apps terminated after checks to avoid background music.


## Compact telemetry and auto connection — 2026-11-03

149 selected tests pass; changed-file analysis and 590-message localization audit clean. Mac 114px and iPhone390 166px fixture panel verified, no runtime errors; unknown/stale car and logo fallbacks tested. Global/connection auto toggle and manual/menu interactions checked. Test apps stopped, saved audio preferences untouched. Detailed evidence and signing/physical-console limits: `.grace/changes/archive/C-AUTO-TELEMETRY-CONNECTION/verification.md`.


## Recovery review fixes — 2026-11-03

Small direct fix explicitly requested after review of 6fbcdb8. Saved-IP failure now remains retryable when broadcast is unavailable; missing first-run address still waits for manual setup. UDP error transitions to lost/recovery; explicit user disconnect suppresses retries.

Seven permanent regression cases in test/telemetry_auto_connection_test.dart cover saved-IP reconnect without DDP, no-address/no-broadcast idle, actual TelemetryService UDP-error handling and return to LIVE, direct dashboard disconnect, and pending recovery cancellation by disconnect/disable/background/dispose. New failure scenarios reproduced before the source fix; selected full regression batch now passes 156 tests. Changed-file analysis reports no errors; GRACE lint reports zero errors (52 existing heuristic warnings).

iPhone17e Simulator full app launched with muted in-memory preferences and saved loopback address. Initial valid-packet timeout and multiple retries occurred before any fixture stream; without UI actions, a later encrypted C stream was accepted by the normal UDP/Salsa20 path and switched Home to LIVE with Toyota GR Supra RZ '20 and the manufacturer logo. Runtime errors after hot reload: none. Evidence: /Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-recovery/iphone-auto-recovered.png . Physical console recovery was not tested in this run. Test app and fixture terminated; saved user preferences untouched.


## Beyond the Apex menu placement — 2026-11-04

User requested parity with the official GT7 GT Menu. Small navigation fix: removed Apex from Services, removed unused onApex callback, changed service grid to four/two/one columns, and added GT Menu magazine entry. Apex now uses global /apex so the originating screen is retained. Reader styling unchanged. Official references, measured web palette and screenshot evidence are documented in docs/design/beyond_apex_ui.md.

95 selected service/menu/reader/settings tests pass, including GT-menu-to-reader-and-back on macOS/iOS variants and RU/EN responsive cards at 320–1920 with text scales 1/1.5. Changed-file analyzer: no errors. Live macOS: menu entry present, reader opens and back restores Home, no runtime errors after hot reload. Muted test preferences are in-memory; test app terminated after inspection.


## Official Beyond the Apex styling — 2026-11-04

C-APEX-MAGAZINE-STYLE implements the confirmed official light magazine appearance: local palette, black GT header/native safe areas, official cover without duplicate title, pale chapter cards and untinted square illustrations. Contents rail at desktop widths; drawer on phones/enlarged text. Theme isolation, real cover rendering and existing navigation/loading/localization cases pass: 131 selected tests, changed-file analysis clean. Quiet native Mac/iPhone390 cover, contents and article interactions checked; runtime errors none. All QA apps terminated; saved audio preferences untouched. See docs/design/beyond_apex_ui.md and change verification.md for evidence.

## Apex navigation refinement — 2026-11-04

Preserved the app AdaptiveNavBar outside the light reader theme (desktop top / mobile bottom). Moved close, contents and original-site actions into the magazine page header, following dealer headers. Apex and navbar tests: 50 passed, widths 320–1920 with normal/enlarged text; close/return tested on macOS and iOS. Native Mac screenshot: apex-style/mac-global-navbar.png.

## Apex native return confirmed — 2026-11-04

Diagnosed the apparent freeze as a hidden Mac window with Flutter frames disabled. Rebinding/activating the native window restored rendering. CUA clicks verified repeated Apex close to the home hub and return to the prior Used Car Display; system-back delivery also popped Apex and retained the dealer route. Final app left open on the cover, resumed with frames enabled. No product code changes required for this diagnosis.

## Apex nested shell navigation — 2026-11-04

Moved Apex into HomeShell next to the dealers. Its light reader no longer builds a duplicate global navbar. The existing AdaptiveNavBar stays mounted during transitions. Native Mac check: main hub → GT menu → Apex → close → hub; Wishlist → GT menu → Apex → close → Wishlist; re-opened Apex for user inspection. Hot reload succeeded, analyzer clean, 50 Apex/navbar tests passed, including navbar Element identity and root/home stack assertions for macOS/iOS.

## Shared GT loading indicator — 2026-11-04

Direct user-requested visual refinement: GtLoadingIndicator uses the existing GT SVG in white, a thin white rounded ring (1.5px / 1px compact), and a dark circular plate in light themes. Used Car Dealer explicitly requests the plate because its white legacy canvas inherits the dark app theme. Replaced all indeterminate CircularProgressIndicator call sites in app bootstrap, login/profile, Apex, both dealers, Brand Central, GT Auto, scanner and telemetry loading states. The determinate profile statistics ring is retained as data UI. Supports reduced motion and a localized loading semantics label.

135 selected tests passed before the final light-canvas refinement; the final 3 loader tests passed afterward (including added legacy-canvas contrast regression). Analyzer clean. Hot reload succeeded. Native Mac: opened Used Car Dealer, observed GT mark/thin ring, waited for real catalogue load, then triggered an actual forceRefresh through the running repository via VM inspection and observed the corrected dark plate/white mark on its light canvas. App left running.

## 2026-11-04 — Local dealership card artwork

Used, Legendary, Brand Central: native macOS and iPhone 17e (390 logical px), cold start with outgoing Dart HTTP denied. Local PNG/AVIF photos, manufacturer logos and flags render; all three sections show card content, no image HTTP attempts, no runtime errors. Used header wraps on narrow Russian UI, SafeArea protects top controls and bottom list padding clears floating navigation. Offline inventory carries its source date. Evidence: `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/local-card-artwork/`. Galleries excluded. Details/update commands: `docs/research/local-card-artwork.md`.

## 2026-11-05 — Local track artwork

Native macOS (1280 logical px) and iPhone 17e (390 logical px), cold launch with metadata HTTP enabled and track image HTTP denied: race card photos and layouts render locally; details also show the correct track logo. Both custom reports contain blockedTrackImageRequests=[]. No image/layout exception or overflow; one Marionette scrollTo target lookup failed independently of UI behavior. Normal online entrypoints restored after testing. Evidence: `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/track-artwork/`. 45 selected regression tests passed; 377 canonical URLs / 211 unique assets / 30,668,808 bytes, no profile photographs.


## 2026-11-05 — C-DEALER-GT7-UI
Used light inventory/dialog and dark Hagerty collection/showroom implemented with official localized metadata and persistent local wishlist. 71 selected tests pass, changed-code analysis clean, final GRACE 0 errors/57 warnings. Native Mac and iPhone Used evidence recorded; final iPhone Hagerty sweep, last visual fixes and standard-launch cleanup remain pending because automatic approval review timed out. See .grace/changes/active/C-DEALER-GT7-UI/verification.md. Do not mark fully verified/applied yet.

### Completed native follow-up — 2026-11-05
Hagerty inventory/showroom/back verified on iPhone; test Ferrari removed from simulator Wishlist. Final Mac logo and price-button fixes inspected and captured. Both targets restored to ordinary online lib/main.dart; one current Mac window raised and left on Hagerty. No runtime exceptions/overflows in final launch logs. C-DEALER-GT7-UI is ready for explicit apply/archive confirmation.

### Dealer follow-up — 2026-11-05
Restored desktop Hagerty horizontal row against official screenshot; fixed whole-car image containment, consistent silhouette rows and long-price fitting. Phone refresh button replaced with pull-to-refresh in both dealers. Music lifecycle startup/fade races covered by permanent tests; actual background sound source was the leftover simulator, now identified for explicit cleanup. 83 tests pass; changed-file analyzer clean. Live simulator shown in IAB during checks. Details: docs/design/dealer-gt7/followup.md.

## C-DEALER-CARD-FIDELITY — 2026-11-05
Applied the approved visual audit: 2.86 Used desktop ratio, compact image-left composition, distributed PP/drive row, small credit prefix, mileage/warning icons; open Hagerty corner marks and reference-proportioned anchors. 71 targeted tests pass, changed-code analyzer clean. Real Mac and visible iPhone compared to saved official references. Original font/assets, ownership and mileage limitations are explicit in docs/design/dealer-gt7/fidelity-verification.md. No claim of literal asset/pixel identity.

### In-app price history — 2026-11-05
GT7Info PNG now opens inside the shared Used/Legendary vehicle flow, with zoom/pan/reset, GT loading indicator, refresh and error/retry. Root modal prevents chart pans from switching the app's PageView tabs; permanent regression covers this real-device finding. 76 tests pass; analyzer clean; GRACE 0 errors. Checked Mac and visible iPhone; simulator stopped and Mac left on the chart. Details: docs/design/dealer-gt7/price-history.md.
