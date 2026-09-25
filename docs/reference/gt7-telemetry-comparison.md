# GT7 telemetry UI vs. our telemetry dashboard

Research note, 2026-09-20. All facts below come from primary sources (official
manual / official news post / GTPlanet hands-on); screenshots are in
`docs/reference/gt7/`.

Primary sources:

- GT7 online manual — [The Race Screen](https://www.gran-turismo.com/us/gt7/manual/race/02) (25-element HUD legend),
  [The Multi-Function Display](https://www.gran-turismo.com/us/gt7/manual/race/04),
  [Racing Views](https://www.gran-turismo.com/us/gt7/manual/race/03),
  [What is the Data Logger?](https://www.gran-turismo.com/us/gt7/manual/datalogger/01),
  [Display Settings](https://www.gran-turismo.com/us/gt7/manual/drivingoption/05)
- Polyphony Digital — [Introducing the New Data Logger Feature!](https://www.gran-turismo.com/us/news/00_5736734.html) (12/03/2025, Spec III)
- GTPlanet — [Gran Turismo 7 Spec III's Data Logger Shown in Action](https://www.gtplanet.net/gt7-spec-iii-data-logger-20251110/) (10/11/2025)
- Ancestor of the feature: [GT6 manual — Data Logger](http://www.gran-turismo.com/us/gt6/manual/howtorace/datalogger.html)

## 1. What "telemetry" looks like inside GT7

GT7 has **two** unrelated things, and they look nothing like each other.

### a) Race HUD — real time, drawn over the world

Screenshots: `gt7-race-hud-normal-view.jpg`, `gt7-mfd-session-best.jpg`,
`gt7-mfd-fuel-map.jpg`, `gt7-race-screen-annotated.jpg` (manual legend, 25 elements).

- Bottom-centre **instrument cluster**: two round analog dials — speedometer left,
  tachometer right — with **thin white needles** on a dark translucent panel;
  an E–F fuel sub-gauge, digital odometer and `km/h` label inside the speedo;
  a **thick red redline arc** and a boost sub-gauge inside the tacho.
- Between the dials: digital block `SPEED | GEAR | MT` with a **segmented rev bar**
  above it (segments light up grey → pink/red), and the MFD panel below
  (`Fuel Map` needle gauge + `Remain Laps 7.0` / `Fuel 93%` boxes; other MFD pages:
  TCS, brake balance, track map, radar, weather radar, Session Best table).
- Flanking the cluster: **vertical throttle and brake bars** (throttle white, brake
  white with the ABS-reduced part in red) and a brake-pressure bar.
- Left: car icon with 4 tyres (`RH`/`SS` initials; wear = bar length, heat = frame
  turning red) + driving-assist icons (white = on, grey = off, red = engaged).
- Timing: driver list with flags and ± gaps, lap list, `Session Best` table with
  `LAST` / `BEST` / `OPT.` rows, **blue − / red + deltas**, blinking red "BRAKE"
  suggestion, final-lap banner, total time, track map.
- Colour language: monochrome white/grey chrome; **yellow** = active/selection,
  **blue** = faster than reference, **red** = slower/redline/warning,
  **purple** = fastest lap. No card frames, no titles, no footnotes.

### b) Data Logger — the actual telemetry screen (Spec III, 03/12/2025)

Screenshots: `gt7-data-logger-view1-speed-gap.jpg`,
`gt7-data-logger-view2-throttle-rpm.jpg`,
`gt7-data-logger-view3-speed-rpm-drivingline.jpg`, `gt7-data-logger-hero.jpg`.

Loads lap data from Time Trial / Drift Trial replays (your own, a saved run, a
shared replay, or a top-ranked driver's). Purpose, per Polyphony: compare **two**
data sets, not one.

- **Permanent left column**: Slot A and Slot B cards (tyre type, car thumbnail,
  car name, `Lap 1/1` + lap time), a track map, and a
  **Centripetal Acceleration (G-meter) scatter** (±1.0 / 2.0 rings).
- Slot A is drawn **cyan `#4DC3F3`**, Slot B **yellow `#E7CB3C`** (card border,
  lap bar, trace, readout, G-cloud) — in the traces *and* in every numeric readout
  on the right.
- x-axis = **distance along the lap** (metres: 0 / 500 / 1000 / 2000 / 3000 / 4000;
  miles in the US locale) on a `#4B4B4B` strip; y ranges: speed 0–200/0–300 km/h,
  throttle 0–100 %, rpm 0–10000. A **red vertical rule is the playback head**, a
  magenta rule marks the gap-axis zero (above = leading).
- **View 1 (two-pane)**: top = `Speed and Gap` trace (y = 0–300 km/h,
  x = **distance in metres**: 0 / 500 / 1000 / 1500 marks); bottom = large
  `Driving Line` ribbon with zoom/pan.
- **View 2 (three-pane)**: `Speed and Gap` + `Throttle` (0–100 %) + `RPM`
  (0–10000 rpm) traces; the two laps are stretched onto each other so the cars sit
  at the same track position, which is what makes the comparison readable.
- **View 3 (three-pane)**: `Speed and Gap` + `Speed and RPM` scatter (gear-ratio
  cloud) + `Driving Line` with an on/off toggle.
- Right-hand readout column: current `Speed` (76 / 78 km/h), `Gap` (−0.064 sec.),
  distance (266 m), `Throttle` (12 % / 0), `RPM` (4,052 / 4,187) — one line per
  slot, colour-coded.
- A vertical **playhead + gate/sector marker lines**, a bottom button legend
  (Change View / Play/Pause / Adjust Playback Position / Graph-Map Scale /
  Change Mode / Reset Position), per-trace settings (hamburger) and a
  view switcher on the left edge.
- Chrome: near-black panels, hairline grid, thin traces, small uppercase labels,
  condensed numeric face. Colour is spent only on data meaning.

### Measured palette / typography (sampled from the reference images)

Full details and per-claim provenance tags are in `gt7-ui-spec.md`; the values
needed for design work:

| | GT7 |
|---|---|
| Panel | dark translucent near-black (`~#20242C` @ ~75 % over the scene), 1 px light border, **6–10 px** corner radii, **no shadows**, no light mode |
| Plot / readout surfaces | plot `#1A1C1B`, left column `#2E2E2E`, readout panel `#363A45`, distance strip `#222632` |
| Numerals | squared LED / segment face with hairline inter-digit gaps |
| Labels | neutral humanist sans, small, uppercase |
| Lines | 1 px hairlines and gridlines, 2–3 px traces |
| Semantics | **purple `#8E4DB1`** = best/fastest lap, **blue** = gain / faster, **red** = loss / warning / brake / engaged, **cyan** = slot A, **yellow** = slot B, **green** = fuel-map arc and `BEST` row, **white → red** = tyre wear |
| Dials | speedo 0–280 / 0–320 km/h, ticks every 40, `km/h` printed inside the face, E–F fuel arc + pump icon + digital odometer inside the dial; tacho `x1000rpm` with the **redline band drawn on the scale arc** (extent is car-dependent) and a boost sub-gauge (`x1000 kPa`, −1…+2) |
| Shift lamp | lit = solid `#FA0F0B`; rev tick strip = pink-red `#DB557A` |

⚠️ When re-using the downloaded screenshots: the browser-blue `#3B81E0` circles and
the numbered badges are the **manual's publicity overlay**, not GT7 UI colours —
exclude them from any palette extraction.

## 2. What our screen does today

`lib/widgets/telemetry/telemetry_display.dart` (screen + `GaugeCard` + `_GaugePainter`),
`lib/widgets/telemetry/throttle_brake_graph.dart`,
`lib/blocs/throttle_brake_graph/`, `lib/theme/gt7_theme.dart`.

- Two card-framed gauges: `Speed` (0–540 km/h) and `RPM` (0–9000), 270° arc,
  18 px stroke, thin ticks every 9°, small grey numeric labels, value + unit in the
  middle, footnote under the dial ("Top speed estimate", "Limiter").
- Active value = **filled progress arc** (white for speed, green → yellow → red
  gradient for RPM). `needleColor` is threaded into `_GaugePainter`
  (`telemetry_display.dart:448/459`) but **never painted** — no needle. The
  green/yellow/red `GaugeSection` zones are painted as flat
  `Colors.grey.withOpacity(0.25)`, so redline zones are invisible.
- Stat tiles: `Gear` (+ suggested gear), `Fuel`/`Charge` (+ %), `Lap` (+ best),
  `Position` (+ last).
- "Tire & Vehicle Status": 4 temperature cards (`FL/FR/RL/RR`, °C +
  Cold/Optimal/Warm/Hot) + `Oil Temp`, `Water Temp`, `Brake %` chips.
- `ThrottleBrakeGraph`: **10-second rolling window** (600 points, 60 Hz poll),
  x-axis = time index with **no x labels at all**, y-axis 0/50/100 % with grey
  labels, drawn on a **near-white `#FAFAFA` panel** inside the dark app, throttle
  `#4CAF50` + brake `#F44336` 2 px lines, legend chips, single session, no
  playhead, no second lap.
- Everything lives in rounded Material cards on a dark theme inside a normal
  scrollable page.
- Parsed but not shown (`lib/models/telemetry/telemetry_data.dart`): boost,
  clutch, oil pressure, ride height, per-tyre diameter/speed/slip ratio,
  suspension travel, 8 gear ratios, world position/velocity/rotation, angular
  velocity, G-force inputs.

## 3. Known defects in the current telemetry screen

These are not style differences — they are bugs in our code, independently
verified in `audit-verification.md` (adversarial pass against the sources and the
local Flutter SDK). Fix them before judging fidelity.

| Defect | Reality (corrected) |
|---|---|
| Gauge row on widths ≤ 700 px | `Flex(vertical)` + two `Expanded` inside a scrolling `Column`: in **debug** it throws `RenderFlex children have non-zero flex but incoming height constraints are unbounded`; in **release/profile** the children shrink-wrap instead (`flex.dart` lays flex children out with non-flex constraints). Not a crash on shipped builds, but the phone layout is wrong. |
| Gauge arc overflows its 240 px box | real, `radius = size.width * 0.38` with no height clamp; corrected overflow = `0.38·W − 110.75` px (+14.6 px at W=330, +59.5 at W=448, +143.1 at W=668). "Nothing clips" was wrong: the `SingleChildScrollView` clips `hardEdge`, so the overdraw is cut at the viewport edge, not at the card. |
| `needleColor`, `GaugeSection.color`, `shouldRepaint` | confirmed dead: no needle is ever painted, zone colours are ignored (literal `Colors.grey.withOpacity(0.25)`), the speed ring is a constant white. |
| Tick vs label grid | confirmed mismatched: 31 ticks / 7 majors, major step is **90 km/h**, and **12 of the 15** speed labels fall between ticks (aligned only at 0 / 360 / 540); the label scale is 40 km/h up to 520 plus a final 20 jump to 540. |
| Theme slots | confirmed: `outlineVariant` → `onSurface` at full opacity (brightest hairline on the screen), `surfaceContainerHighest` → `surface` (panels have no fill), `tertiaryContainer` → `secondary` (Lap and Position share an accent). Stat tiles have no fill because they use `colorScheme.surface` directly. |
| Graph | confirmed: realised window is **9.584 s** (600-sample cap binds before the 10 s window), the BLoC re-reads the same `TelemetryData` at 62.5 Hz with no service listener, `_getXPosition` divides by `(total − 1)` (NaN on a single sample), no x labels, `clear` is never dispatched. |
| Data coverage | confirmed: **86 declarations = 76 packet reads + 10 derived**, 23 have a use site, 63 never reach the UI; `formatCurLapTime` has exactly one occurrence (its own definition). |
| — | **Corrected, not a defect:** the `errorMessage` branch is *reachable* — `UdpService.startListening` reports failures via `onError` and returns, and `connectToGT7` sets `isConnected = true` afterwards, so the host page falls through and `TelemetryDisplay` really renders `Error: UDP Error: …`. |
| — | **Corrected, not a defect:** no duplicate poll timer — the tab page is kept alive (`maintainState` defaults true), so `initState` runs once; and even two timers could not double the rate because the 10 ms de-dup admits one event per period. The never-cancelled timer and the unsafe assignment remain real. |
| — | **Corrected:** a brake numeric readout *does* exist (the `Brake` chip); only throttle has none. "No on-screen controls" is true of this screen only — connect/demo controls live in `telemetry_panel.dart` on the Home tab. |

## 4. Similarity verdict

| Element | GT7 | Ours | Match |
|---|---|---|---|
| Round analog dial (speed left / RPM right) | needle + thin ring, red redline arc, translucent panel | progress-ring fill, no needle, grey dead zones, Material card | 45–55 % |
| Digital cluster (speed \| gear \| rev bar) | centre block + segmented rev bar + MFD pages | big number inside each dial, gear in a tile | 30–35 % |
| Fuel | E–F sub-gauge + odometer + `Fuel %` / `Remain Laps` | `Fuel 96/100 · 96 %` tile | 45 % |
| Tyres | 4 tyres, wear bars, heat = reddening frame, type initials | 4 cards, °C + verbal label | 20 % |
| Timing | driver list, lap list, LAST/BEST/OPT, ± deltas blue/red | `Lap` / `Position` tiles with Best/Last | 30 % |
| Throttle/brake | vertical bars in the HUD; overlaid % traces in the Data Logger | 10 s time-window line graph on a white panel | 30–35 % |
| G-force | permanent G-meter pane in the Data Logger (scatter + rings) | parsed in the model, not drawn | 0 % |
| Delta / gap / theoretical best | `Gap −0.064 sec.` + LAST/BEST/OPT | absent | 0 % |
| Distance-based x-axis, sector markers, playhead | core of every Data Logger view | absent (time index, no labels) | 0 % |
| Two-slot comparison (blue vs yellow) | the whole point of the Data Logger | single session only | 0 % |
| Overall screen metaphor | HUD overlay, or a dark analytical instrument | Material card dashboard | ~25–30 % |

**Bottom line.** The dials are the closest thing we have to GT7 (~45–55 %), and even
they diverge exactly where GT7 is distinctive: needle instead of fill, one red
redline instead of a traffic-light ramp, no card chrome around the instrument.
Everything else reads as a generic sim-racing / pit-wall dashboard. Our natural
GT7 counterpart is the **Data Logger**, and against it we match maybe a quarter:
we have the throttle/brake idea, but as a single-session, time-based, white-panel
graph with no comparison, no distance axis, no markers and no readout column.

Weighted over the whole screen, the honest number is **~30 %**: the element
conventions (scale step of 40 km/h, `×1000 rpm` labelling, speed left / tach right,
percentage throttle/brake) are right, the visual system (palette semantics, panel
radii, hairlines, no shadows, segment numerals, distance axis, two-slot comparison)
is not. Measure this again after §3 is fixed — on a phone the screen currently does
not even lay out correctly, and the redline the verifier confirmed is never painted,
so part of the gap is a defect, not a design choice.

Companion documents, all source-cited:

- `gt7-ui-spec.md` — what GT7 actually shows (578 lines, tagged `[MANUAL]` / `[NEWS]` / `[GTP]` / `[OBS]` / `[PX]`, with 13 explicitly unverified items)
- `our-telemetry-ui-spec.md` — our widgets, measured and cited `file:line`
- `audit-verification.md` — adversarial pass on the audit; the corrections in §3 come from here


## 5. Cheapest changes that move the needle

1. **Draw the needle.** `needleColor` already exists in `_GaugePainter` but is
   unused; GT7 = needle + thin ring, not a filled ring.
2. **One red zone only.** Drop `_calculateGaugeRingColor`'s green→yellow→red ramp;
   keep a neutral ring and paint the limiter zone red (as `GaugeSection` intended —
   today those sections are grey).
3. **Strip the card chrome** from the dials (title, top-right unit, footnote,
   20 px radius + shadow) → floating translucent panel with a hairline border,
   unit as tiny text inside the dial; move "Limiter"/"Top speed estimate" into the
   tile strip.
4. **Readable tick numbers**: white ~14 px for 8–9 major divisions instead of grey
   12 px for 11–15 (today they visually disappear; the capture pipeline used for
   `output/deck/screens/telemetry.png` even renders them as solid glyph boxes —
   re-capture after any change).
5. **Restyle `ThrottleBrakeGraph` after the Data Logger**: dark panel, thin traces,
   axis in metres or seconds *with labels*, x gridlines, and a second (reference)
   lap drawn in a second colour instead of semantic green/red — plus a live numeric
   readout for each channel.
6. **Add the two GT7 blocks we have data for but never draw**: a G-meter
   (lateral/longitudinal, from velocity + yaw rate) and a `LAST` / `BEST` / `OPT.`
   row with ± deltas in blue/red.

## 6. HUD proportions and corner radii (measured, 21 Sep)

Measured off the in-game reference screenshot (`/images/c/i1t9kit44OTrcSH.jpg`,
840x473 → normalised to frame width). The game sizes its HUD in fractions of
the frame, not in fixed pixels:

| Metric | GT7 (game) | Ours, before | Ours, now |
|---|---|---|---|
| Instrument cluster width | ~45 % of frame width | ~89 % | **~53 %** (see note) |
| Centre panel : dial width | 1.4 | 0.93 | **1.34** |
| Centre panel aspect (w / h) | 5.6 | 4.1 | **6.1** |
| Centre panel share of frame | 16.2 % | 10.4 % | **15.6 %** |
| Panel shape | 6-vertex hexagon, rounded | 4-vertex trapezoid | **6-vertex hexagon, rounded** |
| Single dial diameter | ~12 % of frame width | ~23 % | **11.3 %** |
| Cluster bottom margin | ~7 % of frame height | ~2 % | **7.7 %** |
| Session-best / timing panel corners | effectively square (1–2 px at 1080p) | 4–8 px | **2 px** |
| Chip / badge corners | square | 3–5 px | **2 px** |
| Centre panel shape | inverted trapezoid, ~0.2 side slope | same | same (kept) |

Implementation: the HUD is laid out at a fixed *design width* (1180 px — the
intrinsic width of the cluster row) and then scaled uniformly with a
`FittedBox` to `0.46 x frameWidth`, anchored `0.07 x frameHeight` above the
bottom. That is how the game behaves: same HUD, any resolution.

Still different, deliberately or not:

- Our cluster carries a status column (oil / water / brake / assist chips) that
  the game only shows inside the MFD, so our cluster is wider per element.
- The tyre widget is proportionally larger than the game's (element 20).
- The game's dials sit tighter against the centre panel; ours keep ~10 px gaps.

Note on the cluster width: ours is ~53 % because the tyre widget and the status column (oil / water / brake / pressure) sit inside the cluster row, while the game keeps the tyres at the bottom-left corner and has no status column in the HUD at all - those numbers live in the MFD. The dial and panel fractions match the game; the band is wider because it carries two extra elements.
