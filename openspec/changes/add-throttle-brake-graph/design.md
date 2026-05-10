## Context

The GT7 Companion application is a Flutter-based telemetry viewer for Gran Turismo 7, receiving real-time vehicle data via UDP from PlayStation. The current telemetry display (`TelemetryDisplay` widget) shows gauges, stats, and tire status information. The application follows a layered architecture with:

- **Models**: `TelemetryData` containing 100+ telemetry properties including throttle and brake values
- **Services**: `TelemetryService` managing real-time UDP data reception and state
- **UI**: Custom widget composition with gauge visualization using `CustomPaint`
- **State Management**: BLoC pattern for app-level state; Provider for services

The telemetry data already includes throttle and brake values as numeric properties (0-100%). The challenge is visualizing these inputs as a time-series graph positioned below existing telemetry elements.

## Goals / Non-Goals

**Goals:**
- Add a throttle/brake input graph component to the telemetry display
- Show real-time throttle and brake values as time-series lines
- Display graph below all existing telemetry elements
- Maintain responsive design (mobile and desktop layouts)
- Integrate with existing `TelemetryService` state management

**Non-Goals:**
- Recording or persistence of telemetry history to database
- Advanced features like lap comparison or playback scrubbing
- External charting library dependencies (keep implementation lightweight)
- New API endpoints or data format changes

## Decisions

### Decision 1: Custom Canvas Implementation over External Library
**Choice**: Use Flutter's `CustomPaint` with `Path` API for graph rendering instead of adding a charting dependency (FL Chart, Syncfusion, etc.)

**Rationale**: 
- Aligns with existing codebase pattern (`_GaugePainter` uses `CustomPaint`)
- Keeps dependencies minimal
- Full control over styling and animation
- Simpler code review and maintenance
- Graph visualization is straightforward (two lines, basic axes)

**Alternatives**:
- FL Chart: Good feature set but adds npm package overhead; would need theming integration
- Syncfusion: More powerful but heavier dependency footprint
- Web-based charting (JS): Not applicable to Flutter

### Decision 2: Fixed Time Window with Scroll/Ring Buffer
**Choice**: Display a fixed time window (e.g., last 10 seconds of data) in a ring buffer that updates in real-time.

**Rationale**:
- Prevents unbounded memory growth over long sessions
- Simpler implementation than full zoom/pan
- Matches typical race duration (5-30 minutes) display patterns
- Mobile-friendly (no complex scrolling gestures)

**Alternatives**:
- Store all history: Would consume increasing memory/battery over race duration
- Zoom/pan controls: Added complexity; not essential for initial version

### Decision 3: Component Structure
**Choice**: Create a new `ThrottleBrakeGraph` widget in `lib/widgets/telemetry/` as a reusable component within `TelemetryDisplay`.

**Rationale**:
- Maintains separation of concerns
- Allows independent testing and reuse
- Clear integration point with existing widget hierarchy

**Alternatives**:
- Inline the graph directly in `TelemetryDisplay`: Reduces reusability
- Create a separate screen/route: Doesn't match the requirement to show it on existing telemetry screen

### Decision 4: State Management with BLoC
**Choice**: Create a `ThrottleBrakeGraphBloc` to manage throttle/brake history and graph state, using BLoC pattern for separation of concerns.

**Rationale**:
- Aligns with application's BLoC architecture
- Clear separation between business logic (history buffer) and UI rendering
- Easy to test buffer logic independently
- Scales well if graph features expand (zoom, export, etc.)
- Widget listens to BLoC state via `BlocBuilder` or `BlocListener`

**Alternatives**:
- Use Consumer pattern: Simpler but mixed concerns; not aligned with app architecture
- Extend `TelemetryService`: Overloads service with UI-specific logic
- Local widget state only: No centralized history management; harder to test

### Decision 5: Data Source and Buffer Management
**Choice**: `ThrottleBrakeGraphBloc` subscribes to `TelemetryService`; maintains ring buffer of last 300-600 data points (10 seconds).

**Rationale**:
- BLoC layer handles buffer management and history aggregation
- No need to modify `TelemetryService` core logic
- Throttle/Brake events sent to BLoC for processing

**Alternatives**:
- Store all history in service: Bloats service responsibility
- Manual event subscriptions in widget: Doesn't use BLoC pattern

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Memory growth with long races** | Battery drain, potential jank if buffer grows unbounded | Implement fixed ring buffer (300-600 points); clear old data |
| **Canvas performance with high-frequency updates** | Potential frame drops at 60 FPS with many redraws | Optimize `CustomPaint` redraw logic; only redraw when data actually changes |
| **Two colors on small mobile screens** | Graph may be hard to read on small devices | Test on typical mobile screen sizes; ensure minimum graph height; consider line width scaling |
| **Axis labels and grid rendering** | Graph can become cluttered | Keep axes minimal (no grid lines for MVP); simple Y-axis labels (0%, 50%, 100%) |
| **Real-time data arriving faster than UI refresh** | Dropped frames if multiple packets arrive between frame draws | Process batches in single build; let Flutter handle frame pacing naturally |

## Migration Plan

1. **Create BLoC files**:
   - `lib/blocs/throttle_brake_graph/throttle_brake_graph_event.dart`
   - `lib/blocs/throttle_brake_graph/throttle_brake_graph_state.dart`
   - `lib/blocs/throttle_brake_graph/throttle_brake_graph_bloc.dart`
2. **Create widget file**: `lib/widgets/telemetry/throttle_brake_graph.dart` (uses `BlocBuilder` to listen to BLoC state)
3. **Register BLoC**: Add `ThrottleBrakeGraphBloc` to app-level BLoC providers
4. **Integrate into `TelemetryDisplay`**: Add widget below existing telemetry elements
5. **Test on mobile and desktop**: Ensure responsive layout; verify no performance regression
6. **No breaking changes**: Existing telemetry display remains unchanged; graph is additive

## Open Questions

- **Time window duration**: Should the graph show 5, 10, or 15 seconds of history? (Recommend 10 seconds for good detail without too much scrolling)
- **Y-axis labels**: Show 0%, 50%, 100% or finer granularity like 0%, 25%, 50%, 75%, 100%?
- **Graph height on different screens**: Fixed pixels, flex-based, or aspect ratio constrained?
- **Data point frequency**: Are telemetry updates 60 Hz, 100 Hz, or variable? (Impacts buffer sizing)
- **BLoC provider scope**: Should `ThrottleBrakeGraphBloc` be app-scoped or created per `TelemetryDisplay`? (Recommend app-scoped for resource efficiency)
