---
name: flutter-run
description: Run this Flutter app and verify a change by looking at it — launch on macOS desktop or an iOS/Android simulator, hot reload after edits, read runtime errors, inspect the widget tree, take screenshots and drive taps. Use when asked to run or start the app, to check that a UI change works, to reproduce a layout or rendering bug, or whenever a change needs visual confirmation rather than just passing tests.
---

# Running and inspecting the GT7 Companion app

Analyzer and widget tests do **not** catch layout overflow, wrong images, or
empty lists caused by a broken parser. Those only show up on a device. Run the
app whenever a change touches the UI or the data that feeds it.

## Three routes, one set of capabilities

Whatever the harness, the same five things are needed: launch a device, launch
the app, hot reload after an edit, read errors and the widget tree, and see
pixels. This table says how to reach them from each harness used with this
repository.

| Harness | Launch, reload, inspect | Device pixels |
| --- | --- | --- |
| No MCP at all — always works | `flutter run` plus signals, see below | a widget test pumped at a chosen size |
| Claude Code | the `dart` MCP server declared in `.mcp.json`, tools named `mcp__dart__*` (`launch_app`, `hot_reload`, `get_runtime_errors`, `get_widget_tree`, `run_tests`) | the simulator control tool |
| DSH (this machine's desktop session) | MCP servers `dart-mcp-server` (`hot_reload`, `hot_restart`, `get_runtime_errors`, `widget_inspector`, `pub`), plus `flutter-devtools` and `marionette_mcp` for a running app | the `ios_sim_*` tools — `ios_sim_screenshot`, `ios_sim_tap_element`, `ios_sim_ui_tree` |

**A connected MCP server is not the same as callable tools.** A harness can
report the server as connected while none of its tools are registered in the
session — `claude mcp list` shows `dart: dart mcp-server - ✔ Connected` and yet
searching for `mcp__dart__list_devices` returns nothing, with no way to call it.
This has happened. Check once at the start; if the tools are missing, take the
CLI path and move on instead of hunting for them.

### The CLI path, which always works

`flutter run` reloads on signals, so a backgrounded run is fully drivable:

```bash
flutter run -d macos --pid-file /tmp/scratch/flutter.pid > /tmp/scratch/run.log 2>&1 &
kill -USR1 "$(cat /tmp/scratch/flutter.pid)"   # hot reload  (SIGUSR1)
kill -USR2 "$(cat /tmp/scratch/flutter.pid)"   # hot restart (SIGUSR2)
kill      "$(cat /tmp/scratch/flutter.pid)"    # stop
```

Poll the log with `grep` for `Reloaded`, `Syncing`, `EXCEPTION`, `OVERFLOWED`
or the app's own `debugPrint` output. Several devices can run at once — one pid
file each — and one `kill -USR1` per file reloads them all.

**Use the SDK this project pins.** `.fvmrc` names 3.47.5 and `.fvm/flutter_sdk`
symlinks it; `flutter` on `PATH` may be a different version. Running the wrong
one silently rewrites `pubspec.lock` — it downgraded 13 packages here. Call
`.fvm/flutter_sdk/bin/flutter` when it matters.

### What the Dart MCP server itself exposes

To see what the server would expose — also the fastest way to answer "can the
Dart MCP do X?" — probe it over JSON-RPC. This is harness-independent:

```bash
{ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"1"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'; sleep 6; } | dart mcp-server
```

It exposes 21 tools: `launch_app`, `stop_app`, `list_devices`, `get_app_logs`,
`list_running_apps`, `connect_dart_tooling_daemon`, `get_runtime_errors`,
`hot_reload`, `hot_restart`, `get_widget_tree`, `get_selected_widget`,
`set_widget_selection_mode`, `get_active_location`, `flutter_driver`,
`run_tests`, `dart_fix`, `dart_format`, `pub`, `pub_dev_search`, `add_roots`,
`remove_roots`, `create_project`.

**None of them takes a screenshot.** "Look at the screen" through the Dart MCP
means `get_widget_tree` — structure, not pixels. Pixels come from a device tool
(the `ios_sim_*` tools under DSH, the simulator control tool under Claude Code)
or from a widget test pumped at a size.

### The loop, in capability order

1. List devices and pick a target — `list_devices` (Dart MCP) or the harness's
   device tools.
2. Launch the app with the project root as a **plain path** (see the trap below).
   Returns a pid and a DTD URI.
3. Connect the tooling daemon with that URI — `connect_dart_tooling_daemon`.
4. Edit, then `hot_reload`, then `get_runtime_errors`; `get_widget_tree` (DSH:
   `widget_inspector`) when structure matters.
5. Stop the app by pid — `stop_app`.

## Seeing pixels

| Target | How |
|---|---|
| iOS / iPad simulator | the simulator tools — headless, no permissions needed |
| macOS window | **blocked on this machine.** `screencapture` needs Screen Recording and `osascript` needs Accessibility; both are denied to the terminal, so the desktop build cannot be seen |
| any width, no device | a widget test pumped at a chosen size |

Two consequences worth remembering:

**To check a desktop-width layout, run on an iPad.** `iPad Pro 11-inch` gives
834 logical points — past every desktop breakpoint this app has — and the
simulator tool screenshots it happily. That is how the three-column daily-race
row was verified without a macOS screenshot.

**Widget tests fail on overflow.** Pumping a widget at 800×1200 and asserting
on its layout also proves it does not overflow there, which covers most of what
a screenshot would have told you.

## Things that will waste your time otherwise

**`root` must be a plain path.** `launch_app` takes `/Users/…/gt7_companion`,
not `file:///Users/…`. Passing a URI fails with `ProcessException: No such file
or directory` naming the Flutter binary, which reads as if the SDK were
missing. It is not.

**Boot mobile devices before you look for them.** A shut-down simulator does
not appear in `list_devices` and cannot be attached:
`xcrun simctl list devices available`, then `xcrun simctl boot <udid>`;
Android needs `flutter emulators --launch Pixel_9_Pro`.

**With more than one simulator booted, pass `udid` on every call.** The panel
attaches to the device you name, but input keeps going to whichever device was
attached first — a swipe aimed at the iPad lands on the iPhone. Screenshots take
a `udid`; use it.

**Hot reload resets scroll _and_ pops navigation back to the start route.**
After every reload, re-navigate and re-scroll before comparing screenshots, or
you will be looking at the home page and wondering where your change went.

**Hot reload dies with the `flutter run` process.** Under the MCP server that
process is a child of the server; if the server goes away, hot reload starts
failing while `connect_dart_tooling_daemon` still succeeds. Relaunch rather
than debugging the daemon.

**A swipe that starts on a card can register as a tap** and navigate away.
Start the gesture over empty space, and keep it more than 4 pt from any screen
edge — closer than that the OS takes it as back / notification shade / app
switcher.

**Never pipe a `print`-based helper script to a file without `python3 -u`.**
Python buffers stdout when it is not a tty, the log stays empty, and the run
looks hung when it is only building.

## Layout traps specific to this app

The debug build paints a yellow-and-black overflow banner. Look for it.

**The home shell floats its navigation bar over everything** — the page, and
modal bottom sheets too. Any full-height scroller needs roughly 110 pt of
bottom padding or its last rows sit under the bar. `DailyRaceDetailsSheet` and
the GT Auto counters both carry it.

**`DailyRacesDisplay` is a content block, not a scroller.** It lays its
sections out in a `Column` and expects the page to scroll — `home_page.dart`
wraps it in a `SingleChildScrollView`. A test that hosts it in a bare 800×600
`Scaffold` overflows for reasons that have nothing to do with the test.

**Daily race cards carry no fixed size.** They fill the grid tile they are
given and scale their type from their own width; the tile shape comes from
`kDailyRaceCardAspectRatio`. Change the column breakpoints in
`daily_races_display.dart`, not the card.

## Tests

Prefer the MCP server's `run_tests` when it is available; otherwise `flutter
test` — through the pinned SDK.

`flutter test --tags network --run-skipped` runs the live-markup guard against
the two scraped sites. Both flags are required — see `dart_test.yaml`.

## Where this file and the setup live

`.mcp.json` at the repository root registers the Dart MCP server (it ships with
the Dart SDK — nothing to install), and `.claude/settings.json` opts Claude Code
into it. The skill itself lives in `.agents/skills/flutter-run/`, the directory
this repository's agent sessions read.

These three files spent two months on the branch that introduced them, which is
why the setup kept going missing on every other branch. They are on `main` now:
if the MCP server is unconfigured or this file is absent again, something has
reverted that landing, and that is the thing to fix.
