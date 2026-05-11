## ADDED Requirements

### Requirement: Semi-transparent gauge divisions
The analog gauge background divisions SHALL be rendered in semi-transparent gray so they do not compete visually with the active value indicator.

#### Scenario: Static gauge divisions render
- **WHEN** the speedometer or tachometer is drawn
- **THEN** the dial division segments are displayed in subdued gray rather than bright section colors

### Requirement: Active value indicator remains colored
The active gauge ring SHALL remain the only vivid colored element used to show current speed or RPM.

#### Scenario: Active indicator render
- **WHEN** the gauge value updates
- **THEN** the filled ring or active indicator is rendered in the appropriate color while the static divisions remain gray

### Requirement: Numeric labels on speedometer divisions
The speedometer SHALL show small numeric labels for the following major divisions: 40, 80, 120, 180, 200, 240, 280, and 320.

#### Scenario: Speedometer tick labels
- **WHEN** the speedometer gauge is rendered
- **THEN** each specified major division is labeled with its numeric value near the tick mark

### Requirement: Numeric labels on tachometer divisions
The tachometer SHALL show small numeric labels for the following major divisions: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, and 10.

#### Scenario: Tachometer tick labels
- **WHEN** the tachometer gauge is rendered
- **THEN** each specified major division is labeled with its numeric value near the tick mark
