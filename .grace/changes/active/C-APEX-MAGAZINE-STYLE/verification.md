# Verification — 2026-11-04

131 selected tests passed: Apex reader/service/language, service menu, adaptive navbar, app settings and native safe-area helpers. Changed-file analyzer: No errors. Parent dark theme vs local light reader and official-cover-first layout explicitly asserted. RU article navigation tested at320,390,600,768,1024,1280,1920 with scales1/1.5; global language RU/EN and retry regressions retained.

Native macOS 1280-wide and iPhone17e390-wide: real official cover loaded, contents opened, chapter expanded, real article selected and cover restored. Hot reload succeeded; runtime errors none. Native macOS header reserves traffic-light space and paints black across the entire strip; phone body respects safe areas and drawer closes after selection.

Screenshots in /Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/apex-style/: mac-cover.png, mac-article.png, phone-cover.png, phone-contents.png. Source measurements and links in docs/design/beyond_apex_ui.md.

No pixel-identical assertion across native device chrome; back/contents controls and layout adapt the official online magazine presentation to the app. No global theme or language preference changes. QA audio was muted in memory and test apps terminated. Existing GRACE heuristic warnings retained; no commit or push.

### Follow-up: shared application navigation

User requested retaining the existing dark application navbar and moving return/close into the page, following used/legendary dealer headers. Implemented as a direct UI refinement: AdaptiveNavBar stays outside the local light theme, with a page-level close action; desktop top/mobile bottom placement. 50 Apex/navbar tests passed, including real close-button route restoration on macOS/iOS and 320–1920 responsive widths; changed-file analyzer clean. Native screenshot: `apex-style/mac-global-navbar.png`.

Native follow-up limitation: the updated Mac reader was captured successfully. Close/return is covered by widget routing tests; a subsequent native automation attempt stalled with zero interactive elements after navigation, and its debug processes were stopped. Do not count that attempt as a successful native close/return check.

### Native navigation diagnosis resolved — 2026-11-04

Root cause of the previous automation stall: VM inspection reported `[AppLifecycleState.hidden, false, false]` (lifecycle, framesEnabled, hasScheduledFrame). Marionette delivered taps to the hidden window, but Flutter did not render route/dialog animations. A fresh native CUA app binding and foreground activation restored `[AppLifecycleState.resumed, true]`; no app source changes were needed. Do not force `handleAppLifecycleStateChanged(resumed)` or keep hidden windows rendering in production.

Verified in the running native Mac app with CUA clicks and AX observations: GT menu → Apex → page close → main hub; repeated entry from Used Car Display → Apex → close → the same Used Car Display. The system-back handler was also invoked through VM evaluation while Apex was open; the resulting widget tree contained UsedCarDisplay and no ApexDisplay. A further system back restored the hub. The dealer remained in its network-loading state, so this verifies route preservation, not loaded dealer data. Apex's live official preface loaded; Contents returned to the cover.

Final state: the native app remains OPEN on the Apex cover at user request, in resumed lifecycle with frames enabled. This supersedes the previous native automation limitation. Audio is disabled only in the in-memory quiet QA entrypoint.

### Follow-up: Apex belongs to the existing home stack

User corrected the navigation model: the shared bar must remain mounted, as with dealer screens. Moved Apex from root routes into HomeShell children, removed the standalone Scaffold/navbar wrapper, and explicitly registered HomeShell as the home tab. The GT menu pushes into that existing home stack, avoids duplicate Apex pushes and restores the prior tab after close. This direct navigation correction also touches app_router.dart, adaptive_navbar.dart and nested_widget.dart.

50 Apex/navbar tests passed, analyzer clean. Routing tests verify the exact navbar Element stays mounted, root stack size remains 1, Apex is the home stack's current route, close restores the previous tab, and the dealer route beneath Apex survives. Responsive 320–1920 and enlarged text tests remain green.

Native Mac follow-up passed: hub → Apex → close → hub, and Wishlist → Apex → close → Wishlist. Re-entered Apex through the same shared navbar after hot reload and left it open for the user. This supersedes earlier notes about global/root Apex presentation.
