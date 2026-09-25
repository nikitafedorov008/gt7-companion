# Gran Turismo 7 — in-game telemetry UI specification

**Purpose.** A source-backed, image-verified specification of how telemetry is *displayed inside Gran Turismo 7*
(PS4/PS5), so it can be compared against this app's Flutter telemetry screen.

**Scope — two deliberately separate subjects**

1. **In-race HUD** (real-time): the race screen with its 25 numbered elements, the instrument cluster, the
   Multi-Function Display (MFD), the tyre / fuel / assist indicators. Present in every race.
2. **Data Logger** (post-session): introduced by the **Spec III update, released 2025-12-03**. Available for
   **Time Trial and Drift Trial replays only** (`/datalogger/01`). This is the only real telemetry-analysis
   screen in the game.

**Method / evidence classes.** Every claim below is tagged:

* `[MANUAL]` — text of the official GT7 online manual (fetched from its JSON/HTML endpoints).
* `[MANUAL-IMG]` — the official manual figure; I downloaded and pixel-inspected it, including cropped zooms.
* `[NEWS]` — official Polyphony news post `00_5736734.html`.
* `[GTP]` — GTPlanet hands-on article `gt7-spec-iii-data-logger-20251110`.
* `[GT6]` — the ancestor feature's manual pages (history only).
* `[OBS]` — my own reading of the reference screenshot, described as seen.
* `[PX]` — measured programmatically from the reference image (colour sampled with PIL; values are from a
  JPEG/PNG so treat 8-bit values as ±2 and semi-transparent panels as background-dependent).
* `[?]` — could not be confirmed; collected in §7.

Provenance checks performed: `docs/reference/gt7/gt7-race-screen-annotated.jpg` is **pixel-identical**
(mean abs difference 0 on a 64×64 greyscale reduction) to the official manual figure
`/images/c/i1B1lEMx5qJnOb.png` referenced by manual page `/race/02`. `gt7-data-logger.jpg` is **byte-identical**
(md5 `88a5461f5702a3fa623bc3650b08d4f6`) to the official manual figure
`/images/c/i1OtyKTbY3tlvuB.jpg` referenced by `/datalogger/01`.

---

## 1. In-race HUD inventory (the 25 numbered elements)

Manual page `/race/02` "The Race Screen" says: *"The image shows all the information that can be shown in Normal
view. The race screen will look different during an actual race. The details shown will vary depending on the
current view and the type of race."* The manual figure carries exactly **25** blue numbered legend badges; the
official legend (`gt7-race-screen-annotated.jpg`, 1920×1080) is the primary source for this table. Elements are
listed in the manual's own numbered order.

Positions are given in normalised screen coordinates (fraction of a 1920×1080 frame, origin top-left), read off
the annotated figure; treat them as approximate — the HUD is drawn over the scene and some elements only appear
in certain race types.

### 1.1 Top strip

| # | Name `[MANUAL]` | What it shows | Visual form `[OBS]` | Where | Colour `[OBS]`/`[PX]` |
|---|---|---|---|---|---|
| 1 | **Current Position / Number of Cars** | *"the total number of cars in the race and the position of your car"* | Two-part number: a large numeral, then a smaller `/N`. A small uppercase caption label sits above/right. No panel behind it (drawn direct on scene). | Top-left, ≈ (0.01–0.07, 0.02–0.10) | White numeral, white/grey caption. In the annotation figure the numeral is white on the scene with no backing plate. |
| 2 | **Current Laps / Total Laps / Final Lap** | *"the total number of laps and the lap your car is currently on. Also displays a notice during the final lap."* | Same two-part number form as (1) (`LAP 1/20`), with a caption label. On the final lap the text becomes `FINAL LAP  10/10` in **white bold** (see also element 6, which is the separate red badge). | Top-left, immediately right of (1), ≈ (0.10–0.16, 0.02–0.10) | White. |
| 3 | **Rear-view Mirror** | *"Shows what's happening behind you."* | Live-rendered rectangular inset video (not a graphic) with a thin ~1 px light border and slight rounded corners; aspect ≈ 3.4:1. | Top-centre, ≈ x 0.28–0.70, y 0.00–0.11 | Full-colour scene; 1 px white/grey border. |
| 4 | **Track Map** | *"a map of the track and the positions of each car"* | Line drawing of the circuit as a closed outline (in the reference captures it is drawn as a **double line** = both track edges), no fill, no axes; other cars are small dots/markers; a small white boxed numeral marks a special car/lap marker. | Top-right, ≈ x 0.77–0.99, y 0.02–0.30 | White/grey 1–2 px line on transparent scene; car dots coloured (blue/red seen). |
| 5 | **Lap Times** | *"your times for each lap"* | Right-edge **two-column table**, most recent lap at the **top**: a **light grey/white left column** carrying the lap numeral in dark bold (`5`, `4`, `3`, `2`, `1`), then a dark-tinted right column with the lap time in white (`1'23.900`, `1'17.677`, `1'21.001`). Rows are separated by hairline rules. **The fastest lap in the table is drawn as a solid purple/violet row** (`4  1'15.339` in the annotated figure) while the rest are dark. | Right edge, ≈ x 0.87–1.00, y 0.32–0.58 (five rows visible in the annotated figure: `5 —`, `4 1'15.339` purple, `3 1'23.900`, `2 1'17.677`, `1 1'21.001`) | Number column: light grey fill, dark numerals. Time column: translucent dark fill, white numerals. Fastest row: purple `#8E4DB1 [PX]` fill, white numerals. |
| 6 | **Final Lap** | *"Displays when you have entered the final lap."* | **Red rounded-rect badge** (pill) with white bold uppercase `FINAL LAP`, centred above the timing bar. | Top-centre, ≈ x 0.47–0.56, y 0.19–0.23 | Red fill, white text. |
| 7 | **Current Lap Time / Best Times per Sector** | *"your current lap time. The display will switch whenever you set a new best time for each sector of the track."* | Centred **horizontal timing bar**: a purple rounded chip reading `BEST`, then a large **segmented/seven-segment-style digital numeral** (e.g. `0:09.500`), then a second purple rounded chip holding a signed delta (`- 2.338`). Numbers use the game's squared, slanted LED-style face with hairline gaps between digit cells. | Top-centre, ≈ x 0.38–0.68, y 0.22–0.27 | Time = white; both chips = purple `#8E4DB1 [PX]` with white text. |
| 12 | **Time Difference with Best Lap** | *"During a time trial, this gives a real-time display of the time difference between your best lap for the session and your current time. If your time is better, it'll be displayed in blue with a minus sign; if it isn't, it'll be displayed in red with a plus sign."* | Small **triangle glyph** (▲/▼) + signed decimal seconds, centred just above the instrument cluster. | ≈ x 0.50, y 0.615 (in the annotated figure: cyan ▲ `-2.508`) | Cyan/blue triangle when ahead, red when behind `[MANUAL]`; the number is white with a dark outline. |

### 1.2 Left column

| # | Name `[MANUAL]` | What it shows | Visual form `[OBS]` | Where | Colour |
|---|---|---|---|---|---|
| 8 | **Position Indicator** | *"the two drivers in front of you, the two drivers behind you, and the time differences between their cars and your car. This will also display your pit stop status while you are taking a pit stop."* | Left-edge **list**: rows of `position numeral | driver name | national-flag icon | time gap`. In the reference captures the list is presented in two blocks: the leading positions (1–5) at the top, then — separated by a blank gap — the player's local neighbourhood (player row plus the two ahead / two behind). The player's own row carries a **red/pink gap pill**; other rows are plain white. Semi-transparent dark panel behind the block. | Left edge, ≈ x 0.00–0.17, y 0.13–0.52 | Dark translucent panel; white names/numbers; small full-colour flags; **red/pink** pill for your own position (`+5.708`, `+4.966`, `+3.703` seen). |
| 9 | **Fastest Lap Notification** | *"Notifies you when you break a fastest lap record during a race."* | A short **purple/violet bar** below the driver list carrying the lap time in white. | Left edge, ≈ x 0.02–0.19, y 0.53–0.58 | Purple/violet translucent bar, white time. Purple = "best" in GT7's HUD semantics. |
| 10 | **Total Time** | *"the total time elapsed since the start of the race."* | Plain **text-only** readout (no panel, no label), proportional digits. | Bottom-left corner, ≈ x 0.03–0.13, y 0.94–0.98 (annotated figure: `2'46.633`) | White. |

### 1.3 Centre — driving input cues

| # | Name `[MANUAL]` | What it shows | Visual form `[OBS]` | Where | Colour |
|---|---|---|---|---|---|
| 11 | **Braking Suggestion** | *"Displays when it is necessary to brake. For example, just before a corner, red text will blink and the meter panel will turn red, telling you to brake."* | Word `BRAKE` in red capitals, centred; the associated meter panel turns red. | ≈ x 0.50, y 0.585 (just above the steering indicator) | Red text; red panel fill. |
| 13 | **Steering Angle / Gear Change Indicator** | *"The red dot moves left and right to indicate how much you're steering in that direction. The shift indicator is shown below. This will light up when the engine revolution gets close to the red zone, letting you know when it's time to shift gears."* | Two parts. (a) A thin horizontal hairline with a **small red dot** (current steering) and a **grey dot** (centre reference) sliding along it. (b) **Below it**, inside the speed/gear panel, a **rounded-square lamp**: unlit it is an empty dark rounded box occupying the slot to the right of the gear numeral, directly above the transmission-mode label; lit it is **bright red with a bold black glyph inside**. | (a) ≈ y 0.625 across x 0.44–0.56. (b) inside the gear block at ≈ x 0.535, y 0.685 | Lamp lit = **`#FA0F0B`** `[PX]` (saturated pure red) with black glyph; unlit ≈ `#181B20` `[PX]`. |
| 14 | **Car Speed / Gear / Blindside Indicator** | *"the car speed and gear number of the transmission. The red semi-circles on either side are the blindside indicators. These will light up to indicate how close other cars are to the left and right sides of your car."* | **Dark trapezoid/hexagonal digital panel** (wider at the top, sides sloping inward), centred. Left cell = speed as large squared digital numerals over a small unit label (`km/h` / `mph`); a 1 px vertical white divider; right cell = gear numeral, with the transmission-mode label (`MT` / `AT`) under the lamp slot. A row of ~40–60 thin vertical ticks runs along the panel's top edge. Flanking both sides: concentric **red semi-circular arcs** (blindside indicators). | Centred, ≈ x 0.40–0.60, y 0.63–0.72 | Translucent near-black panel (~`#20242C` at ~75 % over the scene `[PX]`, background-dependent); **white** digits; red arcs and red lamp. |
| 16 | **Brake Pressure** | *"Pressure when braking is shown as a white bar here. The amount of pressure reduced by the effect of ABS is displayed in red."* | **Vertical bar**, ~14 px wide, sitting in a thin outlined bracket; white fill from the bottom, a **red cap at the top** representing the ABS-reduced portion; a small pedal glyph beneath. | Left of centre, ≈ x 0.36, y 0.78–0.93 | White bar + **red** segment. |
| 19 | **Throttle** | *"Displays the throttle as a white bar. If this is stabilized by traction control, the degree of this effect will be shown in red."* | **Vertical bar** identical in form to (16), inside a thin white bracket; white fill, red portion = traction-control intervention. | Right of centre, ≈ x 0.585–0.61, y 0.76–0.93 | White bar; red for TC. |

### 1.4 Centre-bottom — instrument cluster and MFD

| # | Name `[MANUAL]` | What it shows | Visual form `[OBS]` | Where | Colour |
|---|---|---|---|---|---|
| 15 | **Speedometer / Fuel Meter / Odometer / Handbrake Indicator** | *"The fuel meter is displayed for races with fuel consumption activated. The odometer shows how far you've driven in each car. The handbrake indicator lights up when the handbrake is in use."* | **Round dial with needle** (left of the pair). Outer graduated arc with white ticks and italic white numerals; inside the dial a **fuel arc gauge** between `E` and `F` with a fuel-pump icon; a dark inset box with the **odometer** as digital numerals; a handbrake lamp. | Left of centre, centre ≈ (0.215, 0.76), outer radius ≈ 0.075 of frame width | Dark dial face (translucent), **white** arc/ticks/numerals; odometer in a dark box with white digits. |
| 17 | **Multi-Function Display (MFD)** | *"lets you adjust settings like traction control and displays useful information while you're driving."* | Centred panel **below** the speed/gear block: page **title** in white centred, flanked by **left/right chevrons** (◀ ▶ = the d-pad page navigation), then the page's own graphic (see §2.4), then a row of small round **page-indicator dots**. | Centred, ≈ x 0.36–0.64, y 0.72–0.86 | White title/chevrons on the translucent cluster panel; dots dark grey with the active page in white. |
| 18 | **Tachometer / Boost Gauge / Light Indicator** | *"The tachometer shows the number of engine revolutions. The light indicator lights up when the car's lights are on. The boost gauge displays the boost pressure for turbo or superchargers."* | **Round dial with needle** (right of the pair): outer graduated arc, numerals `0..N`, a **red/amber band marking the redline**, and a `x1000rpm` caption inside. Inside the dial: a smaller **arc sub-gauge for boost** captioned `x1000 kPa` (scale −1 … +2, with a turbo/supercharger symbol) and a **headlight lamp icon**. | Right of centre, centre ≈ (0.735, 0.76), outer radius ≈ 0.085 | White arc/numerals/needle; redline band red; lamps white when lit. |
| 20 | **Equipped Tires (Initials) / Tire Temperature / Tire Health / Mechanical Damage** | *"The initials for the type of equipped tires (e.g. 'RH' for Racing: Hard and 'SS' for Sport: Soft) will be shown at the front and back of the car icon. As the tires get hotter, the outside frame for the four tires will get redder. As the tires wear down, the icons for them will change from white (healthy) to red (worn out)."* + `/race/06`: *"If the Suspension is Damaged … highlighted in red. If the Engine is Damaged … The engine icon in the center of the car diagram will be highlighted red."* | **Icon widget**: a rear-view car diagram in the centre (with an engine icon inside it and small chevrons around it for the blindside cue), surrounded by **four rounded-rect tyre bars** (two left = front-left/rear-left, two right = front-right/rear-right); **compound initials** (`SS`, `SH`, `RH`, …) printed above and below. | Bottom-left, ≈ x 0.12–0.26, y 0.76–0.95 | Bars light grey/white when healthy → **red** as they wear; a frame reddens with tyre temperature; red highlights for suspension/engine damage. |
| 21 | **Surface Water Indicator** | *"Displays how wet the surface of the track is. The longer the bar, the more wet the track is."* | **Narrow vertical bar with 4 ruler-like subdivisions** and a small tyre-on-water pictogram at its middle; sits immediately left of the tyre widget. | Bottom-left, between x 0.11 and the car diagram, y 0.79–0.94 | Thin white tick rules on transparent scene. |
| 22 | **Driving Assistance Indicators (ABS / Auto-Drive: Brakes / Auto-Drive: Steering)** | *"Driving assistance functions that are turned on will be displayed in white, while those that are turned off will be displayed in grey. Functions that are currently engaged will be displayed in red."* | **Icon row** of three small circular outlined glyphs at the left foot of the cluster. | ≈ x 0.15–0.22, y 0.90–0.945 | White = on, grey = off, **red = engaged** (the ABS glyph is red in the annotated capture). |
| 23 | **Driving Assistance Indicators (traction control / stability management / countersteering assistance)** | same legend wording | Matching **icon row of three** at the right foot of the cluster. | ≈ x 0.71–0.80, y 0.90–0.945 | White = on, grey = off, red = engaged. |
| 24 | **Nitro Indicator / Overtaking Indicator** | *"Only displayed in cars with a Nitro or Overtaking system. The indicator flashes red when engaged. The semi-circle at the top of the indicator represents the amount of time remaining."* | **Small gauge**: a semi-circular arc at the top (remaining time) over a labelled capsule reading `NITRO`. | Bottom-right, ≈ x 0.82–0.90, y 0.89–0.96 | White outline; flashes **red** when engaged. |

### 1.5 Other transient HUD

| # | Name `[MANUAL]` | What it shows | Visual form `[OBS]` | Where | Colour |
|---|---|---|---|---|---|
| 25 | **Overtaken Car Info** | *"Displays information about cars overtaken during a race."* | Small dark **plate**: manufacturer on one line, model + year on the next (`NISSAN` / `180SX Type X '96`). | Right side, mid-height, ≈ x 0.86–0.99, y 0.66–0.74 | Dark translucent plate, white text. |

Additionally observed but **not** among the 25 (see §7):
* a small **downward-arrow + velocity** readout directly beneath the track map (e.g. `↓ 7.8 ft/s` in the US
  locale), present in both the normal-view and chase-view captures, form: small icon + number + unit `[OBS]`;
* floating **car-name labels** above the cars in the world (position numeral in a small box + car name), which are
  the "Car Name Indicator" / "Display Driver Names" display settings (`/drivingoption/05`) `[MANUAL][OBS]`.

### 1.6 Views

`/race/03` documents four views — **Cockpit**, **Normal**, **Hood**, **Chase** — switchable with **R1** by default.
`[OBS]` The HUD element set and the cluster drawing are the same in all four; only the camera changes. In Cockpit
view parts of the cluster are occluded by the car's steering wheel/dash (visible in `gt7-cockpit-view.jpg`), and
the MFD's "Course Map" pane stays bottom-right. `/drivingoption/05` lists the display filters that gate the HUD:
*Show Race Info*, *Show Drivers List* (driver names and/or car names), *Car Name Indicator*, *Display Driver Names
(Online Races)*, *Ghost Display*.

---

## 2. Instrument cluster detail

The cluster is one connected visual unit sitting bottom-centre of the screen, made of: left dial, centre digital
panel + rev tick strip, right dial, MFD below the centre panel, tyre widget + surface-water bar to the left, and
two 3-icon assist rows at the outer bottom corners.

### 2.1 Left dial — speedometer (+ fuel + odometer + handbrake)

| Property | Value | Class |
|---|---|---|
| Form | Round dial, needle, printed scale arc **outside** the numerals | `[OBS]` |
| Scale range | Car-dependent. Observed: **0–280** (annotated manual figure, `km/h`) and **0–320** (MFD capture, `km/h`); **0–200** on the `mph` captures. Major ticks every **40**, labels at every major tick | `[OBS]` |
| Tick style | Thin white ticks crossing a continuous white arc; labels in a white slanted/italic face placed inside the arc | `[OBS]` |
| Needle | Single long light needle from the hub | `[OBS]` |
| Redline/marking | **None observed** on the speedometer (no red arc segment) | `[OBS]` |
| Unit label | `km/h` printed **inside** the dial face (upper-right of the face, between the `160`–`200` labels in the 320-km/h car) | `[OBS]` |
| Sub-gauges inside | **Fuel gauge**: a small arc between `E` and `F` with a fuel-pump pictogram, white arc; present only when fuel consumption is enabled (`/race/02`). **Odometer**: dark inset rectangle with digital numerals, e.g. `082,882.3` / `000,017.4` (a tenths digit is shown) | `[OBS]`, `[MANUAL]` |
| Dial face | Translucent dark (near-black, ~`#171A1F` over dark tarmac `[PX]`); because it is translucent the sampled value depends on the scene | `[PX]` |
| Also here | Handbrake indicator lamp (`/race/02`) | `[MANUAL]` |

### 2.2 Centre digital panel

* Silhouette: a **trapezoid** — the top edge is the widest, the sides slope inward going down, and the bottom is
  shorter; top corners are slightly rounded `[OBS]`.
* **Rev bar**: a row of very thin vertical ticks spanning the full top edge of the panel. Unlit ticks are dark
  grey; when the engine nears the red zone the strip (from the left, filling) lights in **pink-red `#DB557A`
  `[PX]`**; in the Session Best capture the strip is fully lit. This is the visible form of "the shift indicator
  … will light up" in `/race/02` — the game's own HUD uses both a *strip* along the panel top and the *lamp*
  described in §1.3 (13). `[OBS]`
* **Speed**: left cell, large squared/LED-style white numerals. Optical size ≈ 60 px tall in a 1920×1080 frame
  (about 5.5 % of frame height). Unit label `km/h`/`mph` beneath in small white text. `[OBS]`
* **Divider**: a single 1 px vertical white rule between the speed and gear cells. `[OBS]`
* **Gear**: right cell, the same squared white numeral (e.g. `4`), rendered about 25 % larger than the speed
  digits. Below it the transmission-mode label `MT` or `AT` in small white text. `[OBS]`
* **Shift lamp**: a rounded square immediately to the right of the gear numeral, occupying the same slot as (and
  directly above) the mode label. Unlit = empty dark rounded box; lit = **solid `#FA0F0B`** with a bold black glyph
  (observed glyphs: `1` with gear 5, `2` with gear 4 — meaning unverified, §7). `[OBS][PX]`
* **Blindside indicators**: concentric **red** semi-circular arcs on the left and the right of the panel, hugging
  it `[MANUAL: "The red semi-circles on either side"]`, `[OBS]`.

### 2.3 Right dial — tachometer (+ boost gauge + lamp)

| Property | Value | Class |
|---|---|---|
| Form | Round dial, needle, graduated scale arc | `[OBS]` |
| Scale range | `0..N ×1000` rpm, caption **`x1000rpm`** (or `x1000 r/min`) printed inside the dial; observed end values **8** (numeric, manual figure) and **10** | `[OBS]` |
| Tick style | White ticks on a white arc; labels `0,1,2,3,…` | `[OBS]` |
| Redline marking | A **red band on the outer arc**; its extent is car-dependent — a short segment at the top of the scale in the manual figure (≈ `7→8`), and in the MFD capture almost the whole arc is red. The band is drawn **on the scale ring itself**, not as a separate marking | `[OBS]` |
| Needle | White, from the hub | `[OBS]` |
| Sub-gauge inside | **Boost gauge**: a smaller arc spanning ≈ −1 … +2 with the caption **`x1000 kPa`**, a centre-zero arc, and a small turbo/supercharger pictogram; used for turbo/supercharged cars (`/race/02`). In the reference captures this sub-gauge sits in the lower half of the dial | `[OBS][MANUAL]` |
| Lamp | A **headlight icon** inside the dial lights when the car's lights are on (`/race/02`) | `[MANUAL][OBS]` |

### 2.4 MFD

`/race/04` documents the MFD as switched with the **left/right directional buttons** and adjusted with **up/down**.
Pages `[MANUAL]`:

1. **TCS (Traction Control)** — adjust strength in real time.
2. **Brake Balance** — front/rear brake strength; *"A 'Brake Controller' must be installed to view/adjust."*
3. **Fuel Map** — fuel/air concentration; default is `Power` (1), higher numbers go towards `Lean` and reduce
   output in exchange for fuel economy; **an estimate of laps you can run at the current setting is shown below the
   meter**; requires a *Fully Customizable Computer*.
4. **Track Map** — enlarged map of the area around your car. The in-game title observed on screen is
   **`Course Map`** `[OBS]`.
5. **Radar** — other cars close to your car.
6. **Weather Radar** — rainfall around the track; precipitation shown in *"light blue, blue, green, yellow-green,
   orange and pink"*; up/down zooms the radar.
7. **Session Best / Car Record** — see below.

Observed page chrome `[OBS]`: the page **title** is centred in white above the page graphic; **◀ ▶ chevrons**
sit at the left and right of the title row; a **row of small round page dots** sits under the cluster with the
active page white and the rest dark grey (the manual's MFD legend numbers **6** features; the reference captures
show about 6–7 dots — the exact count and dot↔page mapping are unverified, §7).

**Fuel Map page, as drawn** `[OBS]` (`gt7-mfd-fuel-map.jpg`): a horizontal **arc gauge** whose ends are labelled
`POWER` (left) and `LEAN` (right); the arc is built from discrete segments — the span between the two ends is drawn
green, the remaining segments dark; the current setting is a thick **white rectangular pointer** on the arc; small
`▲`/`▼` chevrons sit between the labels (up/down adjustment). Below the arc are two dark inset panels side by side:
`Remain Laps` / a large white `7.0`, and `Fuel` / a large white `98%` — i.e. the label is small and grey, the value
is large and white.

**Session Best / Car Record page, as drawn** `[OBS]` (`gt7-mfd-session-best.jpg`). The manual's layout list is
exactly the row semantics:

| Manual bullet (`/race/04`) | Row in the on-screen table |
|---|---|
| Time for each sector | sector rows, numbered (`2`, `1`) — most recent sector at the **top** |
| Time for the previous lap | row labelled `LAST` |
| Best lap time for the session | row labelled `BEST` |
| Theoretical best lap time calculated from the best sector times | row labelled `OPT.` |
| Difference between the previous sector time and this session's best time | the right-hand delta column on the sector rows |
| Difference between the previous lap time and this session's best lap time | the right-hand delta on the `LAST` row |

Form: a 3-column table — a **label column** (light-grey/white cells with dark text for sector numbers and
`LAST`; a **green** cell for `BEST`; a dark cell with white text for `OPT.`), a **time column** of dark cells with
white numerals (`0'25.036`, `0'29.540`, `0'54.576`, `0'54.266`), and a **delta column** of coloured pills.
Placeholder row (`--` / `--'--.---`) for a sector not yet driven. Colours `[OBS][PX]`: **red pill** for a time
loss (`+ 0.310`, dark brick red ≈ `#7A2A1E`), **blue pill** for a gain (`- 0.454`, `- 0.144`, dark steel blue
≈ `#2F4C6C`), **green** for the session-best row (`BEST` cell fill green and its time printed green); the `LAST`
row's time cell is the plain dark cell; `OPT.` is muted (white on near-black). Every cell is separated by a
hairline border. Values in the reference capture: sector 2 `0'25.036 +0.310`, sector 1 `0'29.540 -0.454`,
`LAST 0'54.576 -0.144`, `BEST 0'54.576`, `OPT. 0'54.266` — consistent (25.036 + 29.540 = 54.576).

> Sign convention on these pills is plainly **loss = red with `+`, gain = blue with `-`**, matching
> `/race/02`'s rule for the time-difference readout ("better … blue with a minus sign; … red with a plus sign").

### 2.5 Tyre widget, surface water, fuel

* **Tyre widget** `[OBS]`: a rear-view car diagram (engine pictogram inside, per `/race/06`) surrounded by four
  rounded-rectangle **tyre health bars** — front pair at the top, rear pair at the bottom in the annotated figure
  and in the captures (bars are drawn left/right of the car, one per wheel). The **equipped compound initials**
  (`CH/CM/CS`, `SH/SM/SS`, `RH/RM/RS`, `IM`, `W`, `D` — the full list is in `/race/08`) are printed once for the
  front pair and once for the real pair (`SS` above and below in the annotated figure; `RH` in the MFD capture).
  Bar colour semantics: **white = healthy → red = worn**; the outer frame around the four tyres reddens with tyre
  temperature; suspension and engine damage are highlighted red (`/race/02`, `/race/06`).
* **Surface water indicator** `[OBS]`: a thin vertical bar with **4 horizontal tick divisions** and a tyre/water
  pictogram, at the left of the tyre widget; length of fill = wetness (`/race/02`).
* **Fuel representation** `[OBS]`: two places — the **E–F arc inside the left (speedometer) dial** as the
  instantaneous level, and the **MFD Fuel Map page**'s `Remain Laps` / `Fuel %` panels (`7.0` laps, `98 %` in the
  capture) for strategy. `/race/02` notes the fuel meter is only shown for races with fuel consumption activated.

---

## 3. Data Logger (Spec III, 2025-12-03)

### 3.1 What it is and what it can load

* `[MANUAL /datalogger/01]` *"The Data Logger breaks down your race data in **Time Trial and Drift Trial replays**,
  turning every input and movement into clear graphs and figures. Whether it's your own post-race session, a saved
  run, an online player's shared replay, or data from the top drivers in the rankings…"*
* `[NEWS]` *"it's best to compare two sets of data rather than reviewing a single run on its own. You can load your
  personal best laps, or download replay data from the fastest players in the online rankings."*
* `[NEWS]` **Three views** exist: *"The examples above use 'View 1'… 'View 2' displays inputs such as throttle and
  brake alongside lateral Gs and other metrics, while 'View 3' highlights information like speed and engine RPM."*
* `[GTP]` *"There's options for different views, comprising a two-pane view and two different three-pane views. In
  all three views, there's a raw speed trace along the length of the lap in the upper pane, and the left side
  permanently has a view of the car, tires, lap, circuit map, and G-meter trace."*
* History `[GT6]`: the ancestor (GT6 "Data Logger") had one graph area with `Preset`/`Set 1`/`Set 2`/`Set 3` tabs,
  **nine** selectable data types, a playback head, a track map and a G-meter, and compared a *current slot* against
  a *reference slot* — the same current/reference idea GT7 expresses as **Slot A / Slot B**. GT6 loaded only
  **best-lap replays** ≤ 20 minutes; GT7 selects a specific lap from a replay instead.

### 3.2 The permanent left column (identical in all three views)

Top to bottom `[OBS]`:

1. **Slot A card.** Rounded-rect card with a **1 px cyan accent border** and a faint cyan-tinted fill
   (`≈#3B5661` over dark `[PX]`). Contents: a header row — the **replay/event name** (e.g. `Time Trial`) in white
   bold, left, and a **≡ (hamburger) button**, right; then a row with **two circular white-outlined badges holding
   the tyre compound initials** (front and rear, e.g. `SH` `SH`, `RH` `RH`) at the left and a **car thumbnail**
   (3/4 view) at the right; then the **car name** bottom-right in white bold (e.g. `Roadster Touring Car`,
   `Skyline Super Silhouette '84`, `Eunos Roadster (NA) '89`).
2. **Slot A lap bar.** A separate full-width bar, **solid cyan** `#4DC3F3 [PX]`, with **black** text: `Lap 2/2` on
   the left and the lap time in large black numerals on the right (`1:04.261`), plus a small ≡ button. This is
   "Slot A – Change Lap" `[MANUAL]`.
3. **Slot B card / Slot B lap bar.** Identical structure, but the accent is **yellow/gold `#E7CB3C`** `[PX]` and
   the lap bar is a **solid yellow** bar with black text (`Lap 1/1` `1:03.393`).
4. **Track map panel.** Caption = circuit name (`Tsukuba Circuit`, `Kyoto Driving Park - Yamagiwa`). The circuit is
   drawn as a thin **double grey/white line** (both track edges) on the dark panel, with a faint square grid
   behind it and a small **circular position marker** (cyan fill, dark ring, white centre dot observed).
   A 1 px light border and rounded corners frame the panel.
5. **"Centripetal Acceleration" panel** — the G–G diagram. A **polar plot**: concentric thin-grey circles plus
   horizontal/vertical cross-hairs. The circles are **labelled along the horizontal axis** — `0.5`, `1.0` in the
   reference captures, and `1.5`/`2.0` where the scale is larger, so the ring spacing is **0.5 g** with the outer
   ring at the axis maximum (≈1.5 g or 2.0 g). Each slot's samples are drawn as a **dense cloud of small square
   points**: cyan for slot A, yellow for slot B. A **legend of two `+` crosses (one cyan, one yellow)** at the
   bottom of the panel marks each slot's **current** position. Panel title in a grey rounded pill.
6. **Far-left vertical icon strip** `[OBS]`: from the top, a **pointer/arrow** icon, a **list** icon (four
   horizontal bars), a **layout/columns** icon (two small squares); then, at the bottom of the strip, a **`?` in a
   circle** button and a **red square button with a white running-figure icon**. The manual's own legend for this
   screen numbers eight numbered items (see §3.6) — the strip is where "Guidance" and "Exit" live `[MANUAL]`, but
   the figure's numbered markers are drawn on the page image, so the exact icon↔function pairing is unverified
   (§7).

### 3.3 The three views and their panes

**View 1 — two panes** (`gt7-data-logger-view1-speed-gap.jpg`, `…-downforce-compare.jpg`)

* Upper pane, full width: **`Speed and Gap`**.
* Lower pane, full width (the whole bottom half): **`Driving Line`** — a rendered road view (see §3.5).

**View 2 — three panes stacked** (`gt7-data-logger-view2-throttle-rpm.jpg`)

* Pane 1, full width: **`Speed and Gap`**.
* Pane 2: **`Throttle`** — a two-state square-wave trace (0 % / 100 % with near-vertical edges), traced twice.
* Pane 3: **`RPM`** — a continuous trace, two lines.
* Panes 2 and 3 each carry a **≡ button** in the title area → the trace shown is **selectable** (`[GTP]`:
  *"two additional traces, each of which looks to be customizable judging by the hamburger button"*). The news
  capture of the same view shows throttle **and brake** plus lateral Gs, confirming the slots are user-chosen.

**View 3 — three panes, two side by side** (`gt7-data-logger-view3-speed-rpm-drivingline.jpg`)

* Pane 1, full width: **`Speed and Gap`**.
* Pane 2, left half: **`Speed and RPM`** — a **scatter plot** with **speed on the x-axis and rpm on the y-axis**,
  i.e. a gear-ratio chart; the point cloud is drawn per slot (cyan and yellow).
* Pane 3, right half: **`Driving Line`** — the road view, here a close-up of one corner.

### 3.4 Axes, units and ranges

| Element | Value | Class |
|---|---|---|
| x-axis unit | **Distance along the lap**, in **metres** in metric locales (`0, 500, 1000, 2000, 3000, 4000`) and **miles** in US locale (`0, 0.25, 0.5, 0.75, 1.0, 1.25`) | `[OBS]` |
| x-axis form | A **solid mid-grey strip** (`#4B4B4B [PX]`) along the bottom of each pane, white tick labels sitting inside the strip; a thin vertical gridline at each labelled tick. Labels every 500 m / 0.25 mi | `[OBS][PX]` |
| y-axis form | Right-hand axis per pane, white numerals, thin horizontal gridlines; axis captions (`km/h`, `mph`, `%`, `rpm`) are **not** repeated per pane — the unit appears in the right-hand readout column | `[OBS]` |
| Speed (in `Speed and Gap`) | right axis, observed `0–200`, `0–300` (km/h) and `0–100` (mph) | `[OBS]` |
| Gap (in `Speed and Gap`) | **left** axis, origin labelled **`0.0`** with a **magenta/pink horizontal zero rule** across the pane; a positive gap plots **above** the rule, negative below | `[OBS]` |
| Throttle pane | right axis `0 … 100`, ticks every 20 (`0,20,40,60,80,100`) — percent | `[OBS]` |
| RPM pane | right axis `0 … 10000`, ticks every 2000 | `[OBS]` |
| `Speed and RPM` pane | x = speed `0 … 300` (ticks every 50), y = rpm `0 … 10000` (ticks every 2000) | `[OBS]` |
| Plot background | `#1A1C1B [PX]` (near-black, faintly green-grey); gridlines thin light grey over it | `[PX]` |
| Playback head | A **red vertical rule** crossing all panes at the current position; confirmed because its x position matches the distance readout (readout `193 m` ↔ rule ≈180–200 m; readout `266 m` ↔ rule ≈270–300 m, given the measured ≈1.0 px/m axis scale) | `[OBS]` |
| Second vertical rule | A **green vertical rule** is also present, at a different distance from the red one (≈660–730 m vs ≈180 m in one capture; ≈790–890 m vs ≈270 m in another). Its meaning could **not** be established | `[OBS]`, see §7 |
| Current-position dot | On the `Speed and Gap` speed trace a small **red dot** marks the value at the playback position; on the G–G plot the cyan/yellow `+` crosses do the same | `[OBS]` |

### 3.5 The `Driving Line` pane

`[OBS]` A rendered, overhead (or slightly oblique) view of the track around the current position:

* the **road surface** is a thick dark-grey band (`≈#3A3A3A`) with lighter grey edge lines, i.e. the track is
  drawn as a solid ribbon rather than a centre line;
* a **green dashed/zigzag line** runs along the ribbon — this is the line the header's toggle turns on and off;
* two **thin coloured lines** (cyan and yellow, one per slot) run inside the ribbon, slightly offset from each
  other — these are the two laps' racing lines;
* a small **red car marker** shows the current position of the lap being played;
* the pane header is a row of controls: a grey rounded **title pill** (`Driving Line`), a **≡ button**, a small
  **white/blue triangle** marker, an **ON/OFF toggle switch** (pill with a round white knob), and a **rounded
  button with a white car silhouette** icon (thumbnail/marker toggle).

In View 1 this pane is stretched across the full width and shows a long, flattened stretch of the lap; in View 3 it
is a half-width, zoomed, rotated view of a single corner (in the captures: a hairpin-like left-hander with the road
ribbon curving through it).

### 3.6 Comparison, alignment and on-screen controls

**Colour code for the two laps.** `[OBS][PX]` — identical hues are used for the traces, the numeric readouts, the
slot card accents and the G-plot clouds:

| Slot | Colour | Measured |
|---|---|---|
| **Slot A** | **cyan / light blue** ("blue" in the official news text, which says *"The blue line represents the slower lap"* in its example) | lap bar `#4DC3F3`; card border `#3B5661`; trace/readout ≈`#4DC3F3`, `#5FC3FF` |
| **Slot B** | **yellow / gold** | lap bar `#E7CB3C`; card border `#665D34`; trace/readout ≈`#E7CB3C`, `#FFC258` |

Errors/differences are **not** drawn in the slot colours: the gap readout is **red** (`≈#B82722 [PX]`, e.g.
`+ 0.141 sec.`, `- 0.064 sec.`) and the zero rule of the gap axis is **magenta/pink**.

**Alignment / how the two laps are compared.** `[GTP]` *"you can actually do it to two different laps and compare
them directly. This appears to function by mapping one of the laps onto the other and stretching it to fit —
regardless of lap time difference — such that the cars are positioned at the exact same point at any moment.
That allows for a precise visualization of track position and data such as speed, throttle position, gear
selection, lateral and longitudinal forces…"* `[GT6]` documents the same idea for the ancestor: when the
time-difference line is **above** the graph's `0` mark the current slot is leading, and **below** the mark the
reference slot is leading — GT7 expresses this in the `Speed and Gap` pane with its `0.0` rule and in the numeric
`Gap` readout. The **`Gap`** readout therefore = the signed time difference between the two loaded laps at the
current position of the playback head, printed with `sec.` under it. The exact sign convention in GT7 (which slot
is "positive") was **not** confirmed — in the reference captures the gap is `+0.141` in one and `-0.064` in another
while Slot A's lap is the faster of the two in one of them, so I cannot state it (§7).

**On-screen control bar.** `[OBS]` A full-width black bar along the bottom holds a row of white icon+label items,
with disabled items dimmed:

| Label observed | Icon observed |
|---|---|
| `Change View` | small figure/glyph |
| `Play/Pause` | boxed play/pause glyph |
| `Adjust Playback Position` | `L1` and `R1` key glyphs |
| `Graph/Map Scale` | `R3` key glyph |
| `Change Mode` | `△` (triangle) key glyph |
| `Reset Position` | greyed out / dimmed (disabled in the captures) |

`[MANUAL /datalogger/01]` documents **eight** numbered controls on this screen, with the button glyphs supplied as
images (so only the functions are recoverable from the text): **1 Change View · 2 Guidance · 3 Exit · 4 Slot A –
Load Replay · 5 Slot A – Change Lap · 6 Slot B – Load Replay · 7 Slot B – Change Lap · 8 Change Thumbnail.**
`[GT6]` additionally documents, for the ancestor, play/pause, a movable playback head, R1/L1 rewind/forward,
R2/L2 sector jumps, and left-stick graph scaling — GT7's bar carries `Graph/Map Scale` on `R3` and
`Adjust Playback Position` on `L1`/`R1`, so the scheme was reshuffled.

### 3.7 Right-hand numeric readout column

`[OBS][PX]` A full-height strip at the far right of the screen (in a 1920-wide frame it occupies roughly
x 0.91–1.00). Form per parameter:

```
   Speed          ← caption, small, grey
    92            ← Slot A value, large, cyan
   km/h           ← unit, small, white
   108            ← Slot B value, large, yellow
```

* The **caption** is a small grey uppercase/label word (`Speed`, `Gap`, `Throttle`, `RPM`).
* The **two values are stacked** in slot order — **Slot A on top (cyan), Slot B below (yellow)** — with the shared
  unit printed once, small and white, between them.
* Below the values, aligned with the pane's x-axis strip, a single scalar is printed on a slightly different dark
  strip: the **distance** of the playback head, e.g. **`193 m`**, **`266 m`**, **`248 m`**, or **`0.77 miles`**
  (white, centred) — this is the only *single-valued* (not per-slot) readout, alongside `Gap`.
* Values observed: `Speed 92 / 108` and `Gap +0.141 sec.` (View 1); `Speed 76 / 78`, `Gap -0.064 sec.`, `266 m`,
  `Throttle 12 % / 0 %`, `RPM 4,052 / 4,187` (View 2); `Speed 181 / 166`, `Gap -0.509 sec.`, `248 m` (news
  capture). Thousands separators are used (`4,052`).
* Colours: readout panel background `#363A45 [PX]`; the distance strip `#222632 [PX]`; cyan `≈#4DC3F3`; yellow
  `≈#E7CB3C`; `Gap` value **red**.

---

## 4. Visual language

### 4.1 Backgrounds and panels

| Surface | Colour | Class |
|---|---|---|
| Data Logger plot area / page background | `#1A1C1B` | `[PX]` |
| Data Logger left-column panel background | `#2E2E2E` | `[PX]` |
| Data Logger x-axis strip | `#4B4B4B` (mid grey, white labels inside) | `[PX]` |
| Data Logger right readout column | `#363A45` (blue-tinted dark grey) | `[PX]` |
| Data Logger distance row | `#222632` | `[PX]` |
| Data Logger/other UI chrome, bars and rules | pure `#000000` | `[PX]` |
| Race HUD cluster backplate, MFD panel | translucent near-black; sampled `≈#5E5955` over grey tarmac and `≈#29303A` over dark tarmac, i.e. roughly **`#20242C` at ~75 % opacity** — the sampled value depends entirely on the scene behind it | `[PX]` |
| Dial faces | the same translucent dark treatment; sampled `#171A1F` over dark tarmac | `[PX]` |
| Driver list / lap-time list / car-name plates (race HUD) | dark translucent plates with hairline separators | `[OBS]` |
| Panels are framed with a **1 px light border and rounded corners** (data logger cards, map panel, pane title pills) | — | `[OBS]` |

### 4.2 Colour semantics (which colour means what)

| Colour | Meaning | Evidence |
|---|---|---|
| **Cyan `#4DC3F3`** | **Slot A** everywhere in the Data Logger (card accent, lap bar, trace, numeric readout, G-plot cloud) | `[PX]` |
| **Yellow `#E7CB3C`** | **Slot B** everywhere in the Data Logger | `[PX]` |
| **Purple `#8E4DB1`** | **Best / fastest lap** in the race HUD: the `BEST` chip and delta chip in the sector-timing bar, the fastest-lap notification bar, and the fastest-lap row in the lap-time list | `[PX]` + `[MANUAL]` wording |
| **Blue with a minus sign** (race HUD) / **blue pill** (MFD delta) | **Ahead of / faster than** your reference time | `[MANUAL]` `/race/02`, `[OBS]` MFD table |
| **Red with a plus sign** (race HUD) / **red pill** (MFD delta) | **Behind / slower than** your reference time | `[MANUAL]` `/race/02`, `[OBS]` MFD table |
| **Red `/` pink-red `#FA0F0B` / `#DB557A`** | **Brake / warning / engaged / limit**: the `BRAKE` cue, the blindside arcs, the final-lap badge, the shift lamp, the rev tick strip when lit | `[PX][MANUAL]` |
| **White vs grey on assist icons** | **on** vs **off**; **red** = currently engaged | `[MANUAL]` `/race/02` |
| **White → red** on the tyre bars | **healthy → worn**; a reddening frame = tyre temperature | `[MANUAL]` `/race/02` |
| **Green** | only two uses observed: the **Fuel Map arc span** (MFD) and the **BEST row** of the Session Best table. **Not** a slot colour | `[OBS][PX]` |
| **Magenta/pink** | the **zero rule** of the Data Logger gap axis | `[OBS]` |
| **Weather-radar ramp** | light blue → blue → green → yellow-green → orange → pink | `[MANUAL]` `/race/04` |

> **Caution for anyone re-using these images.** In the publicity and manual figures, a strong browser-blue
> **`#3B81E0`** circles/boxes overlay the UI (the manual's numbered legend badges and GTPlanet's annotations).
> `#3B81E0` is **not** a GT7 UI colour — I verified its pixel hotspots coincide exactly with those annotation
> badges. Any palette extracted from the marketing figures must exclude it.

### 4.3 Line weights, shapes and typography

* **Line weights** `[OBS]`: hairlines of **1 px** (panel borders, table cell separators, the divider inside the
  speed/gear panel, the steering rule, the tick outlines); **2–3 px** for graph traces; **~10–14 px** for the
  vertical throttle/brake bars; **~6–8 px** for the road-ribbon edge lines. Gridlines are 1 px and low contrast.
* **Shapes**: rounded rectangles (radius ≈ 6–10 px at 1920 width) for all chips, pills, badges, cards and pane
  titles; the speed/gear panel is an **inverted trapezoid**; the gauge arcs are stroked circle segments; the
  Data Logger's x-axis strip is a plain rectangle; the G-plot is polar.
* **Typography** `[OBS]`: everything is a **sans-serif/technical** face. Two distinct roles:
  (a) a **squared, slanted, LED/segment-style digit face with hairline gaps between digit cells** used for all
  *time and speed/gear numerals* (the race HUD's `124`, `4`, `0:09.500`, `2'46.633`); it is wide, tabular and
  genuinely monospaced-looking;
  (b) a **neutral humanist sans** for labels, names, list rows, panel captions, table cells and the Data Logger
  readouts. The Data Logger uses (b) for nearly everything and reserves a condensed technical style for the lap
  time in the slot bars.
* **Emphasis pattern** `[OBS]`: *small grey caption above, large value below* is the repeated idiom (right readout
  column, MFD Fuel Map's `Remain Laps 7.0` / `Fuel 98%`).
* **Depth**: no drop shadows anywhere; separation is achieved with translucency, 1 px light borders and hairline
  cell rules only. Light-on-dark throughout; nothing in either screen is light-mode.

---

## 5. Reference file inventory — `docs/reference/gt7/`

| File | What it shows (one line) | Class |
|---|---|---|
| `gt7-race-screen-annotated.jpg` | Official manual figure for `/race/02` "The Race Screen" — the 25-element HUD legend in Normal view, with blue numbered badges; **pixel-identical to the manual's `i1B1lEMx5qJnOb.png`** | `[MANUAL-IMG]` |
| `gt7-race-hud-normal-view.jpg` | A real Normal-view race screen (Audi R8 LMS at speed, 20-car race, lap 1/20): full HUD with driver list, lap-time list, track map, cluster, `Course Map` MFD page | `[OBS]` |
| `gt7-chase-view.jpg` | Real **Chase-view** race screen with the complete HUD; shows the cluster as a wide dark band with the `Course Map` MFD at the bottom-right and the floating car-name labels above rival cars | `[OBS]` |
| `gt7-cockpit-view.jpg` | Real **Cockpit-view** race screen; shows that the same HUD is drawn but the cluster is partly occluded by the steering wheel and dashboard | `[OBS]` |
| `gt7-mfd-session-best.jpg` | Instrument cluster with the MFD on its **Session Best** page: the 6-row sector/`LAST`/`BEST`/`OPT.` table with red/blue delta pills, a fully lit pink rev tick strip, and the red shift lamp beside the gear | `[OBS]` |
| `gt7-mfd-fuel-map.jpg` | Instrument cluster with the MFD on the **Fuel Map** page: the `POWER`–`LEAN` green arc with a white pointer, `Remain Laps 7.0` / `Fuel 98%` panels — and the clearest view of the complete cluster (speedo with E–F fuel arc + odometer, tach with the `×1000 kPa` boost sub-gauge, tyre widget, assist icons) | `[OBS]` |
| `gt7-data-logger.jpg` | Official manual figure for `/datalogger/01` — the whole Data Logger screen (View 1) with eight blue numbered markers = the eight documented on-screen controls; **byte-identical to the manual's `i1OtyKTbY3tlvuB.jpg`** | `[MANUAL-IMG]` |
| `gt7-data-logger-hero.jpg` | Marketing title card *"Spec III New Feature — How to Use 'Data Logger'"* over a View 1 capture (Eunos Roadster NA '89 vs Roadster S ND '15 at Tsukuba, mph/miles units, `Gap +3.953 sec.`) | `[OBS]` |
| `gt7-data-logger-view1-speed-gap.jpg` | **View 1** (two panes) at Tsukuba with GTPlanet's A–E annotations: `Speed and Gap` over the full-width `Driving Line` pane; shows the slot cards, circuit map, Centripetal Acceleration plot, right readout column (`92 / 108 km/h`, `Gap +0.141 sec.`, `193 m`) | `[OBS]` |
| `gt7-data-logger-view1-downforce-compare.jpg` | **View 1** again for the car-setup comparison (Skyline Super Silhouette '84, `Lap 1/1 0:56.427` vs `Lap 1/2 0:56.988`), with A–C annotations on a zoomed hairpin — the clearest view of the `Driving Line` road ribbon, the green dashed line, the per-slot coloured lines and the red car marker | `[OBS]` |
| `gt7-data-logger-view2-throttle-rpm.jpg` | **View 2** (three stacked panes): `Speed and Gap`, `Throttle`, `RPM`; readout column `Speed 76/78`, `Gap -0.064 sec.`, `266 m`, `Throttle 12 %/0 %`, `RPM 4,052/4,187` | `[OBS]` |
| `gt7-data-logger-view3-speed-rpm-drivingline.jpg` | **View 3** (three panes, two side by side): `Speed and Gap` across the top, the `Speed and RPM` scatter on the left (x = speed 0–300, y = rpm 0–10000) and the `Driving Line` close-up on the right | `[OBS]` |

All twelve are 1920×1080 except the two MFD captures, which are 1920×800 club-cluster crops.

---

## 6. Sources

Fetched directly (all URLs verified working during this research):

1. GT7 online manual, table of contents (JSON):
   `https://www.gran-turismo.com/us/gt7/api/manual/`
2. `/race/02` The Race Screen — the 25-element legend:
   `https://www.gran-turismo.com/us/gt7/api/manual/?u=/race/02`
   (rendered: `https://www.gran-turismo.com/us/gt7/manual/race/02`; figure `https://www.gran-turismo.com/images/c/i1B1lEMx5qJnOb.png`)
3. `/race/03` Racing Views:
   `https://www.gran-turismo.com/us/gt7/api/manual/?u=/race/03`
4. `/race/04` The Multi-Function Display (7 pages + Session Best layout list):
   `https://www.gran-turismo.com/us/gt7/api/manual/?u=/race/04`
5. `/race/06` Mechanical Damage (tyre-area red highlighting):
   `https://www.gran-turismo.com/us/gt7/api/manual/?u=/race/06`
6. `/race/08` Tires (compound initials CH/CM/CS, SH/SM/SS, RH/RM/RS, IM, W, D):
   `https://www.gran-turismo.com/us/gt7/api/manual/?u=/race/08`
7. `/drivingoption/05` Display Settings (Show Race Info, Show Drivers List, Car Name Indicator, …):
   `https://www.gran-turismo.com/us/gt7/api/manual/?u=/drivingoption/05`
8. `/datalogger/01` What is the Data Logger? (scope: Time Trial & Drift Trial replays; the eight controls):
   `https://www.gran-turismo.com/us/gt7/api/manual/?u=/datalogger/01`
   (figure `https://www.gran-turismo.com/images/c/i1OtyKTbY3tlvuB.jpg`)
9. Official Polyphony news post, 2025-12-03, "Introducing the New Data Logger Feature!" — names View 1/2/3, the
   blue-is-slower-lap example, and the alignment/tuning use cases:
   `https://www.gran-turismo.com/us/news/00_5736734.html`
10. GTPlanet, 2025-11-10, "Gran Turismo 7 Spec III's Data Logger Shown in Action" — the pane structure
    (two-pane + two three-pane views), the permanent left column, the stretch-to-align comparison, the
    configurable traces:
    `https://www.gtplanet.net/gt7-spec-iii-data-logger-20251110/`
11. GT6 manual, "Data Logger" (ancestor: Preset/Set 1–3 tabs, nine selectable data types, playback head, track map,
    G-meter, current vs reference slot, best-lap-only replays ≤20 min):
    `http://www.gran-turismo.com/us/gt6/manual/howtorace/datalogger.html`
12. GT6 manual, "Using the Data Logger" (ancestor: time-difference line above `0` = current slot leads; yellow vs
    blue lines; graph scaling with the left stick):
    `http://www.gran-turismo.com/us/gt6/manual/howtorace/datalogger_howtouse.html`

Local evidence: the twelve images in `docs/reference/gt7/` (§5), inspected directly (full view **and** cropped
zooms) and measured with PIL for colours.

---

## 7. Unverified / could not confirm

1. **Meaning of the glyph inside the lit shift lamp.** The lamp itself is confirmed (`/race/02` describes a shift
   indicator that lights up near the red zone; unlit it is an empty dark rounded box in the same slot). But the
   **glyph inside** it reads `1` in the Session Best capture (gear 5, MT) and `2` in the manual figure (gear 4,
   MT). I could not find any source explaining what that digit means. Do **not** assume it is the gear number or
   the next gear.
2. **The green vertical rule in the Data Logger graph panes.** It is clearly present in every capture (panes and
   view variants), but no source in §6 mentions it, and I could not derive its meaning from position. The **red**
   rule *is* confirmed as the playback position (its x matches the `193 m` / `266 m` distance readout).
3. **Sign convention of the Data Logger `Gap` readout.** Which slot makes the gap positive is not documented and
   my two captures (`+0.141`, `-0.064`) do not disambiguate it. (For the *race HUD* the sign convention **is**
   documented: blue/minus = better, red/plus = worse.)
4. **MFD page-dot count and dot↔page mapping.** The manual's MFD legend numbers **6** features (a 7th, Session
   Best, is described separately), and the reference captures show a row of roughly 6–7 small dots; in the
   Session Best capture the lit dot is not the last one. Because page availability depends on installed parts
   (Brake Controller, Fully Customizable Computer), I could not pin the count or mapping down.
5. **Which function each of the eight Data Logger controls is bound to.** `/datalogger/01` supplies the eight
   *functions* as text but renders the button glyphs as images; the bottom control bar in the captures carries six
   *different* labels (`Change View`, `Play/Pause`, `Adjust Playback Position`, `Graph/Map Scale`, `Change Mode`,
   `Reset Position`). The pairing between the manual's eight functions and the on-screen buttons is not resolved.
6. **The exact role of each icon in the far-left vertical strip** (pointer, list, layout, `?`, red running-figure
   button). The red figure button may be "Exit" or "Guidance" — unverified.
7. **The unlabelled small readout under the track map** (`↓ 7.8 ft/s` in the US locale, seen in both the
   normal-view and chase-view captures). It is a velocity in `ft/s` (or its metric equivalent) with a downward
   arrow and a small icon; I could not identify what it measures. It is **not** one of the 25 documented elements.
8. **Whether the rev tick strip along the top of the digital panel and the shift lamp are the same indicator or two
   indicators.** The manual describes only one ("the shift indicator"), positioned below the steering dot; the
   strip lights pink-red (`#DB557A`) across the panel top while the lamp lights `#FA0F0B` beside the gear. I could
   not confirm whether they are one two-part indicator or two separate ones.
9. **Exact red/blue delta pill fills in the MFD Session Best table.** Red and blue are unmistakable and loss/gain
   is certain, but the sampled fills (`≈#7A2A1E`, `≈#2F4C6C`) come from small, JPEG-compressed regions and should
   be treated as approximate.
10. **Tachometer redline extents.** The band's visible extent differs strongly between captures (a short segment at
    the top of the scale vs almost the whole arc). It is certainly car-dependent, but I could not verify the exact
    rule (per-car redline rpm) — nor whether the whole ring is a "lit revs" indicator rather than a redline band.
11. **Whether the speedometer dial ever shows a redline/marking.** None was seen in any capture.
12. **Exact per-element pixel positions of the race HUD.** Positions in §1 were read from the manual's annotated
    figure and the two real screenshots; the HUD is drawn over the scene and shifts with aspect ratio, safe-area
    and display settings, so treat them as approximate fractions, not fixed layout constants.
13. **Data Logger availability/behaviour in the PS4 version.** All sources are version-agnostic; I found no
    PS4-vs-PS5 difference documented for either the HUD or the Data Logger, but I did not verify it.
