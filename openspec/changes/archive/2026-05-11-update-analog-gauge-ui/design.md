## Context

The GT7 companion app currently renders analog speedometer and tachometer widgets where the numeric readouts are positioned over the needle, making them harder to read during live telemetry updates. The tachometer ring also uses a static visual style, so it does not clearly convey RPM intensity or engine stress.

This change is a UI-focused update to the gauge widgets in `lib/widgets/` and possibly the related page or widget tree that hosts them.

## Goals / Non-Goals

**Goals:**
- Make the tachometer ring dynamically change color with RPM, from neutral/transparent at low RPM to red at high RPM.
- Add more tick divisions on analog gauges for improved visual precision.
- Reposition RPM and speed numeric labels below the needle path so they do not overlap the needle.
- Keep the update consistent across tachometer and speedometer widgets.

**Non-Goals:**
- Changing telemetry data sources, network handling, or any backend service logic.
- Introducing new gauge data beyond existing speed and RPM values.
- Reworking app navigation, routing, or non-gauge UI screens.

## Decisions

- **Gauge widget update scope:** Implement changes inside existing gauge rendering widgets rather than creating an entirely new gauge library. This preserves code reuse and stays aligned with the app's widget-based UI layering.
- **Dynamic ring coloring:** Compute a normalized RPM ratio and interpolate a color gradient from the base gauge ring to red. This uses Flutter painting or widget decoration so the visual effect remains performant.
- **Tick density:** Increase tick count on analog gauges by adding additional tick positions around the gauge circumference. Use the same underlying gauge layout but render smaller minor ticks between major ticks.
- **Label placement:** Move numeric readouts downward (or into a dedicated lower band) inside the gauge widget layout. This avoids the needle overlap while maintaining proximity to the gauge.
- **Theme compatibility:** Use theme-aware colors where practical for the gauge ring and tick marks, but preserve the red warning accent as a direct RPM signal.

## Risks / Trade-offs

- [Risk] The gauge widget may require layout or repaint changes that affect performance on lower-end devices. → Mitigation: keep the drawing logic simple and avoid unnecessary rebuilds by using `CustomPainter` or stateless rendering where possible.
- [Risk] Changing label placement may require fine-tuning for different screen sizes or aspect ratios. → Mitigation: use relative positioning and test on both mobile and desktop layout variants.
- [Risk] If the tachometer and speedometer share the same widget, one change may unintentionally alter the other. → Mitigation: encapsulate shared gauge logic while exposing configurable parameters for label placement and ring color behavior.
