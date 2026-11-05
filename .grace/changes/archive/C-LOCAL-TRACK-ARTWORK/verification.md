# C-LOCAL-TRACK-ARTWORK verification

User explicitly approved the four-step proposal and sequential execution. No commit/push requested.

- T-001: 42 locations / 124 configurations, each with photo/logo/layout; 372 DG-Edge + 5 GTSh course URLs. 211 unique files, 30,668,808 bytes. SHA-256/size/Pillow decode verification passed, no discovery/download failures. 111 local catalogue entries covered; profile/advertising/session payloads excluded.
- T-002: independent incremental updater and generated index. Default no-op and real --refresh-catalogue each downloaded zero image bytes. Validator, changed-body, repair, dedup and allowlist regression passed. Offline package verification passed.
- T-003: local-first cards/details and added track logo. Exact source URLs retained through model JSON, new SUGO image names resolve correctly, GTSh-only layout fallback supported. 45 selected Flutter tests passed; changed widgets/generated index/tests analyzer: No issues found.
- T-004: cold native Mac 1280 and iPhone 17e 390 load real metadata while track-image HTTP is denied. Card photo/layout and detail logo render; blockedTrackImageRequests=[] on both. No UI/image errors or overflow. A failed Marionette scrollTo lookup is an automation-only service extension exception, documented explicitly. Both platforms restored to standard lib/main.dart after checks; Mac left visible for user.

Evidence: /Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/track-artwork/
Update procedure and coverage: docs/research/track-artwork-2026-11-05/README.md
Final GRACE gate: 0 errors, 54 warnings (heuristic module-map diagnostics, including the new widget). Evidence: /tmp/tracks-grace-final.log

Applied and archived on 2026-11-05 after explicit user confirmation. Fresh pre-archive final validation passed with 0 errors. Spec and plan marked applied; no commit or push performed.
