## Why

The current analog telemetry gauges use static colored segments and a needle, which makes it harder to read RPM and speed as a continuous fill level. A rounded loading-style ring with dynamic color provides a clearer, more modern visualization of current value intensity.

## What Changes

- Replace the needle-driven display for speedometer and tachometer with a circular progress-style ring that fills based on current value.
- Use dynamic coloring on the ring so it transitions from green through yellow to red depending on the current RPM or speed level.
- Preserve the existing gauge sections while making the visual style behave like a round loading indicator around the instrument.
- Ensure both tachometer and speedometer share the same fill-driven display behavior.

## Capabilities

### New Capabilities
- `round-loading-gauge`: Define a continuous circular gauge display for speed and RPM, with value-driven fill and dynamic color transition.

### Modified Capabilities
- `<existing-name>`: <what requirement is changing>

## Impact

- Affected code: `lib/widgets/telemetry/telemetry_display.dart` and related gauge rendering logic.
- This is primarily a UI widget update and should not impact telemetry data handling or networking.
- No new dependencies are expected; the change will use Flutter drawing and layout APIs.
