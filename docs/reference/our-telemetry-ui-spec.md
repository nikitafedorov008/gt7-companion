# Our telemetry UI — literal, numbers-only inventory

Scope: the **current** telemetry screen of this Flutter app, exactly as written in source. This document is the
"ours" side of a comparison against the in-game telemetry UI of GT7. Every claim carries a `file:line`
citation. Nothing was built or run (sandbox blocks the Flutter cache); this is a source read only, so all
pixel values are the layout values in code, not measured screenshots.

Files audited (all under the repo root):

| File | Role |
| --- | --- |
| `lib/widgets/telemetry/telemetry_display.dart` | `TelemetryDisplay` screen, `GaugeCard`, `_GaugePainter`, `_StatTile`, `_TireStatusBadge`, `_DetailChip` |
| `lib/widgets/telemetry/throttle_brake_graph.dart` | `ThrottleBrakeGraph` + `_ThrottleBrakeGraphPainter` |
| `lib/blocs/throttle_brake_graph/throttle_brake_graph_bloc.dart` | buffer size, sampling, time window |
| `lib/blocs/throttle_brake_graph/throttle_brake_graph_state.dart` | `ThrottleBrakeDataPoint`, state |
| `lib/blocs/throttle_brake_graph/throttle_brake_graph_event.dart` | events (incl. never-dispatched `clear`) |
| `lib/models/telemetry/telemetry_data.dart` | every field parsed from the GT7 UDP packet |
| `lib/theme/gt7_theme.dart` | ColorScheme + textTheme actually used |
| `lib/pages/home_page.dart` | `TelemetryDetailsScreen` host |
| `lib/dependency_injection/app_scope.dart` | where `TelemetryService` / `ThrottleBrakeGraphBloc` are created |
| `lib/services/telemetry_service.dart` | update frequency, demo generator (cited for data-flow facts) |

Only one screen renders telemetry: `TelemetryDetailsScreen` → `TelemetryDisplay`
(`lib/pages/home_page.dart:299-321`, `313-316`). A grep over `lib/` for the parsed field names shows no other
widget consuming `TelemetryData`.

---

## 1. Data flow

### Where the data comes from

1. `AppScope` creates one `TelemetryService` (a `ChangeNotifier`) for the whole app:
   `lib/dependency_injection/app_scope.dart:32`.
   `TelemetryService` owns a `UdpService` (`lib/services/telemetry_service.dart:9`) and decrypts/parses each
   packet into `TelemetryData.fromBytes` (`lib/services/telemetry_service.dart:60,78`).
2. `AppScope` also creates one app-wide `ThrottleBrakeGraphBloc`
   (`lib/dependency_injection/app_scope.dart:82-87`, `dispose: bloc.close()`), constructed with that
   `TelemetryService`.
3. The screen is pushed as tab index 3 of the tab shell
   (`lib/widgets/nested_widget.dart:22`; opened programmatically by
   `lib/widgets/telemetry/telemetry_panel.dart:54,189`; route declared at `lib/router/app_router.dart:43`).
4. `TelemetryDetailsScreen` = `Scaffold(appBar: null)` → `Consumer<TelemetryService>` →
   `TelemetryDisplay(telemetry: service.telemetry, errorMessage: service.errorMessage)`
   (`lib/pages/home_page.dart:304-317`).
   **Gating:** if `!service.isConnected` the whole screen is replaced by
   `Center(child: Text('Not connected to GT7'))` with the default `bodyMedium` style
   (`lib/pages/home_page.dart:309-311`).
5. `TelemetryDisplay` itself builds a second, nested `Scaffold`
   (`lib/widgets/telemetry/telemetry_display.dart:20`) with no app bar, so there is **no title, no back
   button and no control of any kind** on the screen.
6. On desktop the tab shell adds a 72 px top nav bar
   (`lib/widgets/nested_widget.dart:46,52-57`, shown when `width > 800` or on a desktop platform), which is
   the only chrome above the telemetry screen.

### How often it updates

| Path | Cadence | Citation |
| --- | --- | --- |
| Real GT7 UDP | `notifyListeners()` on every accepted packet; accepted only while `packetId` strictly increases | `lib/services/telemetry_service.dart:84,103-105` |
| Demo telemetry (`isDemo`) | `Timer.periodic(500 ms)` → 2 Hz | `lib/services/telemetry_service.dart:153-156,194-195` |
| Graph BLoC sampling | its **own** `Timer.periodic(16 ms)` (~62.5 Hz) that polls `service.telemetry`, independent of packet arrival and of the screen's visibility | `lib/blocs/throttle_brake_graph/throttle_brake_graph_bloc.dart:50-52,61-69` |
| Any change → rebuild | `Consumer<TelemetryService>` rebuilds the **whole** `TelemetryDisplay` subtree per packet; `GaugeCard`'s `TweenAnimationBuilder` is then retargeted | `lib/pages/home_page.dart:307`; `lib/widgets/telemetry/telemetry_display.dart:365-368` |

Because the tree is rebuilt on every packet (`Consumer`), the gauge number animation is restarted
continuously: `TweenAnimationBuilder` keeps `Duration(milliseconds: 600)` + `Curves.easeOutCubic`
(`telemetry_display.dart:365-368`) and on each retarget restarts the 600 ms ease **from the currently
displayed value** (implicit-animation machinery), so the big number is a lagging low-pass of the real value
and only converges if the value stops changing for ≈600 ms. It is rendered with
`toStringAsFixed(0)` (`telemetry_display.dart:392`), so speed shows whole km/h and RPM shows whole rpm.

### What the graph's buffer and time window are

* Ring buffer: `final List<ThrottleBrakeDataPoint> _history = []`
  (`throttle_brake_graph_bloc.dart:18`).
* `static const int maxBufferSize = 600` (`throttle_brake_graph_bloc.dart:24`), comment: "600 points = ~10
  seconds at 60 Hz".
* `static const int timeWindowSeconds = 10` (`throttle_brake_graph_bloc.dart:27`).
* Pruning: everything older than `now - 10 s` is removed
  (`throttle_brake_graph_bloc.dart:123-128`), then the size cap removes the oldest element
  (`throttle_brake_graph_bloc.dart:101-103`).
* De-duplication: an update is dropped if less than 10 ms has passed since the last one
  (`throttle_brake_graph_bloc.dart:81-85`).
* Plotted: only `throttle` and `brake`, each `clamp(0.0, 100.0)`
  (`throttle_brake_graph_bloc.dart:64-67,88-92`), plotted against **sample index**, not time.
* Realised window: with a 16 ms poll, 10 s = 625 samples > 600, so the **size cap binds first** — the buffer
  therefore holds ≈9.6 s, not 10 s, and the two documented limits contradict each other
  (`throttle_brake_graph_bloc.dart:24,27,50,98-103`).
* `ThrottleBrakeGraphEvent.clear` exists (`throttle_brake_graph_event.dart:15`) and is handled
  (`throttle_brake_graph_bloc.dart:39,112-120`) but is **never dispatched anywhere in the app**; the widget
  never calls it, so history can never be reset while running.
* The poll timer is started in `_handleInitialize` and only cancelled in `close()`
  (`throttle_brake_graph_bloc.dart:50-52,131-135`). `initialize()` is dispatched from the widget's
  `initState` (`throttle_brake_graph.dart:25-31`), so re-entering the telemetry tab creates a second
  `Timer.periodic` **without cancelling the first** (no `_pollTimer?.cancel()` in that path) → two timers,
  double sample rate, permanent duplicate polling. The timer also keeps polling the service forever after
  the tab is left, because the BLoC is app-scoped.

---

## 2. Screen shell — `TelemetryDisplay`

`lib/widgets/telemetry/telemetry_display.dart:8-45`

| Item | Value | Line |
| --- | --- | --- |
| Widget | `StatelessWidget`, fields `TelemetryData? telemetry`, `String? errorMessage` | 8-12 |
| Responsive switch | `isDesktop = MediaQuery.of(context).size.width > 700` — **strictly greater**, and based on the full screen width, not the widget's own constraints | 17-18 |
| Root | `Scaffold` → `SafeArea` → `Container(color: theme.colorScheme.surface)` | 20-23 |
| Background colour | `colorScheme.surface` = **`#FF141619`** (theme literal `_gt7Surface`), overriding `scaffoldBackgroundColor` `#FF0B0D0F` outside the SafeArea | 23; theme 5,21,30 |
| Body when `telemetry == null` | `_buildStatusMessage` | 24-25 |
| Body otherwise | `SingleChildScrollView(padding: EdgeInsets.all(16))` → `Column(crossAxisAlignment: start)` | 26-29 |
| Vertical rhythm | `SizedBox(height: 18)` before gauges (31), after gauges (33), after stat row (35), after detail panel (37) — 4 × 18 px | 31,33,35,37 |

### `_buildStatusMessage` (47-64)

| Element | Style | Size | Colour | Line |
| --- | --- | --- | --- | --- |
| `'Error: $errorMessage'` | literal `TextStyle` (not a textTheme style) | 16 | `colorScheme.error` = **`#FFFF5C5C`** | 51-54 |
| `'Waiting for telemetry data...'` | literal `TextStyle` | 16 | `colorScheme.onSurface` = **`#FFE6EEF2`** | 59-62 |

**Dead branch:** the error text is unreachable in practice. `_onError` sets `errorMessage` **and**
`isConnected = false` (`telemetry_service.dart:126-129`), so whenever `errorMessage != null` the host screen
already returned `'Not connected to GT7'` (`home_page.dart:309-311`) and `TelemetryDisplay` is never built with
a non-null error. The `'Waiting for telemetry data...'` branch *is* reachable (connected, no packet yet).

### `_buildGauges` (66-136) — layout

| Item | Value | Line |
| --- | --- | --- |
| Container | `Flex(direction: isDesktop ? horizontal : vertical, crossAxisAlignment: start)` | 71-73 |
| Children | two `Expanded(GaugeCard)` | 75, 107 |
| Separator | desktop `SizedBox(width: 16, height: 0)`; mobile `SizedBox(width: 0, height: 16)` | 106 |
| `isDesktop` is used **only** here | — | 72,106 |

**Broken layout on width ≤ 700 px (all phones):** in the mobile branch the `Flex` is vertical and sits inside
a `Column` inside a `SingleChildScrollView`, i.e. its main-axis height constraint is unbounded; both children
are `Expanded` and `mainAxisSize` defaults to `max`. That trips Flutter's assertion
`RenderFlex children have non-zero flex but incoming height constraints are unbounded`
(`packages/flutter/lib/src/rendering/flex.dart:1035-1053`) → a red-screen/layout error in debug and profile;
in release (asserts off) `canFlex` is false, the flex children are laid out shrink-wrapped, so the `Expanded`
silently does nothing (`flex.dart:1156-1183`). Fix direction: `mainAxisSize: MainAxisSize.min` + `Flexible`,
or a `Column` with plain children on mobile.

### `_buildStatusRow` (138-180)

* `final fuelPercent = telemetry.maxFuel > 0 ? (telemetry.fuel / telemetry.maxFuel).clamp(0.0, 1.0) : 0.0`
  (144-146).
* `Wrap(spacing: 12, runSpacing: 12)` (147-149).
* **Dead parameter:** `bool isDesktop` (141) is never read in the body.
* Four `_StatTile`s (see §4), and each tile is 170 px wide with 12 px gaps → on a 390 px phone only
  **2 tiles per row** (2×170 + 12 = 352), third and fourth wrap; on a wide desktop all four stay left-aligned
  in a 4×170+3×12 = 716 px block with unused space to the right.

### `_buildDetailPanel` (182-238)

| Item | Value | Line |
| --- | --- | --- |
| Container | `width: double.infinity` | 188 |
| Background | `colorScheme.surfaceContainerHighest.withOpacity(0.9)` → that slot is **not defined** in the app's `ColorScheme` (`gt7_theme.dart:13-25`), so Flutter falls back `surfaceContainerHighest → surface` (`color_scheme.dart:1278`) = **`#FF141619` @ 90 %**, i.e. the *same* colour as the screen and the cards — the panel is invisible except for its 1 px border | 189-192 |
| Radius | `BorderRadius.circular(16)` | 193 |
| Border | `Border.all(onSurface.withOpacity(0.08))`, default width 1.0 → `#E6EEF2` @ 8 % ≈ **`#25272A`** composited on `#141619` | 194-196 |
| Padding | `EdgeInsets.all(16)` | 199 |
| Title | `'Tire & Vehicle Status'`, `titleMedium` + `FontWeight.bold` (16 sp, w700, colour `onSurface` @ 0.9 ≈ `#D1D8DC`) | 203-208 |
| Gap | `SizedBox(height: 16)` | 209 |
| Tyre row | `Wrap(spacing: 12, runSpacing: 12)` with 4 `_TireStatusBadge` FL/FR/RL/RR | 210-231 |
| Gap | `SizedBox(height: 20)` | 232 |
| Then | `_buildAuxiliaryRow` | 233 |
| **Dead parameter** | `bool isDesktop` (185) is never read in the body | 185 |

### `_buildAuxiliaryRow` (240-281)

* `LayoutBuilder` → `isWide = constraints.maxWidth > 600` (241-243) — a **second, different breakpoint** from
  the screen's 700 px, measured against the panel's inner width.
* `Flex(direction: isWide ? horizontal : vertical, crossAxisAlignment: start)` (244-247), children
  `Expanded(_DetailChip)` ×3 with `SizedBox(width: 12 / height: 12)` separators (248-277). These are inside a
  `Column` in a scroll view too, so in the narrow case the same unbounded-vertical-Flex/`Expanded` pattern
  appears (same assertion risk in debug).
* The three chips: `Oil Temp`, `Water Temp`, `Brake` (see §5).

### `_buildThrottleBrakeGraph` host container (289-299)

| Item | Value | Line |
| --- | --- | --- |
| Background | `colorScheme.surface` = **`#FF141619`** | 293 |
| Radius | 16 | 294 |
| Border | `Border.all(color: colorScheme.outlineVariant, width: 1)` → `outlineVariant` is not defined either, so it falls back to `onBackground` → `onSurface` (`color_scheme.dart:1299,1360`) = **`#FFE6EEF2` at full opacity** — a bright white hairline, by far the brightest border on an otherwise 4-8 % hairline screen | 295 |
| Child | `const ThrottleBrakeGraph(height: 200)` | 297 |

---

## 3. `GaugeCard` — `telemetry_display.dart:302-424`

Instances: Speed (76-104) and RPM (108-132).

| Property | Speed card | RPM card | Line |
| --- | --- | --- | --- |
| `label` | `'Speed'` | `'RPM'` | 77 / 109 |
| `value` | `telemetry.speed.clamp(0, 540)` | `telemetry.rpm.clamp(0, 9000)` | 78 / 110 |
| `maxValue` | `540` (literal) | `9000` (literal) | 79 / 111 |
| `units` | `'km/h'` | `'rpm'` | 80 / 112 |
| `sections` | `(0,180,#FF4CAF50) (180,360,#FFFFC107) (360,540,#FFF44336)` | `(0,4500,#FF4CAF50) (4500,7000,#FFFFC107) (7000,9000,#FFF44336)` | 81-85 / 113-117 |
| `tickLabels` | 15 labels `'0'…'540'` step 40, `ratio: v/540` | 11 labels `'0'…'10'`, `ratio: 0.0,0.1,…,1.0` | 86-102 / 118-130 |
| `footnote` | `'Top speed estimate: ${telemetry.estTopSpeed} km/h'` | `'Limiter: ${telemetry.rpmLimiter} rpm'` | 103 / 131 |

### Card geometry

| Item | Value | Line |
| --- | --- | --- |
| Outer `margin` | `EdgeInsets.only(bottom: 16)` — applied to **both** cards; in the desktop horizontal row it becomes 16 px of dead space under both | 326 |
| `padding` | `EdgeInsets.all(14)` | 327 |
| Background | `colorScheme.surface` = **`#FF141619`** — identical to the screen background, so the card is visually only a border | 329 |
| Radius | `BorderRadius.circular(20)` | 330 |
| Border | `onSurface.withOpacity(0.08)`, width 1 → ≈`#25272A` | 331-333 |
| Shadow | `Colors.black.withOpacity(0.06)`, `blurRadius: 18`, `offset: (0, 10)` — 6 % black over a near-black surface is effectively invisible | 334-340 |
| Header row | `Row(Expanded(Text(label)), Text(units))` | 344-361 |
| Gap | 16 | 362 |
| Gauge box | `SizedBox(height: 240)` | 363-364 |
| Gap | 16 | 411 |
| Footnote | `maxLines: 2`, `TextOverflow.ellipsis` | 412-419 |

### `isSpeedometer` and the ring colour

`isSpeedometer: label.toLowerCase() == 'speed'` (`378`) — a string comparison of the display label, so
renaming the label silently changes geometry and colour logic.

* `backgroundColor` = `onSurface.withOpacity(0.08)` ≈ `#25272A` (377-379) — the arc track.
* `needleColor` = `colorScheme.primary` = **`#FF00D1E8`** (380) — **passed and stored but never read in
  `paint()`**: there is no needle (see §11).
* `tickColor` = `onSurface.withOpacity(0.55)` ≈ `#888D90` (381).
* `dynamicRingColor` (382-384):
  * Speed → `Colors.white.withOpacity(0.5)` = **`#FFFFFF` @ 50 %** (≈`#8A8B8C` over the surface) — a
    constant, so the speed gauge's ring is always plain white and never colour-coded;
  * RPM (and any other label) → `_calculateGaugeRingColor(animatedValue, maxValue)` (572-587).
* `TweenAnimationBuilder`: `Tween(begin: 0, end: value)`, 600 ms, `Curves.easeOutCubic` (365-368).
* Big number: `animatedValue.toStringAsFixed(0)`, `headlineMedium` + bold → **28 sp, w700**, colour =
  `onSurface` **`#FFE6EEF2` at full opacity**, because the app's `textTheme` (theme 72-90) never overrides
  `headlineMedium` — it keeps the Material default, which for a dark ColorScheme is `colorScheme.onSurface`
  (`typography.dart:197-206`). Contrast with every other label on this screen, which is `onSurface` at
  65-90 % opacity. Placed by `Align(alignment: Alignment(0, 0.6))` → 60 % between top and bottom of the
  240 px box, i.e. in the lower part, inside the bottom gap of the arc (386-387).
* Units under the number: `bodySmall` (12 sp) `onSurface` @ 0.7 (≈`#A7ADB1`) — so the unit appears **twice**
  per card (header right, 356-358, and under the number, 398-403).
* Footnote: `bodySmall` (12 sp) `onSurface` @ 0.74 (≈`#AFB6BA`) (416-418).

---

## 4. `_GaugePainter` — `telemetry_display.dart:441-570`

Fields (442-450) / constructor (452-462):
`currentValue`, `maxValue`, `sections`, `tickLabels`, `isSpeedometer`, `backgroundColor`, `needleColor`,
`tickColor`, `dynamicRingColor`.

`paint()` (465-561):

| Geometry | Value | Line |
| --- | --- | --- |
| Centre | `size.center(Offset.zero)` (box = card content width × 240 px) | 466 |
| Radius | `size.width * 0.38` — width-derived only, **no height clamp** | 467 |
| Stroke width | `18.0` | 468 |
| Arc start | `math.pi * 0.75` = **135°** (0.75 π) | 469 |
| Arc sweep | `math.pi * 1.5` = **270°**, ending at 405° ≡ 45° → gap at the bottom | 470 |
| Base arc | full 270°, `backgroundColor`, `StrokeCap.round`, stroke style | 472-484 |
| Zone arcs | for each `GaugeSection`: `start = (section.start / maxValue) * sweepAngle`, `sweep = ((end-start)/maxValue) * sweepAngle` | 487-489 |
| Zone paint colour | **`Colors.grey.withOpacity(0.25)`** — hard-coded, `section.color` is ignored | 490-494 |
| Fill overlay | drawn only when `fillRatio = (currentValue/maxValue).clamp(0,1) > 0`; sweep = `270° × fillRatio`; colour = `dynamicRingColor`; `StrokeCap.round` | 504-517 |
| Ticks | `const tickCount = 30` → **31 ticks** (`tick <= 30`); `isMajor = tick % 5 == 0` → **7 major** | 520-523 |
| Tick length | major `14.0`, minor `8.0` | 524 |
| Tick radial extent | inner start at `radius - tickLength - 4`, outer end at `radius + 8` | 525-532 |
| Tick width | major `2.5`, minor `1.2`, `StrokeCap.round`, colour `tickColor` | 538-539 |
| Label angle | `startAngle + sweepAngle * ratio.clamp(0,1)` | 544 |
| Label radius | `radius - (isSpeedometer ? 34 : 22)` — a 12 px difference keyed only off the label string, and not tied to the tick lengths | 545 |
| Label text | `const TextStyle(color: Colors.grey = **#FF9E9E9E**, fontSize: 12)` — hard-coded, not from the theme | 550-556 |
| Label position | point minus (width/2, height/2) | 557-558 |

### Dead / unrendered inside the painter

1. **`needleColor` is never used** (field 448, ctor 459, passed 380). There is no needle, no pointer, no
   centre hub — only the arc fill.
2. **`GaugeSection.color` is never used** (490-494). All three zones of both gauges are painted the same
   `grey @ 25 %` (≈`#37373A`), and because the zones together span the whole 0…max range they repaint the
   whole track slightly lighter. **The intended green/amber/red zones are invisible**, so the speed gauge has
   no "high speed" colour band and the RPM gauge has **no redline zone at all**, even though the literal
   values are supplied at 82-84 and 114-116.
3. `shouldRepaint` (564-569) compares only `currentValue`, `maxValue`, `dynamicRingColor`, `isSpeedometer` —
   `sections`, `tickLabels`, `backgroundColor` and `tickColor` are **not** compared, so a change in any of
   them would not repaint. (`GaugeSection`/`GaugeLabel`, 426-439, have no `==`/`hashCode` either, so list
   comparison could not work anyway.)
4. `_calculateGaugeRingColor` (572-587) is called **only** for the non-speed gauge, so its whole
   colour-ramp behaviour applies to RPM alone; the `ratio <= 0 → Colors.transparent` branch (574-576) is
   already guarded by the caller's `fillRatio > 0` check — unreachable.
5. The tick grid does not align with the printed numbers. Ticks sit at `k/30` of the sweep; the speed labels
   sit at `v/540`. A label lands on a tick only when `20m/9` is an integer for `v = 40m`, i.e. **only at
   0 and 360** (plus the hand-added final label 540 = tick 30): 14 of the 15 speed labels sit between ticks,
   and the 7 major ticks (every 5th tick ≈ every 45 km/h) match a printed number only at 0, 360 and 540. For
   RPM every label coincides with *some* tick (`k = 3m`) but only the 0, 5 and 10 labels land on **major**
   ticks. So the printed speed scale (every 40 km/h) is not the scale the ticks imply.
6. RPM labels read `'0'…'10'` (ratios 0.0…1.0) against a `maxValue` of 9000 — the labels are implicitly
   "thousands of rpm" and are unrelated to `maxValue`; the speed labels are absolute (`v/540`). Two different
   labelling conventions inside one widget.
7. The arc **paints outside its 240 px box** on any realistic width. With card content width `W`, the box is
   `W × 240`, centre y = 120, radius = `0.38·W`; the topmost paint (arc stroke + tick tip) reaches
   `120 − 0.38·W − 17`, so the vertical overflow above the box is `0.38·W − 103` px:
   * phone (W ≈ 330, 390 px device) → ≈ **+22 px** (ticks cross into the units row);
   * 1000 px window (W ≈ 448) → ≈ **+67 px**;
   * 1440 px window (W ≈ 668) → ≈ **+151 px** (arc and labels drawn far above the card, over the screen's
     content), and the lower ends at 45°/135° reach `y = 120 + 0.707·radius` ≈ 325 → ≈85 px *below* the box,
     over the footnote. `CustomPaint` does not clip and no ancestor sets `clipBehavior`, so this is real
     overdraw, not a rounding effect. Fix direction: `radius = min(size.width*0.38, size.height/2 - 20)`.

---

## 5. `_StatTile` (589-643) and the four tiles

| Item | Value | Line |
| --- | --- | --- |
| Fixed width | `width: 170` (never stretches on wide screens) | 606 |
| Padding | `EdgeInsets.all(14)` | 607 |
| Background | `colorScheme.surface` = **`#FF141619`** = screen colour → invisible | 609 |
| Radius | 16 | 610 |
| Border | `onSurface.withOpacity(0.06)`, width 1 → ≈`#212326` (the faintest hairline on the screen) | 611-613 |
| Title | `bodySmall` (12 sp), `onSurface` @ 0.75 (≈`#B2B8BC`) — redundant, the theme's `bodySmall` is *already* `onSurface` @ 0.75 (theme 89) | 618-623 |
| Gap | 8 | 624 |
| Value | `titleLarge` (**22 sp**) + bold → w700, colour = `accent` argument (opaque) | 625-631 |
| Gap | 6 | 632 |
| Subtitle | `bodySmall` (12 sp), `onSurface` @ 0.68 (≈`#A3A9AD`) | 633-638 |

Tiles (151-177):

| Tile | Title | Value | Accent (source) | Subtitle |
| --- | --- | --- | --- | --- |
| 1 | `'Gear'` | `_formatGear(currentGear)` → `'R'`/`'N'`/number (283-287) | `colorScheme.primary` = **`#FF00D1E8`** (theme 6) | `'Suggested: ${_formatGear(suggestedGear)}'` |
| 2 | `isEV ? 'Charge' : 'Fuel'` | `'${fuel.toStringAsFixed(0)} / ${maxFuel.toStringAsFixed(0)}'` (no unit) | `#FF4CAF50` if `fuelPercent > 0.4` else `#FFFFC107` (both **literals**) | `'${(fuelPercent*100).toStringAsFixed(0)}%'` |
| 3 | `'Lap'` | `'${currentLap}/${totalLaps}'` | `colorScheme.secondary` = **`#FFC857`** (theme 9) | `'Best: ${formatLapTime(bestLapTime)}'` |
| 4 | `'Position'` | `'${currentPos}/${totalPositions}'` | `colorScheme.tertiaryContainer` → **`#FFC857`** (see below) | `'Last: ${formatLapTime(lastLapTime)}'` |

Problems in this row:

* `colorScheme.tertiaryContainer` is not set in the app's `ColorScheme` (`gt7_theme.dart:13-25` defines only
  brightness, primary, onPrimary, primaryContainer, onPrimaryContainer, secondary, onSecondary, surface,
  onSurface, error, onError). Flutter resolves `tertiaryContainer → tertiary → secondary`
  (`color_scheme.dart:1153,1168`), so tiles 3 and 4 render the **identical** `#FFC857` accent — the
  "different accent per tile" intent is defeated, and the Position value is indistinguishable in colour from
  the Lap value.
* Fuel tile: when `maxFuel == 0` (i.e. `isEV == true`, `telemetry_data.dart:241`) `fuelPercent` is forced to
  `0.0` (144-146), so the accent is **always amber** and the subtitle is **always `0%`**; the value then reads
  e.g. `0 / 0`. Fully deterministic and useless for EVs.
* The subtitle of tile 4 (`Position`) is a **lap time** (`Last:`), and the "Last lap" is grouped with
  position while "Best lap" is grouped with lap count — inconsistent grouping.
* `formatLapTime` returns `''` for values `<= 0` (`telemetry_data.dart:300-301`), so before the first lap the
  subtitles render as `'Best: '` / `'Last: '` with an empty tail.
* The `%` in the fuel subtitle is `fuel/maxFuel` (fuel load fraction). GT7 fuel is a capacity-limited float
  (`0x44`/`0x48`, `telemetry_data.dart:239-240`) and **no unit is printed** for the raw value.

---

## 6. `_TireStatusBadge` (645-704) and `_DetailChip` (706-745)

### `_TireStatusBadge`

| Item | Value | Line |
| --- | --- | --- |
| Fixed width | 130 | 655 |
| Padding | `EdgeInsets.symmetric(vertical: 14, horizontal: 12)` | 656 |
| Background | `color.withOpacity(0.14)` | 658 |
| Radius | 14 | 659 |
| Border | `color.withOpacity(0.25)`, width 1 | 660 |
| Label (`FL`/`FR`/`RL`/`RR`) | `bodyMedium` (**14 sp**) + bold → w700; colour from theme `bodyMedium` = `onSurface` @ 0.9 ≈ `#D1D8DC` | 665-670 |
| Gap / temperature / gap | 6 / `'${temperature.toStringAsFixed(1)} °C'` `titleMedium` (16 sp) w700 + the temperature colour at **full opacity** / 4 | 671-678 |
| State text | `bodySmall` (12 sp) `onSurface` @ 0.75 (≈`#B2B8BC`), values `'Cold'`/`'Optimal'`/`'Warm'`/`'Hot'` | 680-685, 698-703 |

Colour/label thresholds are **duplicated literals** in two functions (`_temperatureColor` 691-696 and
`_temperatureLabel` 698-703) with the same cut-offs `80 / 110 / 130 °C`:

| Temp | Colour (hex, literal) | State |
| --- | --- | --- |
| `< 80` | **`#FF42A5F5`** (Material blue 400 — the only blue in the whole UI) | `Cold` |
| `< 110` | **`#FF66BB6A`** (Material green 400) | `Optimal` |
| `< 130` | **`#FFFFC107`** (amber 500) | `Warm` |
| `≥ 130` | **`#FFF44336`** (red 500) | `Hot` |

Four badges × 130 px + 3 × 12 px gaps = 556 px of intrinsic width, so on a 390 px phone they always wrap to
2 + 2 rows. Only the four tyre **temperatures** are shown: no wear, no pressure, no compound, no per-zone
temperature, no slip. (In demo mode the generated temps are `67 + speed/320·27` … `69 + speed/320·25`
(`telemetry_service.dart:227-230`), i.e. ≤ ≈96 °C, so the demo **never** leaves `Cold`/`Optimal`.)

### `_DetailChip` (three chips: Oil Temp, Water Temp, Brake)

| Item | Value | Line |
| --- | --- | --- |
| Padding | `EdgeInsets.all(14)` | 720 |
| Background | `color.withOpacity(0.12)` | 722 |
| Radius | 14 | 723 |
| Border | **none** — inconsistent with `_TireStatusBadge`, which has a `0.25`-alpha border at the same radius | 719-724 |
| Label | `bodySmall` (12 sp) `onSurface` @ 0.75 (≈`#B2B8BC`) — again redundant with the theme | 728-733 |
| Gap | 8 | 734 |
| Value | `bodyLarge` (**16 sp**) + bold → w700, colour = the passed colour, opaque | 735-741 |

| Chip | Value string | Colour rule (literals) | Source field |
| --- | --- | --- | --- |
| `Oil Temp` | `'${oilTemp.toStringAsFixed(1)} °C'` | `oilTemp > 110 ? **#FFF44336** : **#FF4CAF50**` | `telemetry_data.dart:160` (`0x5C`) |
| `Water Temp` | `'${waterTemp.toStringAsFixed(1)} °C'` | `waterTemp > 100 ? **#FFF44336** : **#FF4CAF50**` | `telemetry_data.dart:161` (`0x58`) |
| `Brake` | `'${brake.toStringAsFixed(0)}%'` | `brake > 80 ? **#FFF44336** : **#FF4CAF50**` | `telemetry_data.dart:136` (`0x92 / 2.55`) |

The `Brake` chip is the **only** brake readout besides the graph: a single instantaneous number, no bar, no
history, no per-wheel split, and no throttle counterpart anywhere on the screen (throttle exists only as a
graph line). The label reads `Brake` while the source is brake **pedal position** (`0x92`), not brake
pressure.

---

## 7. Throttle/brake graph

### `ThrottleBrakeGraph` — `throttle_brake_graph.dart:11-87`

| Item | Value | Line |
| --- | --- | --- |
| Widget | `StatefulWidget`, `final double height` with default `200.0` | 11-21 |
| `initState` | `context.read<ThrottleBrakeGraphBloc>().add(const ThrottleBrakeGraphEvent.initialize())` | 25-31 |
| Build | `BlocBuilder` → `Container(height: widget.height, padding: EdgeInsets.all(8.0))` | 35-39 |
| `initial` | `_LoadingPlaceholder` | 41 |
| `loading` | `_LoadingPlaceholder` (**the same widget**, so "initial" and "loading" are visually identical) | 42 |
| `success` + empty history | `_NoDataPlaceholder` | 44-46 |
| `error` | `_ErrorPlaceholder(message)` | 49 |
| Graph content | `Column(crossAxisAlignment: start)` | 57-59 |
| Legend | `Padding(bottom: 8.0)` → throttle swatch then 16 px then brake swatch | 61-76 |
| Canvas | `Expanded(CustomPaint(painter: _ThrottleBrakeGraphPainter(history), size: Size.infinite))` | 78-83 |

Legend (`_ColorLegend` 248-275): swatch `Container(width: 16, height: 2, color: color)` (262-266), 6 px gap,
label `Theme.of(context).textTheme.bodySmall` → 12 sp, `onSurface` @ 0.75 (≈`#B2B8BC`) (268-271). Legend
colours are hard-coded **duplicates** of the painter constants: `#FF4CAF50` "Throttle" (66) and `#FFF44336`
"Brake" (71).

Placeholders: `_LoadingPlaceholder` = `CircularProgressIndicator(strokeWidth: 2)` in a 24×24 box (283-289);
`_NoDataPlaceholder` = `'Waiting for telemetry data...'` `bodyMedium` (14 sp) with `Colors.grey`
(`#FF9E9E9E`) (299-305); `_ErrorPlaceholder` = `'Error: $message'` `bodyMedium` with `Colors.red`
(`#FFF44336`), centred (317-325).

### `_ThrottleBrakeGraphPainter` — 90-245

| Geometry / colour | Value | Line |
| --- | --- | --- |
| `throttleColor` | **`#FF4CAF50`** (comment: "Green") | 94 |
| `brakeColor` | **`#FFF44336`** (comment: "Red") | 95 |
| Early out | returns if `history.isEmpty` | 101-103 |
| Background | `drawRect(0,0,w,h)`, `const Color(0xFFFAFAFA)` — **near-white**, on a dark UI | 106-109 |
| Axis/grid paint | `const Color(0xFFBDBDBD)`, `strokeWidth: 0.5` | 135-137 |
| Y labels / values | `['100%','50%','0%']` for `[100,50,0]` | 144-145 |
| Left padding literal | `40.0` (repeated in `_drawLine`) | 147, 197 |
| Grid line | from `(40, y)` to `(width-10, y)` | 153-157 |
| Y label text | `const TextStyle(color: **#FF757575**, fontSize: 12)` drawn at `(5, y-8)` | 162-168 |
| X axis | line from `(40, height-20)` to `(width-10, height-20)` | 172-176 |
| Y axis | line from `(40, 0)` to `(40, height-20)` | 179-183 |
| Line stroke | `strokeWidth: 2.0` for both series, `PaintingStyle.stroke`, `StrokeCap.round`, `StrokeJoin.round` | 120,129,210-218 |
| X mapping | `graphWidth = size.width - 40 - 10`; `x = 40 + graphWidth * index / (total - 1)` — **`total == 1` divides by zero** → `NaN` coordinates on the very first sample (the painter is entered with a 1-element history) | 222-230 |
| Y mapping | `graphHeight = size.height - 30`; `y = size.height - 20 - graphHeight * (value / 100)` → 0 % sits on the x axis, 100 % at `y = 10`, so the plot area starts 10 px below the canvas top and the 40 px "padding" is horizontal only | 233-236 |
| `shouldRepaint` | only `history.length` or `history.last` changes → repaints on **every** sample emission (≈62.5 Hz), redrawing the whole path each time | 239-244 |

What is absent inside the graph: **no X-axis labels or ticks of any kind** (no time axis, no "10 s" marker),
no title, no current-value readout, no cursor, no second/reference lap, no fill under the curves, no
smoothing or down-sampling (every buffered sample is a vertex, so vertex density depends on buffer length),
and both series are drawn on the same axis with the brake line drawn second so it overdraws throttle where
they coincide.

---

## 8. Theme audit — `lib/theme/gt7_theme.dart`

### `ColorScheme` actually used (13-25)

| Slot | Hex | Line |
| --- | --- | --- |
| `brightness` | `Brightness.dark` | 14 |
| `primary` | **`#FF00D1E8`** cyan | 6,15 |
| `onPrimary` | **`#FF0B0D0F`** | 16 |
| `primaryContainer` | **`#FF07282B`** | 7,17 |
| `onPrimaryContainer` | **`#FF6BE3FF`** | 8,18 |
| `secondary` | **`#FFFFC857`** | 9,19 |
| `onSecondary` | **`#FF141619`** | 20 |
| `surface` | **`#FF141619`** | 5,21 |
| `onSurface` | **`#FFE6EEF2`** | 22 |
| `error` | **`#FFFF5C5C`** | 11,23 |
| `onError` | `Colors.white` = **`#FFFFFFFF`** | 24 |

Everything else that this UI reads is **undefined** and resolved by Flutter's fallbacks:

| Read at | Falls back to | Value | Reference |
| --- | --- | --- | --- |
| `tertiaryContainer` (telemetry_display.dart:175) | `tertiary` → `secondary` | **`#FFFFC857`** | `color_scheme.dart:1153,1168` |
| `surfaceContainerHighest` (telemetry_display.dart:192) | `surface` | **`#FF141619`** | `color_scheme.dart:1278` |
| `outlineVariant` (telemetry_display.dart:295) | `onBackground` → `onSurface` | **`#FFE6EEF2`** (full opacity) | `color_scheme.dart:1299,1360` |

Also relevant: the theme sets `scaffoldBackgroundColor: #FF0B0D0F` (30) and `cardColor: #FF141619` (70), and
the app passes a single `theme:` with no `darkTheme`/`themeMode` (`lib/app.dart:19`).

### `textTheme` overrides actually used (72-90)

| Style | Colour set by theme | Size/weight from Material 2021 defaults |
| --- | --- | --- |
| `headlineSmall` | `onSurface` (1.0) | 24 sp, w400 |
| `titleLarge` | `onSurface` (**and w700**) | 22 sp, w400→w700 |
| `titleMedium` | `onSurface` @ 0.9 (≈`#D1D8DC`) | 16 sp, w500, ls 0.15 |
| `bodyLarge` | `onSurface` (1.0) | 16 sp, w400, ls 0.5 |
| `bodyMedium` | `onSurface` @ 0.9 (≈`#D1D8DC`) | 14 sp, w400, ls 0.25 |
| `bodySmall` | `onSurface` @ 0.75 (≈`#B2B8BC`) | 12 sp, w400, ls 0.4 |
| `headlineMedium` | **not overridden** → Material default = `onSurface` `#FFE6EEF2` (1.0) | 28 sp, w400 |

`labelMedium` (12 sp) and `labelSmall` (11 sp) are used by `telemetry_panel.dart:82,275`, not by the
telemetry screen's display widgets.

### Typography of every label on the telemetry screen

| Element | Style | Size | Final weight | Colour (opacity) | Line |
| --- | --- | --- | --- | --- | --- |
| Gauge card label (Speed/RPM) | `titleMedium` + bold | 16 | w700 | `#E6EEF2` @ 0.9 ≈ `#D1D8DC` | 349-351 |
| Gauge card unit (top-right) | `bodySmall` | 12 | w400 | `#E6EEF2` @ 0.65 ≈ `#9DA2A6` | 356-358 |
| Gauge big number | `headlineMedium` + bold | 28 | w700 | `#E6EEF2` @ **1.0** | 393-395 |
| Gauge unit under number | `bodySmall` | 12 | w400 | `#E6EEF2` @ 0.7 ≈ `#A7ADB1` | 400-402 |
| Gauge footnote | `bodySmall` | 12 | w400 | `#E6EEF2` @ 0.74 ≈ `#AFB6BA` | 416-418 |
| Gauge tick labels (canvas) | literal `TextStyle` | 12 | default | `Colors.grey` `#9E9E9E` @ 1.0 | 553 |
| Stat tile title | `bodySmall` | 12 | w400 | `#E6EEF2` @ 0.75 ≈ `#B2B8BC` | 620-622 |
| Stat tile value | `titleLarge` + bold | 22 | w700 | accent (opaque) | 627-630 |
| Stat tile subtitle | `bodySmall` | 12 | w400 | `#E6EEF2` @ 0.68 ≈ `#A3A9AD` | 635-637 |
| Panel title | `titleMedium` + bold | 16 | w700 | `#E6EEF2` @ 0.9 ≈ `#D1D8DC` | 205-207 |
| Tyre badge label | `bodyMedium` + bold | 14 | w700 | `#E6EEF2` @ 0.9 ≈ `#D1D8DC` | 667-669 |
| Tyre temperature | `titleMedium` + bold | 16 | w700 | temperature colour @ 1.0 | 674-677 |
| Tyre state | `bodySmall` | 12 | w400 | `#E6EEF2` @ 0.75 | 682-684 |
| Chip label | `bodySmall` | 12 | w400 | `#E6EEF2` @ 0.75 | 730-732 |
| Chip value | `bodyLarge` + bold | 16 | w700 | chip colour @ 1.0 | 737-740 |
| Graph legend label | `bodySmall` | 12 | w400 | `#E6EEF2` @ 0.75 | 270 |
| Graph Y labels (canvas) | literal `TextStyle` | 12 | default | `#757575` @ 1.0 | 162-165 |
| Graph no-data | `bodyMedium` | 14 | w400 | `Colors.grey` `#9E9E9E` | 302-304 |
| Graph error | `bodyMedium` | 14 | w400 | `Colors.red` `#F44336` | 321-323 |
| `'Not connected to GT7'` | default `bodyMedium` | 14 | w400 | `#E6EEF2` @ 0.9 | home_page 310 |
| `'Error: …'` (unreachable) | literal `TextStyle` | 16 | default | `#FF5C5C` | 53 |
| `'Waiting for telemetry data...'` | literal `TextStyle` | 16 | default | `#E6EEF2` @ 1.0 | 61 |

Note the opacity zoo: one colour (`#E6EEF2`) is used at ten different alpha/opacity values
(0.06, 0.08, 0.55, 0.65, 0.68, 0.7, 0.74, 0.75, 0.9, 1.0) with no consistent rule, and the two status texts
use raw `TextStyle(fontSize: 16)` instead of the text theme.

---

## 9. Hard-coded colour appendix (every literal, source-tagged)

Theme-derived (see §8 for resolution): `#141619` surface, `#E6EEF2` onSurface (+ opacities), `#00D1E8`
primary, `#FFC857` secondary, `#FFC857` tertiaryContainer-fallback, `#FF5C5C` error, `#E6EEF2` outlineVariant.

Literals in the telemetry widgets:

| Hex | Where | Line |
| --- | --- | --- |
| `#4CAF50` | speed zone 0-180, RPM zone 0-4500 (**painted grey — ignored**), fuel accent >40 %, oil/water/brake "ok", tyre `Optimal`, `Colors.green` in the RPM ring lerp, graph throttle line + legend | 82,114,162,254,264,274,693,579,94,66 |
| `#FFC107` | speed zone 180-360, RPM zone 4500-7000 (ignored), fuel accent ≤40 %, tyre `Warm` | 83,115,163,694 |
| `#F44336` | speed zone 360-540, RPM zone 7000-9000 (ignored), oil >110, water >100, brake >80, tyre `Hot`, `Colors.red` in the ring lerp, graph brake line + legend, graph error text | 84,116,253,263,273,695,586,95,71,323 |
| `#42A5F5` | tyre `Cold` (the only blue) | 692 |
| `#66BB6A` | tyre `Optimal` | 693 |
| `#FFFFFF` @ 0.5 | speed gauge ring (`Colors.white`) | 383 |
| `#FFFFEB3B` (`Colors.yellow`) | RPM ring lerp midpoint @ 0.7 opacity; ramp opacity 0.7 / 0.85 | 579,586 |
| `#9E9E9E` (`Colors.grey`) @ 0.25 | **all** gauge zone bands | 491 |
| `#9E9E9E` (`Colors.grey`) @ 1.0 | gauge tick labels | 553 |
| `#9E9E9E` (`Colors.grey`) | graph no-data text | 303 |
| `#000000` @ 0.06 | gauge card shadow | 335 |
| `#FAFAFA` | graph background (near-white) | 108 |
| `#BDBDBD` @ 0.5 px | graph axes/grid | 136 |
| `#757575` | graph Y-axis labels | 163 |

---

## 10. Dead, inconsistent, or always-the-same code (consolidated)

| # | Finding | Citation |
| --- | --- | --- |
| 1 | **Mobile layout error:** vertical `Flex` + `Expanded` + `mainAxisSize.max` inside a scroll view → `RenderFlex children have non-zero flex but incoming height constraints are unbounded` (debug/profile), silent shrink-wrap in release | 66-73, 75, 107; `flex.dart:1045-1053` |
| 2 | `_GaugePainter.needleColor` computed, passed, stored, **never drawn** — no needle exists | 380, 448, 459 |
| 3 | `GaugeSection.color` never used → all gauge zones painted `grey @ 25 %`; the three zone colours are dead data and **no redline zone is visible** | 490-494, 82-84, 114-116 |
| 4 | Speed gauge ring is a constant `Colors.white @ 50 %` — the green→yellow→red ramp applies only to RPM, and white is not in the theme | 382-383, 572-587 |
| 5 | `shouldRepaint` ignores `sections`, `tickLabels`, `backgroundColor`, `tickColor` | 564-569 |
| 6 | `_calculateGaugeRingColor`'s `ratio <= 0 → transparent` branch is unreachable (caller guards) | 574-576 vs 505 |
| 7 | Gauge radius = `width * 0.38` with no height clamp → arc/ticks/labels paint outside the 240 px box by `0.38·W − 103` px (+22 px on a phone, +151 px at 1440 px wide); nothing clips | 467, 466, 363 |
| 8 | Tick grid (31 ticks, majors at `k/30`) does not align with printed labels (`v/540`; align only at 0, 360, 540) | 520-523 vs 86-102 |
| 9 | Two label conventions in one widget: speed = absolute value ratios, RPM = `0…10` "thousands" ratios, both against literal maxima | 86-102 vs 118-130 |
| 10 | `isSpeedometer: label.toLowerCase() == 'speed'` — behaviour keyed off a display string | 376 |
| 11 | `_buildStatusRow`'s `isDesktop` (141) and `_buildDetailPanel`'s `isDesktop` (185) are **dead parameters** | 141, 185 |
| 12 | Two different breakpoints: screen `> 700` (18) and panel `> 600` (243); a third (`> 800`) in the shell nav (`nested_widget.dart:46`) |
| 13 | `TelemetryDisplay.errorMessage` error branch is unreachable: `_onError` clears `isConnected` first, and the host shows `'Not connected to GT7'` | 49-55 vs `home_page.dart:309-311`, `telemetry_service.dart:126-129` |
| 14 | Graph background is `#FAFAFA` (near-white) inside a dark UI; the theme's `GT7GraphColors` (grid/track/lineA/marker/highlight, theme 91-101) is **never read by any widget** (grep: 0 consumers) | 108; theme 91-160 |
| 15 | Graph border uses `outlineVariant` → resolves to `onSurface` `#E6EEF2` at full opacity, the brightest hairline on the screen, contradicting the 4-8 % hairlines everywhere else | 295 |
| 16 | `tertiaryContainer` on the Position tile resolves to `secondary` → Position and Lap tiles share `#FFC857` | 175, `gt7_theme.dart:13-25` |
| 17 | Panel background (`surfaceContainerHighest` → `surface`) is the same colour as the screen, so the "Tire & Vehicle Status" panel has no fill at all — only a border | 189-192 |
| 18 | Gauge cards and stat tiles also use `colorScheme.surface` = screen background → their 6-8 % borders are the only separation; the black 6 % shadow is invisible | 329, 609, 334-340 |
| 19 | Graph `_getXPosition` divides by `(total - 1)` → `NaN` on the first sample | 228-229 |
| 20 | Graph has no X axis labels/ticks, so the 10 s window is unlabelled and unmeasurable on screen | 134-184 |
| 21 | `ThrottleBrakeGraphEvent.clear` is never dispatched; there is no UI way to reset history | event 15; bloc 39,112-120 |
| 22 | BLoC `initialize()` can start a **second** `Timer.periodic` without cancelling the first; polling continues after leaving the tab | bloc 50-52, 131-135; widget 25-31 |
| 23 | Documented 10 s window is unreachable: 16 ms polling × 600 cap ≈ 9.6 s, so `maxBufferSize` binds first and `timeWindowSeconds` only matters after a long gap | bloc 24,27,50,98-103 |
| 24 | The BLoC samples the *same* `TelemetryData` object every 16 ms regardless of packet arrival, so the graph is a 62.5 Hz re-plot of a 60 Hz source (duplicate samples), not a per-packet history | bloc 61-69 vs `telemetry_service.dart:84,105` |
| 25 | Both graph series are drawn on one axis with no offset and the brake line is drawn second → throttle is overdrawn where they coincide | 115-130 |
| 26 | `initial` and `loading` states render the identical placeholder | 41-42 |
| 27 | Gauge value is a 600 ms-lagged animation restarted on every packet, so the displayed number is never the instantaneous value | 365-368 |
| 28 | `titleMedium`/`bodyMedium`/`bodySmall` colours are re-specified identically to the theme (redundant `copyWith`), while `headlineMedium` is the one style left at full opacity | 349-351, 620-622, 730-732 vs 393-395 |
| 29 | Errors/settings inconsistencies: `withOpacity` is used in `telemetry_display.dart` (deprecated in this SDK, Dart 3.9 / Flutter 3.35) while `telemetry_panel.dart:68` already uses `withValues` | 192, 195, 332, 377, 381, 417 etc. |
| 30 | EV path always renders amber + `0%`; fuel has no unit; demo `rpmLimiter = 0` → the RPM footnote always reads `'Limiter: 0 rpm'` in demo mode and `estTopSpeed = 320` is a demo constant | 161-164; `telemetry_service.dart:218-219` |

---

## 11. Units (and where they are wrong / asserted)

| Displayed | Unit as rendered | Source / problem | Line |
| --- | --- | --- | --- |
| Speed gauge | `km/h` | correct: parser multiplies m/s by 3.6 (`telemetry_data.dart:135`); **hard-coded**, no mph option | 80 |
| `Top speed estimate` | `km/h`, hard-coded in the template | the parser reads `0x8C` as a raw `int16` with no scaling (`telemetry_data.dart:154`), so the unit is an assumption, not a conversion | 103 |
| RPM gauge | `rpm` | raw float `0x3C`, unscaled (`telemetry_data.dart:134`) — correct; gauge max is a literal **9000** regardless of the car's `rpmLimiter` | 110-112 |
| `Limiter` footnote | `rpm` | `0x8A` `uint16` (`telemetry_data.dart:153`) — the *only* rev-limit-related rendering; not used for any zone | 131 |
| Gear / Suggested | none (`R`, `N`, `1…`) | `suggestedGear == 0` means "unknown" in the parser (`telemetry_data.dart:144`) but `_formatGear(0)` prints `'N'` → renders `'Suggested: N'` for unknown | 153-155, 283-287 |
| Fuel / Charge tile | **no unit at all** | `0x44`/`0x48` raw floats (`telemetry_data.dart:239-240`); the value reads `100 / 100` | 158-160 |
| Fuel subtitle | `%` | `fuel/maxFuel`; forced `0%` whenever `maxFuel <= 0` (EV) | 144-146, 164 |
| Lap / Best / Last | `M:SS.mmm` (no hours) | `formatLapTime` returns `''` for `<= 0`, else 3-decimal minutes:seconds (`telemetry_data.dart:300-306`); the `'Best: '`/`'Last: '` prefixes stay and render with an empty tail before the first lap | 170, 176 |
| Position | `n/m` | `0x84`/`0x86` `int16` (`telemetry_data.dart:127-128`), no 1-based fix-up | 174 |
| Oil / Water / tyre temps | `°C` + 1 decimal | raw floats (`0x5C`, `0x58`, `0x60-0x6C`), no conversion | 251, 261, 673 |
| Brake chip | `%` + 0 decimals | `0x92 / 2.55` (`telemetry_data.dart:136`) — brake **pedal position**, labelled `Brake` | 271 |
| Gauge big numbers | none | `toStringAsFixed(0)` → whole km/h, whole rpm | 392 |
| Graph Y axis | `%` labels `0/50/100` | input is already 0-100 (`throttle_brake_graph_bloc.dart:88-92`); mapping divides by 100 (`233-235`) | 144-145 |

Watch out: `curLapTime` (the parser's "current lap time in seconds") is computed by the service with a
`DateTime` stopwatch started when the app first sees a new `currentLap` (`telemetry_service.dart:87-101`) —
it is wall-clock from the app's own observation, not the game's lap clock, and **it is never displayed**
(`formatCurLapTime`, `telemetry_data.dart:308-313`, is never called — 1 occurrence in the whole repo).

---

## 12. What the screen does NOT have at all

Nothing in the list below exists anywhere in the current UI (verified by reading all of
`telemetry_display.dart`, `throttle_brake_graph.dart` and their painters; several of these have parsed data
sitting unused, noted in brackets):

**Gauges / revs**
1. Analogue **needle** (the `needleColor` parameter is dead) — only an arc fill.
2. **Redline / rev-limit zone** on the RPM gauge (the zone data exists in code but is painted grey).
3. **Shift light / rev warning** — `rpmWarning` (`0x88`) is parsed and never rendered; `suggestedGear` is
   printed as text only, with no up/down shift arrow or light bar.
4. **Gear / rev bar** (GT7's row of lights above the gear digit) — the gear is a 170 px text tile.
5. **Boost / turbo gauge** — `boost` (`0x50`) parsed, unused.
6. **Oil pressure** and **ride height** gauges — parsed (`0x54`, `0x38`), unused; oil/water are text chips only.
7. **Speed scale beyond 540 km/h / above 9000 rpm** — both maxima are literals, and each value is
   `clamp`-ed to them, so any car exceeding either saturates.
8. No **mph/kph or metric/imperial switching**.

**Inputs**
9. **Throttle/brake bars** (the classic vertical T/B bars) — brake exists only as one number; throttle has no
   numeric or bar readout at all.
10. **Brake pressure vs pedal position** distinction — only pedal position `0x92` is read.
11. **Steering input** indicator — there is no steering field in the model at all.
12. **Clutch / clutch engagement** — `clutch`, `clutchEngaged`, `rpmAfterClutch` (`0xF4`, `0xF8`, `0xFC`)
    parsed, unused.
13. Any **input histogram / pedal trace** other than the single throttle+brake 2-line graph.

**Tyres**
14. **Tyre wear** — not parsed, not shown.
15. **Tyre pressure / compound / temperature zones** (inner/middle/outer) — not available, not shown.
16. **Wheel slip / wheel-speed** display — `tireSpeed*` and `tireSlipRatio*` are computed and never rendered.
17. **Per-wheel locking / spinning** indication.
18. `tireDiam*` is parsed only as an intermediate for `tireSpeed` and never shown.

**Chassis**
19. **G-force meter** (lateral/longitudinal) and the G-circle — `angVel*`, `rot*`, `vel*` parsed, unused.
20. **Suspension histogram / travel graph** — `suspensionFL..RR` (`0xC4..0xD0`) parsed, unused.
21. **Track map / driving line** — `posX/posY/posZ` parsed, unused.

**Timing / race context**
22. **Delta to best / delta to reference lap** — absent (no such field, no computation).
23. **Sector times / sector deltas / best sectors** — absent (only whole best/last lap times are shown).
24. **Current lap time** — computed by the service as `curLapTime` and never shown.
25. **Per-lap history**, lap list, lap chart, session/optimum — absent.
26. **Reference-lap overlay / best-lap ghost line on the graph** — absent; the graph holds a single rolling
    10 s window of one lap's inputs and has no second series.
27. **Gap / interval to the car ahead or behind** — only the raw position number is shown.
28. **Fuel-per-lap, laps remaining, fuel map / ECU mode, pit strategy** — absent; only a raw counter + a %.
29. **EV battery / regen / deployment** — `isEV` merely renames the tile; no charge %, no regen, no deployment.
30. **Time of day / weather / track state** — `timeOfDay` (`0x80`) parsed, unused.
31. **Flag / penalty / tyre-wear flag bits** — `flags8E`, `flags8F`, `flags93` parsed, unused.
32. **Car identity** — `carId` parsed, unused; no car name anywhere.

**Chart affordances**
33. **Distance or time axis** on the graph — the X axis is sample index, with no labels or ticks.
34. **Graph cursor / hover values**, zoom, freeze, or panning.
35. **Any on-screen control** — no app bar, no title, no unit toggle, no pause, no reset, no export, no
    fullscreen; the only interaction surface is the tab shell that hosts it.

---

## 13. Rendered fields vs parsed-but-unused fields

`TelemetryData` declares **86 fields** (`lib/models/telemetry/telemetry_data.dart:5-114`). **23** of them reach
the UI. **63** are parsed and never rendered (plus `curLapTime`, which is *computed* and never rendered, and
`packetId`, which is used only by the service's monotonic check).

### Rendered (23)

| Field | Parsed at | Rendered as | Where |
| --- | --- | --- | --- |
| `speed` | `0x4C × 3.6` (135) | Speed gauge value + 600 ms animated number; clamped 0-540 | 78, 392 |
| `rpm` | `0x3C` (134) | RPM gauge value; clamped 0-9000 | 110, 392 |
| `estTopSpeed` | `0x8C` (154) | Speed footnote `Top speed estimate: N km/h` | 103 |
| `rpmLimiter` | `0x8A` (153) | RPM footnote `Limiter: N rpm` | 131 |
| `currentGear` | `0x90 & 0x0F` (146) | `Gear` tile value (`R`/`N`/digit) | 153 |
| `suggestedGear` | `0x90 >> 4` (147) | `Gear` tile subtitle `Suggested: …` | 155 |
| `fuel` | `0x44` (239) | `Fuel`/`Charge` tile value (no unit) + `fuelPercent` | 159-160, 145 |
| `maxFuel` | `0x48` (240) | same value string + `fuelPercent`; also drives `isEV` | 160, 144-146, 241 |
| `isEV` | derived `maxFuel <= 0` (241) | Tile title `Charge` vs `Fuel`, accent fallback | 158 |
| `currentLap` | `0x74` (125) | `Lap` tile `n/m` | 168 |
| `totalLaps` | `0x76` (126) | `Lap` tile `n/m` | 168 |
| `bestLapTime` | `0x78` (129) | `Lap` tile subtitle `Best: M:SS.mmm` | 170 |
| `currentPos` | `0x84` (127) | `Position` tile `n/m` | 174 |
| `totalPositions` | `0x86` (128) | `Position` tile `n/m` | 174 |
| `lastLapTime` | `0x7C` (130) | `Position` tile subtitle `Last: M:SS.mmm` | 176 |
| `tireTempFL` | `0x60` (166) | `FL` badge (`°C` + state) | 216 |
| `tireTempFR` | `0x64` (167) | `FR` badge | 219 |
| `tireTempRL` | `0x68` (168) | `RL` badge | 222 |
| `tireTempRR` | `0x6C` (169) | `RR` badge | 225 |
| `oilTemp` | `0x5C` (160) | `Oil Temp` chip (`°C`, 1 dp) | 251 |
| `waterTemp` | `0x58` (161) | `Water Temp` chip | 261 |
| `brake` | `0x92 / 2.55` (136) | `Brake` chip (`%`) + graph brake line | 271; graph 124-130 |
| `throttle` | `0x91 / 2.55` (133) | graph throttle line **only** (no numeric readout) | graph 115-121 |

Internally used, not rendered: `packetId` (`0x70`) — gates updates (`telemetry_service.dart:84`).

### Parsed but never rendered (63)

| Group | Fields | Parsed at (model line) | Comment |
| --- | --- | --- | --- |
| Time | `timeOfDay` | `0x80` (124) | no clock/tod anywhere |
| Lap time | `curLapTime` | computed in service (95-96), declared 13 | `formatCurLapTime` never called |
| Car | `carId` | `0x124` (132) | no car name/id shown |
| Engine | `boost` | `0x50-1` (149-150) | no turbo gauge |
| Engine | `rpmWarning` | `0x88` (152) | no shift light / rev warning |
| Clutch | `clutch`, `clutchEngaged`, `rpmAfterClutch` | `0xF4`, `0xF8`, `0xFC` (156-158) | — |
| Engine | `oilPressure` | `0x54` (162) | — |
| Engine | `rideHeight` | `0x38 × 1000` (163) | mm value never shown |
| Tyres | `tireDiamFL/FR/RL/RR` | `0xB4/B8/BC/C0 × 200` (171-174) | intermediates for `tireSpeed` only |
| Tyres | `tireSpeedFL/FR/RL/RR` | computed (178-185) | no wheel-speed trace |
| Tyres | `tireSlipRatioFL/FR/RL/RR` | computed strings (187-200) | no slip/grip display |
| Suspension | `suspensionFL/FR/RL/RR` | `0xC4/C8/CC/D0` (202-205) | no histogram |
| Gearing | `gear1`…`gear8` | `0x104`…`0x120` (208-215) | no ratio table |
| Gearing | `gearUnknown` | `0x100` (216) | — |
| Position | `posX`, `posY`, `posZ` | `0x04`, `0x08`, `0x0C` (219-221) | no track map |
| Velocity | `velX`, `velY`, `velZ` | `0x10`, `0x14`, `0x18` (224-226) | — |
| Rotation | `rotPitch`, `rotYaw`, `rotRoll` | `0x1C`, `0x20`, `0x24` (229-231) | no attitude/G display |
| Angular | `angVelX`, `angVelY`, `angVelZ` | `0x2C`, `0x30`, `0x34` (234-236) | no yaw-rate/G display |
| Flags | `flags8E`, `flags8F`, `flags93` | `0x8E`, `0x8F`, `0x93` (244-246) | no flag/penalty/wear bits |
| Unidentified | `float94`, `float98`, `float9C`, `floatA0`, `floatD4`, `floatD8`, `floatDC`, `floatE0`, `floatE4`, `floatE8`, `floatEC`, `floatF0` | `0x94`…`0xF0` (249-260) | 12 raw floats, never used |

Total: 63 rows above = 86 − 23 rendered.

---

## 14. Numbers cheat-sheet (for direct comparison)

* Screen padding 16; inter-section gaps 18; no app bar; page title absent.
* Card: padding 14, radius 20, border 1 px @ 8 % `onSurface`, shadow blur 18 / offset (0,10) / 6 % black.
* Gauge canvas: 240 px tall, radius = `0.38 × card width`, stroke 18, arc 135° → 405° (270° sweep),
  31 ticks (7 major), major tick 14 / minor 8, tick widths 2.5 / 1.2, labels 12 px `#9E9E9E` at
  `radius − 34` (speed) / `radius − 22` (rpm), value animation 600 ms `easeOutCubic`.
* Speed scale 0-540 km/h, label step 40 (15 labels); RPM scale 0-9000, labels `0…10` (11 labels).
* Stat tile 170 × auto, padding 14, radius 16, border 1 px @ 6 %; title 12 / value 22 / subtitle 12.
* Tyre badge 130 × auto, padding 14 vertical / 12 horizontal, radius 14, fill 14 % / border 25 % of the
  threshold colour; temps 1 dp, thresholds 80 / 110 / 130 °C.
* Detail chip padding 14, radius 14, fill 12 %, no border; label 12 / value 16.
* Graph: 200 px tall, 8 px padding, legend swatch 16 × 2, plot left padding 40, right margin 10, x-axis at
  `height − 20`, 0 % at the axis, 100 % at `y = 10`, Y labels 12 px `#757575` `100/50/0 %`, lines 2 px,
  background `#FAFAFA`, buffer 600 samples / 10 s window / 16 ms poll.
