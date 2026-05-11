## 1. Review current gauge rendering

- [x] 1.1 Inspect `lib/widgets/telemetry/telemetry_display.dart` to locate the gauge painter and label layout.
- [x] 1.2 Identify the max values and current value sources used by the speedometer and tachometer.

## 2. Implement circular fill gauge

- [x] 2.1 Update the gauge painter to draw a circular fill ring proportional to the current value.
- [x] 2.2 Remove or de-emphasize the needle so the ring becomes the primary indicator.
- [x] 2.3 Ensure the fill ring animates smoothly as values change.

## 3. Add dynamic color transition

- [x] 3.1 Map the normalized gauge ratio to a green-yellow-red color gradient.
- [x] 3.2 Apply the dynamic color to the fill ring while preserving the underlying gauge sections.
- [x] 3.3 Keep color intensity subtle at low values and stronger at high values.

## 4. Adjust label placement and layout

- [x] 4.1 Move the numeric value and unit labels below the ring center so they do not overlap the fill indicator.
- [x] 4.2 Verify the new layout works for both speedometer and tachometer cards.

## 5. Validate the new gauge behavior

- [ ] 5.1 Run the app and confirm the speedometer and tachometer display the fill ring correctly.
- [ ] 5.2 Check the gauge appearance on both desktop and mobile layouts.
- [ ] 5.3 Update or add a widget test if needed for the new paint behavior.
