# Verification — 2026-11-03

Implemented the approved compact GT7 telemetry strip and sequential connection plan.

## Evidence

- Dart MCP selected regression batch: **149 tests passed** (connection UI/state, discovery, global settings, telemetry layouts, parser/track, motion and input graphs).
- Changed Dart files: analyzer reported **No errors**.
- Localization audit: **590 messages**, matching RU/EN keys and placeholder schemas.
- DDP loopback tests verify the request header, strict device/status parsing, deduplication, timeout and cancellation. Mac additionally found a real active console via DDP; no physical-console GT7 packets were available during QA.
- Fixture uses real encrypted 368-byte C UDP packets over 127.0.0.1, through UdpService and Salsa20 decoder; carId3418 resolves to Toyota GR Supra RZ '20 and official Toyota tnr43 logo. Fixture screenshots must not be described as a live race on a physical console.
- macOS actual panel: **1248×114 logical pixels** in a 1280-wide window. Settings, More, manual address entry, valid-packet LIVE state and global Telemetry category checked through Marionette. Shared auto toggle kept its value across both settings surfaces.
- iPhone17e Simulator actual width390: fixture panel **358×166 logical pixels**, manual state180; entry/settings form scrolls and accepts IP, More/disconnect work. Current car/brand and actions visible, no overflow.
- Widget tests cover RU/EN 320,390,800,1280,1440 with 1.5 text scale; unknown IDs, logo load failure, expiry and prior car/brand removal.
- Runtime errors after hot reload: **none on Mac and iPhone**.
- Native QA used in-memory muted preferences; saved user audio preferences were not changed. Both test apps terminated, local UDP fixtures ended.

Screenshots:
`/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-auto/mac-live-fixture.png`
`/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-auto/phone-live-fixture.png`
`/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-auto/mac-global-settings.png`

## Limits

Physical iOS broadcast discovery needs the Apple multicast entitlement, absent from current signing. This build honestly disables broadcast discovery on iOS and retains manual-first/confirmed-address automatic reconnection. No console wake, PSN login, Remote Play session or automatic subnet sweep. Physical-console live telemetry not verified; network discovery and fixture decoding verified separately.

Existing GRACE heuristic markup warnings remain; no broad legacy cleanup included. No commit or push.
