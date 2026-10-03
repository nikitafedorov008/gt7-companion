---
name: gt7-project-map
description: Map of the GT7 Companion Flutter app - which layer holds what, where feature screens actually live, and what is out of bounds. Use before any change in this repository, or when AGENTS.md and the code disagree (they do).
---

# GT7 Companion — project map

Full evidence with `file:line` citations lives in [`docs/CODE_STYLE.md`](../../../docs/CODE_STYLE.md).
This is the short version an agent needs before touching code.

## Layers

| Path | Holds | Never holds |
| --- | --- | --- |
| `lib/services/` | one external source per service (UDP, dg-edge, gtsh-rank, gt7info, GTDB, official GT7 API): network, parsing, timeouts | domain merging, widgets |
| `lib/repositories/` | composition of several sources + domain merge/dedup/sort | HTTP calls at all |
| `lib/models/<source>/` | models per data source, manual JSON mapping | network calls |
| `lib/widgets/<vertical>/` | that vertical's UI, **including its screens** (`@RoutePage()`) | network access, business logic |
| `lib/pages/` | thin composer pages and modals: home hub, login, wishlist, empty | feature screens of verticals |
| `lib/blocs/` | only foreign blocs (profile, throttle_brake_graph) | author-written blocs |
| `lib/dependency_injection/app_scope.dart` | every provider registration, the single DI point | anything else |
| `lib/theme/gt7_theme.dart` | dark theme, palette, `gt7*` tokens, one ThemeExtension | consumed by non-telemetry UI |

## Screens live in `lib/widgets/**`, not `lib/pages/**`

`@RoutePage()` sits on classes inside vertical folders:
`lib/widgets/car_dealer/used/used_car_display.dart`, `lib/widgets/car_dealer/legendary/legendary_car_display.dart`,
`lib/widgets/gt_auto/gt_auto_display.dart`, `lib/widgets/daily_races/daily_races_display.dart`,
`lib/widgets/nested_widget.dart` (tab shell). `lib/pages/` holds only the home hub, login, wishlist and stubs.

## Out of bounds for style work

Telemetry and profile were written by another author and do not follow the rules in these skills:

- telemetry: `lib/widgets/telemetry/**`, `lib/models/telemetry/**`, `lib/services/{telemetry,udp}_service.dart`,
  `lib/utils/crypto_utils.dart`
- profile: `lib/pages/profile_page.dart`, `lib/blocs/{profile,throttle_brake_graph}/**`,
  `lib/repositories/profile_repository.dart`

They are the only consumers of `gt7Caption`, `gt7Digital`, `gt7PanelDecoration` and `GT7GraphColors`.
Do not restyle them, and do not pull their tokens into the verticals.

## `AGENTS.md` is inaccurate — three corrections

1. It says BLoC/Cubit is the primary state management. In author-written code there is **no BLoC at all**;
   state is `ChangeNotifier` + `Provider`/`Consumer`.
2. It says feature screens live in `lib/pages/`. They live in `lib/widgets/**` with `@RoutePage()`.
3. It says to prefer `Theme.of(context)` for colors. That is true for newer modules, but the
   `gt7*` theme tokens are telemetry-only.

When a task is described by `AGENTS.md`, prefer the code and these skills.

## Two generations of code

- **Legacy:** `lib/widgets/car_dealer/**`, `lib/models/{car_dealer,gt7info,gtdb}`, `lib/pages/home_page.dart`,
  `lib/widgets/adaptive_navbar.dart` — literal `TextStyle`/`Colors.*`, `_buildXxx()` methods, `withOpacity`/`withAlpha`.
- **Canon:** `lib/widgets/{daily_races,gt_auto}/**`, `lib/models/{gt7_stats,gt7_sport_*,dg_edge,gtsh_rank}` —
  `Theme.of(context)`, `withValues(alpha:)`, extracted private widget classes.

Keep a legacy file's own style when editing it; write new files in the canon.

## Commands

```sh
flutter pub get
flutter run                 # FVM-pinned SDK: .fvm/flutter_sdk
flutter test
flutter analyze
```
