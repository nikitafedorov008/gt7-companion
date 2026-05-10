## 1. UI Layout and Wireframe

- [ ] 1.1 Review the current `TelemetryDisplay` screen and identify the text fields to replace with the dashboard layout
- [ ] 1.2 Create the dashboard layout with two main sections: analog gauges and status indicators
- [ ] 1.3 Ensure the new layout is responsive for mobile and wider screens

## 2. Gauge and Indicator Implementation

- [ ] 2.1 Implement an analog speedometer widget with a needle and numeric overlay
- [ ] 2.2 Implement an analog tachometer widget with a needle and RPM labels
- [ ] 2.3 Add tire condition, fuel level, gear, and lap status indicators near the gauges
- [ ] 2.4 Animate gauge needle movement smoothly when telemetry values change

## 3. Integration and Verification

- [ ] 3.1 Hook the dashboard widgets to the existing `TelemetryService` telemetry model
- [ ] 3.2 Preserve the existing connected/demo behavior when switching to the new dashboard view
- [ ] 3.3 Test the new screen with live telemetry and demo telemetry to verify gauge updates
- [ ] 3.4 Clean up any removed plain-text telemetry display code and confirm no regressions
