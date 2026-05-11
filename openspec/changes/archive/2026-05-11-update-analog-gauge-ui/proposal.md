## Why

The current analog gauge UI makes it difficult to read RPM and speed because the needle overlaps the numeric labels and the gauge ring does not visually communicate engine load. Improving the tachometer and speedometer visuals will make telemetry easier to interpret at a glance.

## What Changes

- Update tachometer gauge ring coloring so it transitions from transparent/neutral at low RPM to bright red as RPM increases.
- Add more tick divisions to analog telemetry gauges for finer visual precision.
- Reposition numeric RPM and speed labels below the needle path so the needle does not overlap the labels.
- Apply the same improved layout behavior to the speedometer and tachometer gauges.

## Capabilities

### New Capabilities
- `analog-gauge-visuals`: Define the updated analog gauge UI behavior for tachometer and speedometer, including dynamic ring color, more tick divisions, and label placement.

### Modified Capabilities
- `<existing-name>`: <what requirement is changing>

## Impact

- Affected code: `lib/widgets/` gauge rendering widgets, relevant BLoC/UI state if label layout depends on runtime sizing, and app theming if gauge color scales use theme values.
- Likely changes in `lib/models/` or `lib/services/` are minimal; this is primarily UI and widget layout work.
