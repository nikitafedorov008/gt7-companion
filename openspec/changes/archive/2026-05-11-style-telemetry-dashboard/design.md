## Context

The current GT7 telemetry screen is implemented as a simple text display, which is easy to read but does not match the visual language of a racing dashboard. The telemetry source and route structure remain unchanged. This change is purely a presentation-layer redesign for the in-app telemetry experience.

## Goals / Non-Goals

**Goals:**
- Present speed and engine RPM as analog gauges with animated needles.
- Show tire condition, fuel level, and gear/lap state using race-style status indicators.
- Keep telemetry data flow unchanged and support existing demo/connected modes.
- Improve readability and driver immersion without adding backend complexity.

**Non-Goals:**
- This change does not add new telemetry metrics or change the telemetry API.
- It does not rewrite the telemetry service or network connection logic.
- It does not add a full dashboard simulation mode beyond presenting existing values.

## Decisions

- Use Flutter widgets and `CustomPainter` or lightweight gauge widgets to render the analog speedometer and tachometer. This keeps the UI implementation self-contained and avoids adding a heavy third-party dependency.
- Keep the existing `TelemetryDisplay` route and build from the same `TelemetryService` data so the change stays isolated to the presentation layer.
- Build a responsive layout that adapts to narrow mobile screens and wider desktop/tablet layouts without requiring separate screens.
- Use animated needle transitions for gauge updates rather than abrupt text jumps, improving perceived polish.

## Risks / Trade-offs

- [Performance] Rendering animated custom gauges may be heavier than plain text. Mitigation: limit gauge updates to only the values that changed and use efficient `CustomPainter` logic.
- [Complexity] Custom gauges add UI complexity. Mitigation: keep the design simple with two main analog instruments plus clear status indicators.
- [Consistency] Styling must work across light/dark themes. Mitigation: use theme-aware colors and ensure contrast for gauge labels and status badges.
