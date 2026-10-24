# Verification — 2026-10-25

- User-selected Workshop concept implemented in the Flutter GT Auto route.
- Official catalogue generator refreshed 580 cars and 580 photo links; entrypoint discovered from the current official page.
- Native macOS loaded 292 confirmed GTPlus swap records and HRC Rolls special-parts compatibility directly from the public sources. S15 has two engine choices; donor, price and comparison changed when selecting the NISMO engine.
- Actual taps selected a swap and Carbon Propeller Shaft, and typed notes. After a full app restart all three restored. Switching to Abarth 500 showed an independent empty plan; returning to Silvia restored its plan. Test-created plan selections and notes were then removed.
- Native windows inspected: 600x900, 820x900, 1024x900, 1280x900/1000, 1920x1080. A shared-header overflow at 600 was found, fixed in C-WORKSHOP-NARROW-NAV and rechecked at 600 and 820. The final Dart runtime-error query returned no errors.
- 25 new data/repository/workshop checks plus 14 desktop-header checks. Widths 320/390/600/820/1024/1280/1920 and text scales 1/1.5.
- Full MCP run_tests: 354 passed, one existing opt-in network check skipped. Targeted Dart analysis of all changed Dart modules and tests: No issues found.
- Selected GRACE final assertions for both changes: zero errors. Existing heuristic warnings remain; no new lifecycle errors.
- Native screenshots: /Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/gt-auto/runtime/ (gt-auto-workshop-wide.png, gt-auto-swaps.png, gt-auto-600.png, gt-auto-820.png, gt-auto-plan-restored.png).

Limits: Native verification was macOS only. Special parts describe the stock car; swapped-engine effects, regular-parts pricing and wide-body compatibility are not inferred. GTPlus/sheet formats are third-party contracts with visible retry states, not official stable APIs. The previously deferred native renderer crash remains outside this change; a lost old debug instance was relaunched during verification.
