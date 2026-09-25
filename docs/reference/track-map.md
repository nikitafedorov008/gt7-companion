# Track map — drawing the driven route from the packet coordinates

Written 2026-09-23, after the `CarPlate` work and the "can we draw a route like
navigation?" question.

## 1. Short answer

Yes, and it is already implemented. GT7's packet "A" carries the car's position
in metres 60 times a second, so the HUD accumulates those positions and draws
the route. Nothing has to be downloaded: the map is *built by driving*, which
also means it is the only source of course geometry available to us.

What is **not** possible with the UDP feed: opponents (the packet describes only
the player's car), and therefore no radar, no gaps to rivals on a map, no course
outline before the first lap.

## 2. Where the coordinates are in the packet

Packet "A", 296 bytes, 60 Hz. Every field we already parsed matches the
community structure exactly, which is what makes the new offsets trustworthy:

| Offset | Field | Already used by us? |
|--------|-------|---------------------|
| `0x04` | `position[3]` — X, Y, Z in metres | **new** (track map) |
| `0x10` | `worldVelocity[3]` | **new** |
| `0x1C` | `rotation[3]` — pitch, yaw, roll (normalised −1…1) | **new** |
| `0x28` | `orientationRelativeToNorth` (1.0 = north) | **new**, stored, unused |
| `0x2C` | `angularVelocity[3]` | **new** |
| `0x38` | `bodyHeight` | yes — ride height |
| `0x3C` | engine RPM | yes |
| `0x40` | `iv[4]` (Salsa20 nonce) | yes |
| `0x4C` | speed, m/s | yes |
| `0x70` … `0x8E` | packet id, lap count, lap times, position, alert RPM, flags | yes |
| `0x90` | gears (current | suggested) | yes |
| `0x91` / `0x92` | throttle / brake | yes |
| `0xA4` … `0xC0` | wheel RPS, tyre radius | yes |
| `0xF4` … `0xFC` | clutch, engagement, RPM after clutch | yes |
| `0x124` | `carCode` | yes — car name plate |

The up axis is **Y**: the ground plane is X/Z. That is how the community track
visualisers plot it (for example `newXYZ = [position.x, position.z]` in
[Bornhall/gt7telemetry `gt7trackdetect.py`](https://github.com/Bornhall/gt7telemetry/blob/main/gt7trackdetect.py)),
and the full struct is documented in
[MacManley/gt7-udp](https://github.com/MacManley/gt7-udp) ("Packet A": position,
world velocity, rotation, orientation to north, angular velocity) and in the
[Hyurt field gist](https://gist.github.com/Hyurt/7f6ba61c4af3f6ad5c86271957ab6adb)
(`(0x04,3,"FLOAT","POSITION")`, `(0x10,3,"FLOAT","VELOCITY")`).

`headingNorth` is deliberately parsed and then ignored by the map: the drawing
derives heading from the driven positions instead (`atan2(-Δz, Δx)`), which needs
no convention about how the packet normalises angles.

## 3. Implementation

| Piece | File |
|-------|------|
| Position/rotation parsing | `lib/models/telemetry/telemetry_data.dart` (`fromBytes`, `0x04…0x34`) |
| The route itself | `lib/models/telemetry/track_trace.dart` (`TrackTrace`, `TraceSample`) |
| Keeping it current | `lib/repositories/track_repository.dart` (`TrackTraceRepository`) |
| Drawing | `lib/widgets/telemetry/track_map.dart` (`TrackMap`, `_TrackMapPainter`) |
| HUD page | `gt7_hud.dart` → `mfdTitles[7] = 'TRACK MAP'`, `_TrackMapPage` |
| Data view panel | `telemetry_display.dart` → `_TrackMapPanel` |

Decisions worth knowing:

* **Thinning by distance, not time.** A 2.5 m step means a 300 km/h car records
  one point per packet (~1.4 m apart at 60 Hz is *below* the step, so several
  packets collapse into one point) while a slow corner keeps its detail. One
  Nürburgring lap lands around 8 000 points instead of 25 000.
* **Session jumps.** A step larger than 500 m means a new track or a restart, so
  the trace clears instead of drawing a line across the world.
* **Zeros are not a position.** The packet reports `(0, 0, 0)` before a car is
  on track; those samples are dropped.
* **Caching.** Paths and the speed-band point lists are rebuilt only when
  `TrackTrace.revision` changes (a new point or a clear), never per frame. The
  painter's transform is a `Matrix4` applied to a canvas, so the cached geometry
  is resolution independent.
* **Colour = speed.** Five bands (60/120/180/250 km/h) drawn as `PointMode.lines`
  pairs, with a dim flat stroke underneath so the line stays continuous.
* **Two views, one button.** `HEADING UP` is the navigator: the car sits low in
  the panel (62% height, so the road ahead has room), its direction of travel
  points straight up, and the road is magnified by `headingUpZoom` (2.6x).
  `NORTH UP` is the flat plan of the whole circuit, which is the better shape to
  read a lap from.
* **The navigator view is tipped away from the camera.** `tilt` rotates the
  ground plane about the screen's horizontal axis (43 degrees), so the far side
  of the circuit is foreshortened by `cos(tilt)` and shrunk by a little
  perspective (`setEntry(3, 2, …)`), with a gradient shade over the far half.
  This is done as a *world* rotation about the car (`spin`) followed by the
  camera tilt, not as a rotation of the finished picture: turning the picture
  would spin the horizon instead of the map. The flat plan keeps `tilt: 0`.
* The map mode the data view opens in can be set for screenshots and demos:
  `flutter run -d macos --dart-define=GT7_MAP=heading`.

## 4. The demo circuit

Without a PlayStation there is nothing to draw, so `TelemetryService`'s demo
feed drives a fictional ~3 km loop defined in `_DemoCircuit` (a Catmull-Rom
spline through 15 control points, corner speeds from `v = sqrt(a_lat / k)`).
The demo ticks at 10 Hz, so the map, the speed colours and the lap counter all
move exactly as they do with a real session.

## 5. Verification

* `test/track_trace_test.dart` — thinning, extents, session jump, lap counting
  and heading (7 tests) plus a synthetic 296-byte packet that proves the parser
  reads `0x04`/`0x08`/`0x0C`/`0x1C`/`0x20`/`0x28`.
* Screenshots: `output/design/trackmap_mfd.png` (HUD TRACK MAP page),
  `output/design/map_north_up.png` (data view, the flat plan),
  `output/design/navigator_final.png` (navigator: tipped plane, car centred low,
  heading up, 2.6x).
* `flutter analyze lib` → 0 errors; `flutter test` → all suites pass.

## 5a. The circuit is named from the lap, not from the packet

GT7's packet has **no track id** - the community asked for years and Polyphony
never added one (Nenkai confirmed no further packet modes as of 1.68). The only
route to "which circuit am I on" is to measure the lap and look it up:

| Piece | File |
|-------|------|
| The course database (111 circuits) | `assets/tracks/tracks.json`, built by `tools/fetch_gt7_tracks.py` from ddm999/gt7info's `course.csv` |
| The measurement | `TrackTrace.lapSignature` - lap length in metres, elevation span, and a corner count taken from the curvature of the line |
| The lookup | `lib/repositories/track_catalog.dart` (`TrackCatalog.identify`) |
| Where it shows | the TRACK MAP caption (`telemetry_display.dart`) |

Scoring is deliberately strict: the length must be within 6%, the elevation and
corner count are weighted in when the database has them, and a 15% penalty
rejects the lap outright. If a second circuit fits within 3% of the best one the
caption says so (`ALSO FITS …`) rather than picking a winner - two layouts of one
circuit, or two circuits of similar length, are genuinely indistinguishable from
a single lap of coordinates. **This is inference, not telemetry**, so it only
ever speaks when the evidence is strong, and the demo feed (a fictional loop)
suppresses it entirely.

## 5b. Fuel per lap is the one honest strategy number

`0x44` is the fuel level, so consumption is arithmetic rather than a guess:

* `TrackTrace` closes a lap when the packet's lap counter changes, recording the
  distance covered and the fuel burned (`lastLapFuel`, median of the last five
  laps as `fuelPerLap`, and `lapsRemaining` from the current level).
* Laps that show a *gain* (a refuel, a reset) are dropped instead of averaged.
* The HUD's STINT page reads that shared measurement - it used to run its own
  250 ms timer duplicating the same arithmetic, which is why the numbers could
  disagree between views.

Tyre wear and compound are **not** available anywhere in the packet, so no
widget pretends to show them.

## 5c. The ghost lap, the live delta and the elevation profile

Three things the packet supports that the game's own HUD does not show:

* **Ghost lap.** `TrackTrace` records every closed lap's sample range and its
  duration (from the packet's `lastLapTime`), so the fastest lap of the session
  can be drawn under the current one in the HUD's purple (`TrackMap.showGhost`).
* **Live delta.** `TrackTrace.deltaToBest()` compares the current lap with the
  fastest one **at the same distance**, interpolating the best lap's clock. That
  is what a driver actually wants and it needs no reference data: it is this
  session against itself. The HUD's header chip says `LIVE` when the number comes
  from this computation rather than from `lastLapTime - bestLapTime`.
  The lap clock itself comes from packet `C` (`0x15C`) when it is available -
  timing laps off the host clock drifts against the console.
* **Elevation profile** (`lib/widgets/telemetry/elevation_profile.dart`): the
  fastest lap's `position.y` drawn against distance, with the range in metres.
  Available in the data view and as the HUD's ELEVATION page.

## 5d. Shape matching: why it is not here

The obvious upgrade to the track lookup is to match the *shape* of the lap, not
just its length. I went looking for circuit outlines and found none that can be
used: the official track list ships **badges**, not maps
(`/common/dist/gt7/tracklist/assets/<hash>.png` is a 400x200 canvas with a small
logo in the corner - verified by fetching and inspecting one), and the community
databases (`gt7info/course.csv`) carry only metadata: length, elevation,
corners, longest straight. Without outlines there is nothing to match a driven
contour against, so the lookup stays on measurements that exist.

The route to shape matching that *would* work is self-learning: when the
metadata match is confident, store the lap's normalised contour and match
against stored contours next time - the app would then distinguish two layouts
of the same circuit by shape alone. That is designed but not built.

## 6. Still open

* No per-lap colouring of the *reference* lap: the trace knows lap numbers, and
  the packet gives `bestLapTime`/`lastLapTime`, so a "ghost of the best lap"
  overlay is a natural next step.
* No sector markers, no distance-to-line readout, no corner names (GT7 sends no
  sector boundaries).
* The map is 2D: overpasses cross. `position.y` is stored, so an elevation
  profile (or a 3D view) is possible.
