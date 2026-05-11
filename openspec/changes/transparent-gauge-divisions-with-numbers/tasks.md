## 1. Review gauge rendering

- [x] 1.1 Inspect `lib/widgets/telemetry/telemetry_display.dart` to find the gauge painter and division rendering code.
- [x] 1.2 Identify where speedometer and tachometer tick values are defined.

## 2. Update gauge division appearance

- [x] 2.1 Change static gauge divisions to semi-transparent gray.
- [x] 2.2 Preserve the active fill indicator color while dimming non-active segments.

## 3. Add numeric tick labels

- [x] 3.1 Add small numeric labels to the speedometer major ticks: 40, 80, 120, 180, 200, 240, 280, 320.
- [x] 3.2 Add small numeric labels to the tachometer major ticks: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10.
- [x] 3.3 Ensure tick labels are positioned clearly without overlapping the gauge or fill ring.

## 4. Validate the gauge styling

- [ ] 4.1 Run the app and verify the speedometer and tachometer show muted divisions and visible numeric labels.
- [ ] 4.2 Confirm the update works on desktop and mobile layouts.
- [ ] 4.3 Add or update a widget test if needed for the new gauge label rendering.
