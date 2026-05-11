## ADDED Requirements

### Requirement: Throttle/brake graph state management
The system SHALL manage throttle and brake history using a dedicated `ThrottleBrakeGraphBloc` that maintains a ring buffer of input values.

#### Scenario: BLoC initializes and listens to telemetry
- **WHEN** the app starts
- **THEN** `ThrottleBrakeGraphBloc` is initialized and begins listening to `TelemetryService` for throttle/brake events

#### Scenario: BLoC maintains history buffer
- **WHEN** new telemetry data is received
- **THEN** BLoC updates its ring buffer with new throttle/brake values without exceeding buffer capacity

### Requirement: Display throttle and brake input graph
The system SHALL display a graph visualization of throttle and brake pedal inputs on the telemetry screen below existing telemetry elements.

#### Scenario: Graph renders with telemetry data
- **WHEN** the telemetry screen is displayed and BLoC has history data
- **THEN** a graph component appears at the bottom showing throttle and brake input history

### Requirement: Throttle input visualization
The system SHALL display the throttle (gas pedal) input as a line on the graph showing values from 0-100%.

#### Scenario: Throttle line appears on graph
- **WHEN** telemetry data contains throttle values
- **THEN** a throttle line is rendered on the graph with appropriate color (e.g., green or blue)

#### Scenario: Throttle values update in real-time
- **WHEN** new telemetry data is received
- **THEN** BLoC updates its state and the throttle line is rendered with the new input value

### Requirement: Brake input visualization
The system SHALL display the brake pedal input as a line on the graph showing values from 0-100%.

#### Scenario: Brake line appears on graph
- **WHEN** telemetry data contains brake values
- **THEN** a brake line is rendered on the graph with a distinct color (e.g., red)

#### Scenario: Brake values update in real-time
- **WHEN** new telemetry data is received
- **THEN** BLoC updates its state and the brake line is rendered with the new input value

### Requirement: Graph legend and labels
The system SHALL provide clear visual distinction between throttle and brake inputs with appropriate labels.

#### Scenario: Legend identifies throttle and brake
- **WHEN** the graph is displayed
- **THEN** a legend or color-coded labels clearly identify which line represents throttle and which represents brake

### Requirement: Graph positioning
The system SHALL position the throttle/brake graph below all other telemetry display elements on the screen.

#### Scenario: Graph appears at bottom of telemetry screen
- **WHEN** the telemetry screen is rendered with multiple elements
- **THEN** the throttle/brake graph is positioned below all existing telemetry data displays
