## Why

The telemetry screen currently displays individual telemetry values but lacks visual representation of driver input patterns. Adding a throttle and brake graph will help drivers visualize and analyze their throttle/brake inputs over time, enabling better performance analysis and improvement of driving technique.

## What Changes

- Add a throttle/brake input graph component to the telemetry screen
- Display gas and brake pedal inputs as a time-series visualization positioned below existing telemetry elements
- Track and plot throttle (0-100%) and brake (0-100%) values over the race timeline
- Support real-time updates as telemetry data is received

## Capabilities

### New Capabilities
- `throttle-brake-graph`: Displays a visual graph of throttle and brake pedal inputs over time on the telemetry screen

### Modified Capabilities
<!-- No existing capabilities require specification changes for this feature -->

## Impact

- **UI Components**: Will add a new graph component to the telemetry display
- **Telemetry System**: Existing telemetry data collection should already capture throttle/brake values; no changes needed
- **Layout**: Telemetry screen layout will be adjusted to accommodate the new graph below existing elements
- **Dependencies**: May require charting library (check if one exists in the project)
