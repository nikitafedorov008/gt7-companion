# Telemetry connection UI

Implemented the user-selected second visual in the existing native Flutter app: graphite panel, white Connect PlayStation action, demo/settings, connected dashboard/disconnect actions, truthful waiting state, responsive stacking. IP/scanner and all four packet formats are in a scrollable connection-settings dialog; C is default. Draft changes apply only on Save/Connect. RU/EN typed strings and legacy adapter are consistent.

Validation: 142 targeted/regression tests pass through Dart MCP; 22 new connection tests. New widgets/tests analyze clean. Localization audit passes (566 messages); UDP retains 4 existing avoid_print infos. Live macOS (1280 and 1487 logical width) and iPhone 17e (390) checks include real taps, scanner, settings, form validation, demo/dashboard/Home/disconnect, keyboard scrolling and actual default-C heartbeat. Screenshots and visual comparison are linked in root design-qa.md, final result passed. Real console packets were unavailable.

The user explicitly requested implementation and both device checks; work proceeded sequentially. No additional source scope was introduced; unsuitable generated icon trials remain outside the repository. Existing full app background/header/Services preserved. No commit/push requested or performed.
