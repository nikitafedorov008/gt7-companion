# GT7 Companion Agent Instructions

## Project overview
- Flutter app for GT7 telemetry display across mobile and desktop platforms.
- Real-time UDP telemetry ingestion and Salsa20 decryption in `lib/services/`.
- UI built with `lib/widgets/`, state managed with Provider and Flutter BLoC patterns.
- Routing uses `auto_route` via `lib/app.dart` and `lib/router/app_router.dart`.

## Key conventions
- Keep cross-platform code in Dart; avoid platform-specific native logic unless the change explicitly targets iOS/macOS/Windows/Linux host integration.
- The app follows a clean architecture with a layered code structure: services, models, repositories, blocs, widgets, pages, router, and theme are separated.
- Use `lib/dependency_injection/app_scope.dart` for centralized DI registration. All services, repositories, and BLoCs are added there once and consumed across the app.
- BLoC instances are exposed with `Provider<TBloc>` in `AppScope`, and widgets consume them with `BlocBuilder`, `BlocListener`, or `context.read<TBloc>()` as needed.
- New UI components should live under `lib/widgets/`, with feature screens under `lib/pages/`.
- Domain models belong in `lib/models/`; repository and service logic belongs in `lib/repositories/` and `lib/services/`.
- Prefer reusable widgets and `Theme.of(context)` for colors so light/dark mode works consistently.

## Tech stack
- Flutter / Dart app using stable Flutter SDK conventions.
- Routing with `auto_route` and `MaterialApp.router`.
- Primary state management is BLoC/Cubit (via `flutter_bloc`) for features and larger sections of code.
- Provider / ChangeNotifier are used only for small shared services, repositories, and lightweight state.
- UI layering uses responsive Flutter widgets and custom painters for telemetry visualization.

## Important files and paths
- `README.md` — canonical repository setup and architecture summary
- `openspec/config.yaml` — direct guide to architecture, patterns, and repo layout
- `lib/app.dart` — app root and router setup
- `lib/dependency_injection/app_scope.dart` — dependency injection bindings
- `lib/router/app_router.dart` — route definitions and auto_route config
- `lib/services/telemetry_service.dart` — core GT7 UDP telemetry service

## Build and test commands
- `flutter pub get`
- `flutter run`
- `flutter test`
- For platform-specific iteration, use `flutter run -d <device-id>` or `flutter build <platform>` as needed.

## Coding guidance for agents
- Preserve existing clean architecture layers.
- Follow existing state-management patterns: Provider for shared services, BLoC for feature state when already in use.
- When updating telemetry flow, do not move protocol parsing into widgets.
- For UI changes, prefer adding widgets under `lib/widgets/` and wiring them into `lib/pages/` or existing display widgets.
- When introducing network or service dependencies, register them in DI and keep them decoupled from widgets.

## Live app inspection (Dart MCP server)

`.mcp.json` registers `dart mcp-server`, which ships with the Dart SDK — nothing
to install. It talks to the Dart Tooling Daemon, the same daemon DevTools uses,
so an agent can run the app and look at it rather than asking the user to.

Typical loop:

1. `list_devices` → pick a target
2. `launch_app` with `root` as a **plain path** (not a `file://` URI — passing a
   URI makes the launch fail with a confusing `ProcessException`) — returns a
   PID and a DTD URI
3. `connect_dart_tooling_daemon` with that URI
4. `hot_reload` after edits, then `get_runtime_errors` / `get_widget_tree`
5. `stop_app` with the PID

Verified on this project: macOS launches in ~25 s, the iOS simulator in ~50 s,
and hot reload plus widget-tree inspection work on both. Android needs
`flutter emulators --launch Pixel_9_Pro` first; iOS simulators need
`xcrun simctl boot <udid>` before they appear in `list_devices`.

Prefer the server's `run_tests` over `flutter test` — its own description says
so, and it reports failures in a form built for agents.

## Notes for automation
- Use `README.md` and `openspec/config.yaml` as the primary references for project conventions.
- Avoid broad refactors unless the user requests them explicitly.
- Keep guidance minimal and actionable, with links to the repo documentation for deeper context.
