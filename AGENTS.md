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
- `openspec/config.yaml` — OpenSpec change workflow configuration
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
