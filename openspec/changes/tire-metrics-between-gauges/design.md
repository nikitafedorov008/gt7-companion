## Context

The current `TelemetryDisplay` shows the speedometer and tachometer side by side with other status panels below. There is no dedicated central tire metrics panel, which makes it harder to compare tire health alongside the primary gauges.

## Goals / Non-Goals

**Goals:**
- Add a centered tire metrics panel between speed and RPM gauges.
- Display four tire values in a compact 2x2 grid.
- Preserve responsive behavior for desktop and mobile widths.
- Keep changes limited to the UI layer and avoid unnecessary service or model updates.

**Non-Goals:**
- Changing telemetry data sources or UDP packet parsing.
- Introducing new app-wide state management beyond the existing widget tree.
- Adding new dependencies or external packages.

## Decisions

- **Widget placement:** Extend `TelemetryDisplay._buildGauges` to render a third child between the two existing `GaugeCard` widgets when wide enough. This keeps the implementation local to the telemetry display and avoids broad refactors.
- **Tire panel structure:** Implement a new reusable `_TireMetricsPanel` widget with four `_TireMetricCard` children. The panel will use a 2x2 `Wrap` or `GridView` layout to ensure consistent spacing and compact presentation.
- **Responsive layout:** Keep the current `Flex` wrapper for `isDesktop` widths. When narrow, stack the speedometer, tire panel, and tachometer vertically with spacing. For desktop, use a three-column row with the tire panel occupying the center column.
- **Data binding:** Use existing `TelemetryData` values (`tireTempFL`, `tireTempFR`, `tireTempRL`, `tireTempRR`). No new model fields are required.
- **Styling:** Reuse the existing glyph and color styling conventions from `_TireStatusBadge` and `_DetailChip` for visual consistency.

## Risks / Trade-offs

- [Layout complexity] → The new center panel may crowd the view on narrow desktops if not sized carefully. Mitigation: make the center panel flexible and allow vertical stacking on smaller widths.
- [Widget cohesion] → Adding extra display logic directly in `telemetry_display.dart` could make that file larger. Mitigation: keep the panel implementation as small reusable widgets within the same file and avoid adding unrelated functionality.
