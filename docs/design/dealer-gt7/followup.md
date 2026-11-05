# Dealer follow-up fixes — 2026-11-05

User-requested bounded corrections after C-DEALER-GT7-UI was applied; implemented as direct fixes under AGENTS.md small-fix exception. Archived approved artifacts remain unchanged.

- Confirmed official legend-grid.jpg reference: one horizontal collection row. Restored horizontal desktop/tablet layout (700+ logical points), visible scrollbar and retained scrolling. Phones keep a vertical grid, including landscape, with AlwaysScrollableScrollPhysics.
- Used artwork uses contain, preserving whole-car aspect ratio instead of portrait cropping. Hagerty model-title and price/stock blocks reserve equal heights so different names/stock labels cannot shift the silhouettes or blue rules. Long prices scale down rather than truncate.
- On phones, removed the header refresh button and enabled pull-to-refresh for both inventories. Desktop retains the explicit refresh action. Existing error retry remains available.
- Music observer is registered before preference loading and reads initial lifecycle state. Audio commands serialize, stale starts/fades cancel, late native preparation pauses again, and disposal waits for pending commands. Resume restores volume after an interrupted fade.

## Evidence
83 selected tests passed (/tmp/dealer-followup-tests.log); changed-file analyzer has no issues (/tmp/dealer-followup-analyze.log). Tests cover real pull gestures and forced refresh, horizontal scrolling, 390/820/1280, RU/EN, 1.0/1.5 text scale, dialogs and music hidden/late-load/resume races.
Native Mac resized to 1280x820, 820x650, 390x844; native iPhone 17e checked. Local screenshot folder: /Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/dealer-gt7/native/ . Final phone evidence: legend-phone-pull-refresh.png, used-phone-pull-refresh.png. Runtime logs: /tmp/telemetry-dealer-fix-mac.log, /tmp/telemetry-dealer-pull-phone.log.

Mac had already exited when the user reported ongoing music; the remaining simulator Runner was identified and stopped. Native window close was exercised and process inspection confirmed no Mac binary remained. The simulator was shown live through serve-sim in the visible IAB at http://localhost:3200/ because the Simulator.app frontend is absent from this machine's Xcode installation. Any further simulator testing must be visible, and the app must be stopped after testing to avoid hidden duplicate audio. No persistent music preference changes were made.

Final cleanup: phone preview stopped after visible pull-to-refresh checks; scoped serve-sim helper terminated. Mac ordinary online lib/main.dart remains open. Final GRACE lint: 0 errors, 56 warnings. No commit/push. The user requested that simulator work always be shown visibly during future checks.
