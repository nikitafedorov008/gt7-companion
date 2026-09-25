## 1. UI Design and Layout

- [ ] 1.1 Add a new central tire metrics panel widget in `lib/widgets/telemetry/telemetry_display.dart`
- [ ] 1.2 Implement four tire metric cards arranged in a compact 2x2 grid
- [ ] 1.3 Adjust the existing gauge row layout to render the new panel between speed and RPM gauges on desktop widths

## 2. Responsive Behavior

- [ ] 2.1 Ensure the tire metrics panel stacks gracefully on narrower widths
- [ ] 2.2 Verify the speedometer, tire panel, and tachometer all remain visible without overflow on mobile layouts

## 3. Data Display and Styling

- [ ] 3.1 Bind the panel to the `TelemetryData` tire temperature values for FL, FR, RL, and RR
- [ ] 3.2 Reuse existing styling conventions for tire status labels and temperature colors

## 4. Validation and Review

- [ ] 4.1 Review the new layout in the telemetry display to ensure the panel appears centered between gauges
- [ ] 4.2 Confirm the change is limited to `lib/widgets/telemetry/telemetry_display.dart` and does not modify unrelated app layers
