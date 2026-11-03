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
