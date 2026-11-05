# Dealer GT7 UI verification — 2026-11-05

## Implemented
Light Used inventory and dialog; dark Hagerty collection and showroom; exact canonical-ID official catalogue join for PP/specifications/history; unknown mileage remains unknown; shared persistent local wishlist and functional existing tab; separate corrected numeric-ID price-history link. RU/EN and local artwork retained. No purchases or PSN writes.

## Passing evidence
- 71 selected tests passed: `/tmp/dealer-final-tests.log`. Data joins, storage failure/retry/serialization, RU/EN cards, dialogs, real controls and inventories at 390/820/1280, text 1.0/1.5, iPhone-height dialogs, retained partial-source rows, rotated-out wishlist and scroll restoration.
- Changed files analyzer: no issues (`/tmp/dealer-target-analyze.log`). Full lib/test analyzer reports 177 existing issues in other code (`/tmp/dealer-all-analyze.log`); do not claim a clean whole-repository analyzer.
- Final GRACE: 0 errors, 57 warnings (`/tmp/dealer-grace-final.log`). Dart adapter invoked with analytics suppressed because default telemetry writes outside allowed workspace fail. Temporary PATH wrapper only adds Dart --suppress-analytics; no analysis bypass.
- Native online macOS via ignored `.dart_tool/dealer_online.dart`: Used/Legendary inventory and dialogs, genuine card tap, save, history expansion, Escape/close. Saved FIAT car1523 persisted after full hot restart and appeared in real Wishlist tab; test addition removed afterwards.
- Native online iPhone 17e, 390 logical points: Used inventory, Ferrari dialog, save/history/close and return to inventory/home operated through real controls. Bottom actions remain above floating navigation. Test Ferrari car3654 was added (initial button was Add) and removed during the completed continuation below.

## Native evidence
Absolute folder: `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/dealer-gt7/native/`.
Files: used-mac.png, used-dialog-mac.png, legend-mac.png, legend-dialog-mac.png, wishlist-restored-mac.png, used-phone.png, used-dialog-phone.png.
Mac inventory/dialog screenshots precede final brand-logo inversion removal and light price-link foreground fix; iPhone Used screenshots include those fixes and real aspirationShort field. Final source is covered by 71 tests.

## Completed continuation — 2026-11-05
The user explicitly authorized retrying the native checks and normal app restoration after the previous approval timeouts.
- Native iPhone Hagerty two-column inventory inspected: correct manufacturer colours, years, prices and no overflow. Honda car683 showroom opened via actual card and closed via actual button; dealer close returned home.
- Wishlist tab opened through actual floating navigation. Only test Ferrari car3654 was present; removed through wishlist-remove-car3654, and localized empty state verified.
- Final Mac fixes verified in native app: manufacturer logo colours and light dialog price-history foreground. Screenshots legend-mac-final.png and used-dialog-mac-final.png supersede the earlier captures. New phone evidence: legend-phone.png and legend-dialog-phone.png.
- Debug inspection launches stopped. Normal online lib/main.dart launched on both Mac and iPhone; PID/log files /tmp/gt7-online.pid, /tmp/gt7-online.log and /tmp/gt7-online-phone.pid, /tmp/gt7-online-phone.log. No network override or mock preferences in either normal entrypoint.
- Mac CUA confirmed current redesigned Hagerty (real years, no fake mileage) under the shared app navigation. Window raised and left open for the user. Earlier stale windows are gone.
- No runtime exception or overflow in the final launch logs.

## Lifecycle
Implementation and verification complete. User explicitly confirmed final apply/archive on 2026-11-05. Spec/plan marked applied and complete bundle archived under .grace/changes/archive/C-DEALER-GT7-UI. No commit or push performed.
