## ADDED Requirements

### Requirement: Display tire metrics panel between gauges
The main telemetry dashboard SHALL display a centered tire metrics panel between the speedometer and tachometer when telemetry data is available.

#### Scenario: Layout includes tire metrics panel
- **WHEN** telemetry data is present and the display is rendered
- **THEN** the UI SHALL show the speedometer on the left, the tire metrics panel in the center, and the tachometer on the right

### Requirement: Show four tire values in 2x2 grid
The tire metrics panel SHALL present four tire cards arranged in a compact 2x2 grid for FL, FR, RL, and RR.

#### Scenario: Tire status cards rendered
- **WHEN** the tire metrics panel is visible
- **THEN** it SHALL show four labeled cards for FL, FR, RL, and RR with current temperature values

### Requirement: Maintain responsive layout for mobile and desktop
The tire metrics panel SHALL adapt the gauge layout so that it remains readable on both narrow and wide screens without losing the central position between speed and RPM gauges.

#### Scenario: Responsive layout adapts width
- **WHEN** the display width is smaller than the mobile threshold
- **THEN** the gauges and tire metrics panel SHALL stack or adjust so the tire panel remains visible and content does not overflow
