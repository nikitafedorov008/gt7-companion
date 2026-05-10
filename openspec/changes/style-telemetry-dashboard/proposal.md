## Why

The current GT7 telemetry screen displays raw values as plain text, which makes the UI feel more like a debug panel than a real racing dashboard. This change will improve driver immersion and readability by styling the screen with analog race instruments.

## What Changes

- Replace the plain telemetry value list with a dashboard-style layout.
- Add an analog speedometer and tachometer with moving needle gauges.
- Add stylized status indicators for tire condition, fuel, gear, and lap information.
- Keep the underlying telemetry data source and route behavior unchanged.

## Capabilities

### New Capabilities
- `telemetry-gauges`: Render GT7 telemetry as a dashboard with analog speedometer and tachometer gauges, plus race-style status indicators.

### Modified Capabilities
- 

## Impact

- Affected code: `lib/pages/home_page.dart`, telemetry display widgets, and any shared telemetry model/data classes used by the dashboard.
- No API or backend changes expected; this is a presentation-layer enhancement.
- Dependencies: may add or update custom gauge widget styling within the Flutter UI layer.
