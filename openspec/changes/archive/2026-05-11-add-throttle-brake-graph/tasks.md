## 1. BLoC Setup

- [x] 1.1 Create `lib/blocs/throttle_brake_graph/throttle_brake_graph_event.dart` with events (TelemetryUpdated, Initialize, Clear)
- [x] 1.2 Create `lib/blocs/throttle_brake_graph/throttle_brake_graph_state.dart` with states (Initial, Loading, Success with history data)
- [x] 1.3 Create `lib/blocs/throttle_brake_graph/throttle_brake_graph_bloc.dart` with ring buffer management logic
- [x] 1.4 Define constants for BLoC (time window duration, buffer size, max data points)
- [x] 1.5 Implement ring buffer logic in BLoC to maintain last N seconds of throttle/brake data
- [x] 1.6 Register `ThrottleBrakeGraphBloc` in app-level providers (main.dart or appropriate BLoC setup file)

## 2. BLoC Event Handling

- [x] 2.1 Implement listener to `TelemetryService` that sends TelemetryUpdated events to BLoC
- [x] 2.2 Implement BLoC event handler for TelemetryUpdated with throttle/brake extraction
- [x] 2.3 Ensure BLoC maintains chronological ordering of data points in history
- [x] 2.4 Implement data point filtering to prevent duplicate timestamps

## 3. Widget Implementation

- [x] 3.1 Create new file `lib/widgets/telemetry/throttle_brake_graph.dart`
- [x] 3.2 Implement `ThrottleBrakeGraph` widget with `BlocBuilder<ThrottleBrakeGraphBloc>` listener
- [x] 3.3 Implement `_ThrottleBrakeGraphPainter` CustomPaint painter class
- [x] 3.4 Create painter delegate class that properly implements size/paint/shouldRepaint

## 4. Graph Rendering

- [x] 4.1 Implement Y-axis labels (0%, 50%, 100%) in the painter
- [x] 4.2 Implement X-axis with time markers in the painter
- [x] 4.3 Implement throttle line drawing (green color) in the painter
- [x] 4.4 Implement brake line drawing (red color) in the painter
- [x] 4.5 Add legend/color key to identify throttle vs brake lines
- [x] 4.6 Handle empty/loading state when no history data yet

## 5. Integration and Layout

- [x] 5.1 Integrate `ThrottleBrakeGraph` widget into `TelemetryDisplay` below existing telemetry elements
- [x] 5.2 Set appropriate height constraints for the graph (fixed or flex-based)
- [x] 5.3 Ensure responsive layout works on both mobile and desktop screen sizes
- [x] 5.4 Test layout doesn't overflow or cause layout issues on small screens
- [x] 5.5 Ensure graph padding and margins align with existing design

## 6. Real-time Updates and Performance

- [x] 6.1 Test BLoC receives telemetry updates correctly
- [x] 6.2 Optimize `CustomPaint` redraw logic to avoid unnecessary repaints
- [x] 6.3 Verify shouldRepaint method correctly identifies state changes
- [x] 6.4 Test for performance issues (frame drops, jank) with continuous telemetry updates
- [x] 6.5 Verify memory usage remains stable over long telemetry sessions (5+ minutes)

## 7. Testing and Polish

- [x] 7.1 Test graph display with sample telemetry data (mobile device or emulator)
- [x] 7.2 Test graph display with desktop layout
- [x] 7.3 Test graph behavior when telemetry connection is lost (loading state)
- [x] 7.4 Test graph behavior when switching between screens and returning to telemetry
- [x] 7.5 Test BLoC cleanup and disposal when leaving telemetry screen
- [x] 7.6 Add comments and documentation to BLoC and graph rendering code

## 8. Code Review and Cleanup

- [x] 8.1 Review BLoC code for proper state management patterns
- [x] 8.2 Review code for style consistency with existing codebase
- [x] 8.3 Ensure no debug print statements or unused imports
- [x] 8.4 Verify all requirements from specs are met
- [x] 8.5 Final testing on actual device with live GT7 telemetry data
