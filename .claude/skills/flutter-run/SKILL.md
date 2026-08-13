---
name: flutter-run
description: Run this Flutter app and verify a change by looking at it — launch on macOS desktop or an iOS/Android simulator, hot reload after edits, read runtime errors, inspect the widget tree, take screenshots and drive taps. Use when asked to run or start the app, to check that a UI change works, to reproduce a layout or rendering bug, or whenever a change needs visual confirmation rather than just passing tests.
---

# Running and inspecting the GT7 Companion app

Analyzer and widget tests do **not** catch layout overflow, wrong images, or
empty lists caused by a broken parser. Those only show up on a device. Run the
app whenever a change touches the UI or the data that feeds it.

## Tools

Two independent pieces, both already configured:

| What | Where | Use it for |
|---|---|---|
| `dart mcp-server` | `.mcp.json` | launch, hot reload, runtime errors, widget tree, tests |
| iOS Simulator control | built-in tool | the visible panel, screenshots, taps and swipes |

The Dart MCP server ships with the Dart SDK — there is nothing to install. It
talks to the Dart Tooling Daemon, the same daemon DevTools uses.

## The loop

1. **Pick a target.** `list_devices`. `macos` is always there and builds
   fastest (~25 s). The iOS simulator takes ~50 s.
2. **Boot the mobile device first if you need one.** A simulator that is
   shut down does not appear in `list_devices`:
   - iOS: `xcrun simctl list devices available`, then
     `xcrun simctl boot <udid>`
   - Android: `flutter emulators --launch Pixel_9_Pro`
3. **Open the panel before building** when the user should see the app: call
   the simulator tool with `action: "attach"`. It is cheap and opens instantly
   on a booted device.
4. **`launch_app`** with `device` and `root`. It returns a PID and a DTD URI.
5. **`connect_dart_tooling_daemon`** with that URI.
6. **Edit, then `hot_reload`.** Takes about a second. Follow with
   `get_runtime_errors`.
7. **Look at it.** Screenshot through the simulator tool; `get_widget_tree`
   when you need structure rather than pixels.
8. **`stop_app`** with the PID when done, and kill any stray
   `GT7 Companion` process.

## Things that will waste your time otherwise

**`root` must be a plain path.** `launch_app` takes
`/Users/…/gt7_companion`, not `file:///Users/…`. Passing a URI fails with
`ProcessException: No such file or directory` naming the Flutter binary, which
reads as if the SDK were missing. It is not.

**Hot reload dies with the `flutter run` process.** That process is a child of
the MCP server. If the server goes away, hot reload starts returning
"Hot reload failed" even though `connect_dart_tooling_daemon` still succeeds
against the app's own daemon. Relaunch rather than debugging the daemon.

**Hot reload resets the scroll position.** Swipe back down before comparing
screenshots of a list.

**Never pipe a `print`-based helper script to a file without `python3 -u`.**
Python buffers stdout when it is not a tty, the log stays empty, and the run
looks hung when it is only building.

**Swipes must start more than 4 pt from a screen edge**, or the OS takes them
as back / notification shade / app switcher gestures instead of scrolling.

## Layout checks worth making

The debug build paints a yellow-and-black overflow banner. Look for it — that
is the failure mode this app has hit before.

`lib/widgets/daily_races/daily_races_display.dart` puts race cards in a
horizontal strip of fixed height, and `DailyRaceCard` splits that height
between an image section and a text section. Content whose height varies —
a car-model chip on a one-make race, a long leader name — overflows the text
section first. Adjust the flex split before reaching for a taller strip.

## Tests

Prefer the MCP server's `run_tests` over `flutter test`; its own description
says so and it reports failures in a form built for agents.

`flutter test --tags network --run-skipped` runs the live-markup guard against
the two scraped sites. Both flags are required — see `dart_test.yaml`.
