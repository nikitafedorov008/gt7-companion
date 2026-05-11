## Context

The current telemetry display uses bold colored sections for analog gauge dial divisions. This creates visual noise because the same colors also indicate the current value. The requested update is to make the static divisions semi-transparent gray and preserve color only for the active ring fill.

## Goals / Non-Goals

**Goals:**
- Render gauge division segments as semi-transparent gray to reduce visual competition with the active indicator.
- Keep the active speed and RPM value indicator bright and color-driven.
- Add numeric tick labels at key speed and RPM values for better readability.
- Apply the update consistently across both the speedometer and tachometer.

**Non-Goals:**
- Changing telemetry values, data source handling, or app navigation.
- Introducing a new gauge widget framework outside of the existing gauge rendering code.
- Adding new external dependencies.

## Decisions

- **Use existing gauge painter**: Update `lib/widgets/telemetry/telemetry_display.dart` rather than introduce a new gauge component. This keeps the change localized and reuses the current dial layout.
- **Gray inactive divisions**: Render the static tick segments in a semi-transparent gray color. This preserves the dial structure while de-emphasizing non-active areas.
- **Add numeric labels**: Draw small numeric labels near key tick positions for speed and RPM. Use discrete value sets for each gauge so numbers remain legible.
- **Preserve active indicator coloring**: Keep the active fill or ring color logic separate so it remains visually prominent as the primary value cue.

## Risks / Trade-offs

- [Risk] Small numeric labels may overlap or become too dense if placed poorly. → Mitigation: only add labels for key values and place them near major ticks with careful spacing.
- [Risk] Gray divisions may reduce contrast too much on dark themes. → Mitigation: use semi-transparent gray with enough opacity to stay visible while staying muted.
- [Risk] Updating the gauge painter may require additional layout tweaks for both cards. → Mitigation: test on desktop and mobile and keep the logic symmetric for both instruments.

## Migration Plan

1. Update the gauge painter to draw division segments in translucent gray.
2. Add numeric labels for the speedometer and tachometer major ticks.
3. Verify the active value indicator remains the only vibrant colored element.
4. Test the gauges in live telemetry mode and on multiple screen sizes.
