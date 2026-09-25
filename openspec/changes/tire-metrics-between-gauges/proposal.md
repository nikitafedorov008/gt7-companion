## Why

Telemetry visualization currently places the speedometer and tachometer side by side without a dedicated tire status section, making it harder to compare core vehicle metrics at a glance. Adding a centered tire metrics panel improves readability and gives drivers a clearer view of tire health while keeping the primary gauge layout intact.

## What Changes

- Add a central tire metrics panel between the speedometer and tachometer in the main telemetry display.
- Display four tire status cards in a compact 2x2 layout representing FL, FR, RL, and RR.
- Keep the existing speedometer and tachometer gauges on the left and right respectively.
- Ensure the layout adapts cleanly between desktop and mobile widths.

## Capabilities

### New Capabilities
- `tire-metrics-panel`: Defines the tire status display panel between the speedometer and tachometer.

### Modified Capabilities
- None

## Impact

- UI layer: `lib/widgets/telemetry/telemetry_display.dart`
- Potential layout helpers or responsive widget behavior in telemetry display
- No external dependency changes expected
