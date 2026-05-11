## 1. Analyze existing gauge implementation

- [x] 1.1 Review `lib/widgets/telemetry/telemetry_display.dart` and identify the current gauge painting and label layout.
- [x] 1.2 Confirm where speedometer and tachometer gauges are instantiated and what value ranges they use.

## 2. Implement gauge ring color dynamics

- [x] 2.1 Update `_GaugePainter` to compute a normalized RPM ratio from `currentValue / maxValue`.
- [x] 2.2 Add a dynamic ring color or overlay that interpolates from neutral to red based on RPM.
- [x] 2.3 Ensure the ring color only appears when RPM is above zero and remains subtle at low RPM.

## 3. Improve tick mark density

- [x] 3.1 Increase the number of major and minor tick marks drawn in `_GaugePainter`.
- [x] 3.2 Use distinct styling for major versus minor ticks while keeping the gauge readable.
- [x] 3.3 Test the gauge appearance at multiple values to verify the new divisions are visible.

## 4. Reposition label layout

- [x] 4.1 Move the numeric value and units label in `GaugeCard` downward inside the gauge content area.
- [x] 4.2 Adjust `CustomPaint` child alignment so the needle no longer overlaps the numeric text.
- [x] 4.3 Verify both speedometer and tachometer labels appear lower and are not obscured by the needle.

## 5. Validate and polish

- [x] 5.1 Run the app and verify the speedometer and tachometer updates in live telemetry mode.
- [x] 5.2 Check on mobile and desktop layouts that gauge labels remain readable and tick marks are clear.
- [ ] 5.3 Update any widget tests or add a new test if needed for gauge rendering logic.
