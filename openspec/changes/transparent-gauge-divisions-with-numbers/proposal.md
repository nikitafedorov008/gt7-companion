## Why

The current analog gauges use strong colored segments for the dial divisions, which competes visually with the value indicator. Making these divisions translucent gray improves focus on the active value ring and reduces visual clutter.

## What Changes

- Render analog gauge dial divisions as semi-transparent gray instead of fully saturated colored bands.
- Keep only the active value indicator around the instrument colored and vibrant.
- Add small numeric labels for tick divisions on the speedometer at 40, 80, 120, 180, 200, 240, 280, and 320.
- Add small numeric labels for tick divisions on the tachometer at 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, and 10.

## Capabilities

### New Capabilities
- `transparent-gauge-divisions`: Update analog gauge dial styling so inactive divisions are gray and only the active fill indicator is colored, with labeled numeric ticks for speed and RPM.

### Modified Capabilities
- `<existing-name>`: <what requirement is changing>

## Impact

- Affected code: primarily `lib/widgets/telemetry/telemetry_display.dart` and any shared gauge rendering widgets.
- This is a UI styling and readability improvement, not a telemetry data or business-logic change.
- No new external dependencies are required; the change uses existing Flutter rendering and layout functionality.
