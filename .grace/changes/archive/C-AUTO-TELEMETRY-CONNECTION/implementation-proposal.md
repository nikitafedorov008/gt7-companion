# Compact telemetry and automatic connection

Status: implemented, verified and applied with explicit user approval on 2026-11-03. See verification.md for evidence and limits.

## Visual target

Interactive preview: http://127.0.0.1:8768/proposal.html . File: `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/telemetry-compact/proposal.html`.

Normal desktop strip: roughly 114 logical pixels instead of the current large panel. Left: 96-pixel-wide SVG with small PS4/PS5 wordmarks underneath. Middle: small Telemetry label, prominent state or current vehicle name, one line with console/status. Right: white Open telemetry/Connect primary action, outlined Settings and More; demo/manual/disconnect move into More. In live mode the console art is replaced by the current manufacturer logo. Phone: roughly 164–185 pixels, actions move below; labels may grow naturally with accessibility text, without clipping or shrinking tap targets. No car photo or secondary metrics on Home.

States: searching, console found/waiting for GT7, live car, multiple consoles, manual mode. Values in the preview are illustrative. Search does not navigate away from Home. Only the user opens the existing instruments screen.

## Connection policy

1. Default persisted setting: automatic local discovery and connection enabled. Place under GT → Settings → Global → Telemetry. Also expose the same value in connection settings.
2. Start after settings load, while foregrounded. Try the last confirmed console address first using a bounded request; otherwise run a short DDP discovery round (about 3 seconds) on the PlayStation discovery ports. Do not run the legacy subnet-wide scanner automatically.
3. Parse protocol status, host identity/type/name and sender address; deduplicate. Active single candidate may connect. If there are several, prefer the previously confirmed target if present; otherwise ask the user to select. Standby candidates do not get woken.
4. Request packet C from the selected console. The UDP listener's existence is a listening/waiting state. Only valid decrypted GT7 packets from that sender establish live telemetry. Proposed telemetry-wait budget: 6 seconds per automatic attempt. No signal is shown as a helpful waiting/not-found state with manual action.
5. While foregrounded, bounded retries with a 30-second minimum delay; only one search/connect attempt at once. Stop discovery/retries immediately on background, disable, manual connect/demo, disposal or explicit disconnect. Explicit disconnect suppresses auto-reconnect until explicit restart of search or next app session. Disabling auto-search preserves an already active manual/live connection.
6. Remember the console address only after valid telemetry. Use packet receive time for freshness; after a short configurable stale threshold (proposed 5 seconds), hide the old current-car claim and show signal lost/waiting. Never present a stale car as live.
7. Resolve carId through the existing CarCatalog.byPacketId; use official name and manufacturerId to obtain the same official manufacturer logo used by Brand Central, preserving aspect ratio and caching. Missing logo falls back to manufacturer text; stale/unknown data never retains the previous brand. No new external car API. Show an unknown-ID fallback instead of inventing a model.

## What the source review found

- `lib/services/network_scanner.dart` already tries ARP, UDP, SSDP and ping across the subnet. Its UDP search omits the DDP protocol-version header; TCP port tests and vendor confidence are heuristics. It is not a suitable automatic connection trigger as-is.
- `lib/services/telemetry_service.dart` currently sets isConnected after opening the listener, before receiving valid game data. The new coordinator must distinguish waiting from live; sender filtering and lifecycle cancellation belong in services/repository, not the panel.
- `lib/repositories/car_catalog.dart` already supplies packet-ID-to-name lookups from bundled official car data; no scraper work is needed.
- `lib/services/app_settings_service.dart` already restores/persists global settings and is the right home for the auto-connect preference.

Protocol facts checked against primary implementation, not copied source code:
- https://github.com/ktnrg45/pyremoteplay/blob/master/pyremoteplay/ddp.py — SRCH discovery uses a protocol-version header; replies carry host type/status, with active versus standby distinct.
- https://github.com/ktnrg45/pyremoteplay/blob/master/pyremoteplay/const.py — PS4 discovery port 987, PS5 9302.
- https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.multicast — physical iOS requires this entitlement for IP multicast/broadcast. Existing project has NSLocalNetworkUsageDescription, but no multicast entitlement was found. Do not add an unsupported entitlement to signing blindly or claim Simulator evidence proves physical-device discovery. Direct-IP and saved-address paths remain supported while provisioning availability is checked.

## Execution after approval

1. Write the approved GRACE spec and sequential executable plan with bounded scopes and assertions, preserving existing uncommitted changes.
2. Add a cancellable Dart console-discovery source with protocol parsing and deterministic tests; keep the old heavyweight scanner manual only. No new package is expected.
3. Add a telemetry-connection repository to coordinate settings, discovery, one socket and actual-packet freshness; inject through AppScope. Add a narrow UDP test seam if needed. Keep packet parsing in current service/model.
4. Persist auto-connect and last confirmed target; add GT7-style Telemetry settings UI and shared connection control.
5. Apply compact panel and actual car/status presentation, retaining manual settings, SVG/platforms and demo. Use typed RU/EN resources.
6. Verify state-machine races, background cancellation, stale packets, retries, multiple consoles, setting restoration, user disconnect/manual override, unknown car, RU/EN 320–1440 and text scale 1.5. Run parser/connection/settings regressions, analysis, localization audit and GRACE final checks.
7. Run quiet native macOS and iPhone checks; verify the auto toggle and manual fallback, capture screenshots, report physical-console/signing limits accurately, and terminate both test apps at the end.

Expected new source scopes: `lib/services/console_discovery_service.dart`, a discovery model under `lib/models/telemetry/`, `lib/repositories/telemetry_connection_repository.dart`, telemetry services/panel/connection-dialog, settings display/service, AppScope, localization resources and dedicated tests. Durable graph/verification updates only in the approved lifecycle. No commit/push or saved audio preference changes.

## Latest visual refinement

Manufacturer mark appears beside the model in live state. Prototype uses official Toyota tnr43 PNG, downloaded through IAB and served locally for a reliable preview. The live badge is soft green; searching has a small spinner, waiting an outline, lost signal amber, manual neutral. State text accompanies every indicator. Primary action is Open telemetry (Instruments on narrow screens); secondary actions Settings and More have 44px minimum targets, keyboard focus and hover/pressed treatment. Reduced-motion disables animation. This remains a draft preview, not implemented Flutter behavior.
