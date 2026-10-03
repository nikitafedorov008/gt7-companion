# GT7 Companion Agent Instructions

## Project overview
- Flutter app for GT7 telemetry display across mobile and desktop platforms.
- Real-time UDP telemetry ingestion and Salsa20 decryption in `lib/services/`.
- UI built with `lib/widgets/`. App code uses Provider/ChangeNotifier; BLoC exists only in the two features written by another author (`lib/blocs/profile`, `lib/blocs/throttle_brake_graph`).
- Routing uses `auto_route` via `lib/app.dart` and `lib/router/app_router.dart`.

## Where code lives
- `lib/services/` — one external source per service: network, parsing, timeouts.
- `lib/repositories/` — composition of several sources plus domain merging; no HTTP here.
- `lib/models/<source>/` — models per source, hand-written JSON mapping.
- `lib/widgets/<vertical>/` — that vertical's UI **including its screens** (`@RoutePage()`): `car_dealer/{used,legendary}`, `daily_races`, `gt_auto`.
- `lib/pages/` — thin composer pages and modals only: the home hub, login, wishlist, stubs.
- `lib/dependency_injection/app_scope.dart` — the single DI point.
- `lib/theme/gt7_theme.dart` — dark theme and `gt7*` tokens, consumed by telemetry only.

## Key conventions
- Keep cross-platform code in Dart; avoid platform-specific native logic unless the change explicitly targets iOS/macOS/Windows/Linux host integration.
- The app follows a clean architecture with a layered code structure: services, models, repositories, blocs, widgets, pages, router, and theme are separated.
- Use `lib/dependency_injection/app_scope.dart` for centralized DI registration. Register in dependency order; dependent repositories use `ChangeNotifierProxyProvider`/`ProxyProvider2` with `update: (context, dep, instance) => instance ?? Repo(dep)`.
- Blocs (if any) are registered as `Provider<TBloc>(create: ..., dispose: (context, bloc) => bloc.close())` and consumed with `BlocBuilder`/`context.read`; do not add `BlocProvider`, `RepositoryProvider`, `context.select` or a service locator.
- New UI components live under `lib/widgets/`, next to the vertical they serve. A feature screen is a `@RoutePage()` class inside its vertical folder, not in `lib/pages/`.
- Domain models belong in `lib/models/`; repository and service logic belongs in `lib/repositories/` and `lib/services/`.
- Colours and text come from `Theme.of(context)` (`colorScheme`, `textTheme`) with `withValues(alpha:)`. The `gt7*` helpers in `lib/theme/gt7_theme.dart` are telemetry-only. The codebase has two generations — legacy files (`car_dealer`, `gt7info`, `gtdb`) use literal styles; keep a legacy file's own style when editing it.

## Tech stack
- Flutter / Dart app using stable Flutter SDK conventions (FVM-pinned; `.fvm/flutter_sdk`).
- Routing with `auto_route` and `MaterialApp.router`; screens are marked `@RoutePage()`.
- State management for app code: `ChangeNotifier` + `Provider`/`Consumer`, state exposed as data + `isLoading` + `error`.
- BLoC/Cubit (via `flutter_bloc`) exists only in the profile and throttle-brake-graph features.
- UI layering uses responsive Flutter widgets and custom painters for telemetry visualization.

## Important files and paths
- `README.md` — repository setup and architecture summary
- `docs/CODE_STYLE.md` — how code and UI are actually written, with file:line evidence; the `gt7-*` skills summarise it
- `.grace/context/*.xml` — GRACE 4 product and technical context
- `lib/app.dart` — app root and router setup
- `lib/dependency_injection/app_scope.dart` — dependency injection bindings
- `lib/router/app_router.dart` — route definitions and auto_route config
- `lib/services/telemetry_service.dart` — core GT7 UDP telemetry service

## Build and test commands
- `flutter pub get`
- `flutter run`
- `flutter test`
- `flutter analyze`
- For platform-specific iteration, use `flutter run -d <device-id>` or `flutter build <platform>` as needed.

## Coding guidance for agents
- Preserve existing architecture layers and the file layout described above.
- State pattern for app code: a `ChangeNotifier` repository/service injected via `Provider`, read with `context.read<T>()`, observed with `Consumer<T>`; no BLoC in these modules.
- When updating telemetry flow, do not move protocol parsing into widgets.
- For UI changes, add widgets inside the relevant vertical under `lib/widgets/` and wire them into that vertical's display widget; new screens belong there too.
- When introducing network or service dependencies, register them in DI and keep them decoupled from widgets.
- Read `docs/CODE_STYLE.md` (or the `gt7-*` skills) before writing UI: the screen skeleton, spacing scale, card shell, state handling and colour rules are fixed there.

## Notes for automation
- `docs/CODE_STYLE.md` and the `gt7-*` skills are the primary references for code and UI conventions; `README.md` for setup.
- Avoid broad refactors unless the user requests them explicitly.
- Keep guidance minimal and actionable, with links to the repo documentation for deeper context.

## GRACE 4 project protocol

Keywords: gt7, telemetry, flutter, dart, racing, udp, salsa20, daily-races, car-dealer.

This project uses the GRACE 4 `.grace` artifact model.

- Product and technical context: `.grace/context/*.xml`
- Current graph projection source: `.grace/graph/index.xml` plus routed graph documents such as `.grace/graph/main.xml`
- Current verification projection source: `.grace/verification/index.xml` plus routed verification documents such as `.grace/verification/main.xml`
- Active work: `.grace/changes/active/C-*/spec.xml` and `.grace/changes/active/C-*/plan.xml`
- Completed or terminal work: `.grace/changes/archive/C-*/*`

Legacy `docs/*.xml` files are GRACE 3 state, not GRACE 4 state. They are handled only by the
`grace-migrate` workflow; do not silently validate, convert, or delete them.

### Workflow rules

1. Do not implement source behavior before an approved active `GraceChangeSpec` and `GraceChangePlan` exist, unless the user explicitly requests a small direct fix.
2. Treat `spec.xml` as normative. Treat `design-context.xml` as explanatory memory only.
3. Before execution, check `BaselineAssertions`, `TargetAssertions`, `DurableScope`, and `ObservedWriteScope` in the plan.
4. Update durable `.grace` graph and verification state only as part of the approved change lifecycle.
5. Never store transient run state by mutating approved XML statuses. Runtime states are derived from current files, assertions, and scopes.

### Semantic anchor rules

- GRACE semantic anchors are XML tags, never attributes: use `<M-EXAMPLE />`, not `<Module ref="M-EXAMPLE" />`.
- Module IDs use `M-*`; data-flow IDs use `DF-*`; graph document wrappers use `GD-*`; verification entries use deterministic `V-M-*`; verification document wrappers use `VD-*`; change bundles use `C-*`.
- Code-level semantic markup remains grep-stable: `START_MODULE_CONTRACT`, `START_MODULE_MAP`, `START_CONTRACT:`, `START_BLOCK_`, and `START_CHANGE_SUMMARY`.

### Grep-first navigation

1. Locate module ownership through `.grace/graph/index.xml`, then open the routed graph document.
2. Locate verification through `.grace/verification/index.xml`, then open the routed verification document.
3. Locate active work through `.grace/changes/active/C-*`.
4. Use file-local `LINKS:` fields and `START_BLOCK_` anchors to narrow code reads before loading whole files.

### CLI checks

- `grace lint --path .` validates `.grace` grammar, projections, assertions, lifecycle locations, and scope overlaps.
- `grace status --path .` summarizes durable and operational GRACE 4 health.
- `grace module`, `grace verification`, and `grace file` navigate graph, verification, and file-local anchors.

### File-local markup reference

```dart
// START_MODULE_CONTRACT
//   PURPOSE: [What this module does]
//   SCOPE: [Bounded responsibility]
//   DEPENDS: [M-* dependencies or none]
//   LINKS: [Related M-* and V-M-* anchors]
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   exportedSymbol - one-line responsibility
// END_MODULE_MAP
//
// START_CONTRACT: functionName
//   PURPOSE: [What it does]
//   INPUTS: { paramName: Type - description }
//   OUTPUTS: { ReturnType - description }
//   SIDE_EFFECTS: [External state changes or none]
// END_CONTRACT: functionName
//
// START_BLOCK_EXAMPLE
// ... implementation slice ...
// END_BLOCK_EXAMPLE
```
