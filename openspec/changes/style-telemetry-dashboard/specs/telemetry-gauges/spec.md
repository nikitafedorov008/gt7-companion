## ADDED Requirements

### Requirement: Dashboard-style telemetry presentation
The system SHALL display GT7 telemetry using a dashboard-style interface instead of plain text values.

#### Scenario: Render telemetry dashboard on connection
- **WHEN** the telemetry screen is active and telemetry data is available
- **THEN** the screen displays an analog speedometer and an analog tachometer
- **THEN** the dashboard also displays tire condition, fuel level, gear, and lap status indicators

### Requirement: Analog speedometer
The system SHALL render speed as an analog gauge with a needle indicating the current speed.

#### Scenario: Speedometer updates with telemetry
- **WHEN** telemetry updates the vehicle speed
- **THEN** the speedometer needle animates to the new speed value
- **THEN** the gauge remains visible and labeled as speed

### Requirement: Analog tachometer
The system SHALL render engine RPM as an analog tachometer gauge with a needle.

#### Scenario: Tachometer updates with telemetry
- **WHEN** telemetry updates the engine RPM
- **THEN** the tachometer needle animates to the new RPM value
- **THEN** the gauge remains visible and labeled as RPM

### Requirement: Race-style status indicators
The system SHALL show tire condition, fuel level, and gear/lap state as visually distinct indicators near the gauges.

#### Scenario: Display tire and fuel status
- **WHEN** telemetry provides tire surface or quality data
- **THEN** the dashboard shows each tire condition using a label or badge
- **THEN** the dashboard shows a fuel-level indicator

### Requirement: Preserve existing telemetry data source
The system SHALL use the existing telemetry data source and shall not require new backend telemetry APIs.

#### Scenario: Existing telemetry service integration
- **WHEN** telemetry data arrives from `TelemetryService`
- **THEN** the dashboard updates using the same model objects already provided by the current telemetry route
