# Brand Central — implementation and verification

Implemented the user-approved independent fifth Services entry with the complete official GT7 catalogue snapshot: 580 cars, 77 brands, RU/EN histories and specifications, 3–6 official gallery frames per car. Images load on selection and successful module resolutions are cached. Public JavaScript is parsed as data, never executed.

The user's subsequent explicit visual refinements extend the original UI work: a GT7-style escalator atrium, separate flat map, region-first navigation and country-grouped manufacturers, plus a separately generated portrait plate. Necessary asset registration is in pubspec.yaml and assets/images/brand_central/. The original approved plan is retained unchanged. test/apex_display_test.dart has the required new ServiceMenu callback in its existing navigation fixture.

## Evidence

- Full Flutter suite through Dart MCP: **376 passed, 1 skipped**.
- Final affected UI/data/routes/DI/tests analyzer: **No issues found**.
- Python source-literal parser/security and bundled-coverage checks: **3 passed**.
- Widget checks: widths 320, 390, 600, 820, 1024, 1280, 1920, text scales 1.0/1.5; region → country/brand → car → back; actual language controls, gallery error/retry, stale responses, correct portrait/landscape asset selection and animation lifecycle/reduced motion.
- Live macOS: official history/specifications and 4 gallery frames loaded for Nissan Silvia and Aston Martin DB11; next frame and full-screen photo verified, back retains search. Windows 600/820/1280/1920 were inspected during the change.
- Live iPhone 17 Pro Simulator (iOS 26.5): real Services card opens the portrait lobby, separate portrait architectural plate is visible, all three region controls and bottom navigation fit, Asia-Pacific opens manufacturers grouped by country, Nissan search returns one brand.
- Screenshot directory: /Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/brand-central/ .
- Official visual references and asset provenance are documented in docs/research/BRAND_CENTRAL_RESEARCH.md and assets/images/brand_central/README.md.

## Limits

The atrium is a generated image with camera drift, not original game video or physically animated escalator steps. Full brand-event museum timelines are not fabricated. Unknown manufacturers/countries remain accessible via All marques / All GT7 cars. Catalogue updates use tools/fetch_gt7_cars.py --brand-central-only.

The previously deferred macOS debug-renderer instability remains outside this change. A demo HUD overflow at lib/widgets/telemetry/gt7_hud.dart:184 was observed on iPhone after hot reload; it is outside Brand Central and was not changed. Some automation attempts raced asynchronous navigation; only rendered destination screenshots are treated as visual evidence.

The approved bundle remains active for review; no commit or push was requested in this change.
