## Context

The telemetry display currently renders analog speedometer and tachometer gauges using colored segments and a needle. The requested change is to replace the needle-led presentation with a circular fill ring that behaves like a round loading indicator and changes color based on current speed or RPM.

## Goals / Non-Goals

**Goals:**
- Update the existing analog gauge widgets so the value is shown as a filled circular ring rather than only a needle.
- Use dynamic color interpolation so the ring transitions through green, yellow, and red as the current value increases.
- Keep the change localized to the gauge rendering layer in `lib/widgets/telemetry/telemetry_display.dart`.

**Non-Goals:**
- Changing telemetry sources, network handling, or state management.
- Replacing the entire telemetry dashboard or adding new instrument screens.
- Adding new external dependencies.

## Decisions

- **Shared gauge rendering**: Reuse the existing `GaugeCard` and `_GaugePainter` structure rather than adding a separate new widget type. This keeps implementation focused and avoids duplicating gauge layout logic.
- **Fill ring behavior**: Implement the ring as a circular progress overlay that fills in proportion to the normalized current value. This is more intuitive than a traditional needle and matches the requested loading-indicator style.
- **Dynamic color mapping**: Use a simple green-yellow-red gradient based on the normalized value ratio, with a subtle color overlay on top of the existing gauge sections. This preserves the existing section visual semantics while introducing a value-driven color effect.
- **Label layout preservation**: Keep the numeric value and unit labels below the ring center, ensuring the new ring rendering does not obscure them.

## Risks / Trade-offs

- [Risk] Replacing the needle-style gauge with a fill ring may feel visually different from the current analog instrument. → Mitigation: preserve the circular gauge structure and colored section ranges to retain familiarity.
- [Risk] The new fill overlay may become too intense or hard to read at high values. → Mitigation: cap the overlay opacity and use a smooth interpolation so the ring remains readable.
- [Risk] Gauge rendering complexity may impact repaint performance. → Mitigation: keep the painter logic simple and rely on `CustomPainter` for efficient rendering.

## Migration Plan

1. Update the shared gauge painter to support a value fill ring and color interpolation.
2. Adjust label alignment so values remain readable beneath the ring.
3. Test the gauges in live telemetry mode for both speed and RPM.
4. Verify the appearance on different layouts.

## Open Questions

- Should the dynamic color overlay replace the existing section colors entirely, or should it layer on top of them? The design favors a layered overlay to preserve current gauge ranges.
