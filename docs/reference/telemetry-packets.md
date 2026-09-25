# GT7 telemetry packets: what the console sends, and how to ask for more

Written 2026-09-23, answering "can we tell which way the car is turned?".

## 1. Short answer

* **Which way the car is pointing** is in the base packet `A`: `rotation[3]`
  (pitch/yaw/roll, normalised) at `0x1C`/`0x20`/`0x24`, plus
  `orientationRelativeToNorth` at `0x28`. We decode all four; the track map
  draws its car arrow from the driven positions instead, because that needs no
  convention, but the yaw is there if we want the needle.
* **Which way the wheels are turned** is *not* in packet `A`. GT7 sends it only
  when the heartbeat asks for packet `B` (or `C`), where a motion block at
  `0x128` carries the steering angle and the accelerations.
* The switch is one byte: the heartbeat character. `A` → 296-byte packets,
  `B` → 316, `~` → 344, `C` → 368. Every packet is a superset of `A`, so no
  existing offset moves.

## 1a. What the 2026 survey changed

A survey of the public implementations (2026-09-23) corrected four things in
this document and found three fields we were not reading at all:

| Finding | Where it came from | What we did |
|---------|--------------------|-------------|
| The nonce XOR is **per format**: `A` = `0xDEADBEAF`, `B`/`C` = `0xDEADBEEF`, `~` = `0x55FABB4F` | `GT7UDPParser.cpp`, `PDTools SimulatorInterfaceClient.cs`, `gt7-telemetry-relay` | `CryptoUtils.nonceXor`; before this, asking for `B` would have produced garbage |
| `C` extends **`~`**, not `B` (`struct PacketC : public PacketTilda`) | `MacManley/gt7-udp` | this is what makes 296/316/344/368 add up, and it gives the C offsets below |
| `0x1C..0x2B` may be a **unit quaternion** (x,y,z,w) rather than pitch/yaw/roll + heading | PDTools ("change rotation type to quaternion"), community packet sheet | detected at runtime by checking `x²+y²+z²+w² ≈ 1`; when it holds, the body angle is exact and the drift fit is skipped |
| The format can only be changed by **letting the connection lapse** - the first heartbeat wins | SHWotever, `gt7-telemetry-relay` | switching the packet type now silences heartbeats for 3 s |

Fields we now read that we did not before: `0x13C` throttle *before* TCS,
`0x13D` brake *before* ABS, `0x13E` drivetrain/torque-vectoring flag, `0x13F`
energy-recovery flag, `0x158` per-wheel surface, `0x15C` the live lap clock,
`0x160`/`0x164` front wheel angles, `0x168` dynamic left wheelbase, `0x16C`
car category.

Two more notes worth keeping: `0xD4..0xF3` are **reserved** (four independent
sources agree nothing has ever populated them - stop looking), and `0x124`
`carCode` is overwritten by cars with 9+ gears because the game copies the gear
ratios without a bounds check (an LC500 also overwrites `0x128`, which in `B`
and up is the steering angle).

## 2. The four packets

| Heartbeat | Size | What it adds | Source |
|-----------|------|--------------|--------|
| `A` | 296 | position, velocity, rotation, orientation to north, angular velocity, RPM, speed, lap times, gears, throttle/brake, tyres, car code | [MacManley/gt7-udp](https://github.com/MacManley/gt7-udp) |
| `B` | 316 | + `wheelRotation` (`0x128`), `steeringAngularVelocity` (0x12C), `sway` (0x130), `heave` (0x134), `surge` (0x138) | same, and [RaceCrewAI/gt-telem](https://github.com/RaceCrewAI/gt-telem) ("the GUI uses heartbeat B to access motion data **including steering wheel rotation**") |
| `~` | 344 | + filtered throttle/brake, torque vectors, energy recovery | MacManley |
| `C` | 368 | + `surfaceType[4]` (per tyre: T/C/D/G/S/s), lap time in ms, `wheelSteeringAngle[2]`, `wheelBase`, `carCategory[4]` | MacManley |

Caveats from the documentation itself: `B` is not available in Sport Mode
(corroborated by two independent reports), `~` is not available in replays (one
source disputes this and says replay data is merely aliased). **`C` carries no
such note, which is why it is the recommended heartbeat**: it has everything
`B` and `~` have plus the car's own geometry.

Also operational, and easy to trip over: **only one consumer can hold the
connection and the first heartbeat wins**, so if SimHub or another app has the
stream we get nothing until it stops. The per-format XOR means two apps asking
for different formats cannot share one stream.

**Why we do not parse the `C`-only fields yet.** The published struct for `C`
(`struct PacketC : public PacketB`) lists only 24 bytes of additions, which
would make it 340 bytes — but the packet is 368. There is a block the document
does not describe, so the offsets of `wheelSteeringAngle`, `wheelBase` and
`carCategory` cannot be trusted without capturing a real `C` packet and locating
them by their ASCII (`"GR3\0"`, `"TTTT"`) and physical ranges. Guessing them
would be worse than not having them; the motion block, which is fully described,
is parsed.

## 3. What we implemented

| Piece | File |
|-------|------|
| Heartbeat character (`A`/`B`/`C`), documented | `lib/services/udp_service.dart` (`packetType`) |
| Switching it, with a reason for each | `lib/services/telemetry_service.dart` (`packetType` setter), UI in `lib/widgets/telemetry/telemetry_panel.dart` |
| Motion block parsing | `lib/models/telemetry/telemetry_data.dart` (`0x128`…`0x138`, guarded by packet length) |
| The readout: steering bar + lateral/longitudinal g | `lib/widgets/telemetry/motion_panel.dart`; HUD page `mfdTitles[8] = 'MOTION'`, data-view card |
| Demo values so it can be seen without a console | `_DemoCircuit.curvatureAt` → steering `atan(k·L)`, lateral g `v²·k` |

Design notes:

* Absent motion data is **NaN**, not `0.0`, so the UI prints `—` and explains
  that packet `A` has no steering, instead of inventing a centred wheel.
* The steering field is documented as "wheel rotation"; since it is the only
  steering channel in the packet and the gt-telem GUI uses exactly this packet
  for "steering wheel rotation", we accept it but reject values outside
  ±3.2 rad as "not steering data" — a rolling-wheel counter would be unbounded
  and would fail that check instead of drawing nonsense.
* `packetType` is derived from the received length, so the UI can say which
  packet the numbers came from.
* The demo answers `B`, so the panel is not empty in demo mode.

## 3a. The load dial: a small 3D renderer, not a drawing

`lib/widgets/telemetry/g_force_ball.dart` is the round load indicator, and
`car_model_3d.dart` is the car inside it. The car is not an icon: it is a
sixteen-vertex model (three body boxes and four wheel boxes) whose faces carry
normals and get shaded by a light, projected through an orthographic camera
**24 degrees above the horizon** - behind the car and slightly above it, the
chase angle racing games use - and painted back to front. That is what makes the
attitude honest:

* the body rotates by the **measured** roll and pitch - the quaternion's own
  axes (`bodyRollRadians`, `bodyPitchRadians`), not a guess from the g-forces;
* the wheels are a separate group that takes the yaw and the steering angle but
  never the lean, because a body rolls on its springs while the tyres stay flat
  on the road;
* when the packet has no quaternion the lean falls back to the load, which is
  the direction a car rolls anyway, and the readouts say `NOT IN THIS PACKET`.

The car is drawn as a **glass shell**: back faces are kept and faded instead of
being culled, each face is filled semi-transparently, and the edges are stroked
light, so the dial's grid shows through the body and the volume reads from its
outline. The load itself is the sphere - `sway` and `surge` from packet `B` and
up - with its recent path trailing behind it and the session's peaks marked on
the axes.

The body is not a box any more: each part is an extrusion built from two
outlines (a rounded rectangle at the bottom, a tapered one at the top, plus a
shoulder shell and a rear wing), and the wheels are cylinders lying on the car's
lateral axis. Same renderer, same shading - just shapes that read as a car. The
face normal of a tapered quad is approximated by its centroid, which is the
trade a miniature renderer makes at a hundred pixels.

Two things about those outlines are worth writing down, because both were wrong
first and both are invisible in a still frame until you know what to look for:

* **A corner arc has to sweep the quadrant that faces away from the shape.** The
  front-right corner runs from the nose round to the right flank; sweeping the
  inward quadrant instead leaves every edge dished inwards, and a car whose nose
  and tail are concave reads as a tent over a tub rather than as a body.
* **The body is narrower than the track** (1.66 m against tyres centred at
  ±0.80 m). With the body wider than the wheels the tyres disappear underneath
  it from any camera above the car, which is most of the dial's view - and a
  surface colour painted on an invisible tyre tells the driver nothing.

### The surface, drawn on the car

Packet `C` reports one surface letter per wheel (`0x158`). Those letters belong
to the wheels, so they are shown **on** the wheels in two places: the tyre tiles
in the `TYRES & VEHICLE` card name the surface of each corner (and the tile
takes the warning colour when that wheel is off the racing surface), and the car
on the load dial carries the same information on itself:

* each **tyre takes the colour of the ground under it** - `Color.lerp` from the
  tyre's own near-black towards the surface colour, lit harder than a plain tyre
  so the tint reads at dial size (a tyre at its usual shade comes out a muddy
  maroon nobody can read);
* each wheel also gets a **contact patch on the road**: the tyre's footprint,
  turned with the steering angle, filled with the surface colour. If every wheel
  is on tarmac nothing is drawn at all, because "all four on tarmac" is not
  information;
* the patches are painted **before** the car. Drawing their outlines afterwards
  makes them float over the glass body and read as if they were on the roof. The
  front wheels are partly hidden behind the body from the dial's camera, so
  their patch is seen through the shell - dimmer, but in the right place;
* the camera angle is part of this too. At 30 degrees above the horizon the
  tyres disappear under the body and only their tops show; 24 degrees keeps the
  rear-3/4 reading while letting the front tyres, and therefore their colour, be
  seen. The floor grid's vertical squash is `sin(tilt)` for the same reason the
  camera is tilted at all - a ground distance projects as `sin(tilt)`, so the two
  are the same number twice and have to be changed together.

`surface_codes.dart` is the single vocabulary for this - the colour, the word,
and what counts as off track - shared by the tyre tiles and the tyres painted on
the car, so the two can never disagree about what a letter means. Tarmac is the
HUD's normal text colour there (`TARMAC` has to be *readable* as text) and `null`
in `gt7WheelSurfaceColours` (a tyre on tarmac is not tinted): the same idea in two
places, which is why the second function exists rather than the first returning a
near-black that vanishes as text.

There used to be a fifth place: a row of `FL/FR/RL/RR` chips in the motion
readouts, beside the dial. It said the same thing as the tyre tiles, one panel
away from them, and it is gone - a surface belongs to a wheel, and the wheel is
on screen.

`test/wheel_surface_tint_test.dart` checks this against pixels rather than
geometry - it paints the car with and without tints and counts coloured pixels,
per wheel - because "the colour reaches the canvas at all" is not something a
projection test can prove.

### The wheelbase, drawn on the car

Packet `C` reports the distance between the axles down the car's left-hand side
(`0x168`). It is drawn **in the dial**: a dimension line along the right flank
with a tick at each axle, and `WHEELBASE 2.60 m` beside it - the classic way a
drawing states a measurement, and the number only means anything next to the car
it describes.

Three things about it are deliberate:

* **it is drawn on the right flank, although the number is the left-hand one.**
  The car is viewed from behind and slightly to its left, so the right flank is
  the side facing the camera: drawn on the left the line sat behind the body.
  Both sides were measured against the car's own mask (the model rendered alone,
  in the same projection) and intersected with what the dimension adds - on the
  left 33 of 4828 pixels landed on the car, all of them on the front tyre's
  antialiased edge, on the right **none** do;
* **the line is 1.45 m out from the car's centre line, not 1.02 m.** The offset
  has to clear the car's *silhouette*, not its geometry: the car is yawed 18
  degrees, so the flank of a nearer point is drawn further out than a further
  one. At 1.02 m the line ran through the rear corner; at 1.22 m it still
  clipped the front tyre;
* **the label has a plate behind it.** It shares the dial with the load ball, and
  at a left-hand load the ball sits exactly on the label. Half a measurement
  covered by the thing it measures is worse than no measurement;
* **it is drawn only when the dial is at least `kGForceBallWheelbaseSize` (376 px)
  across.** The text does not scale with the dial, so on a smaller one it would
  grow out through the rim; below the threshold `MotionPanel` keeps the number in
  the readouts instead. One constant decides, so the number can never appear
  twice or vanish - `test/wheelbase_dimension_test.dart` checks both halves.

### Would Flutter Scene (`flutter_scene`) be better here?

Checked 2026-09-24 against [pub.dev](https://pub.dev/packages/flutter_scene),
[fscene.dev](https://fscene.dev/getting-started/installation/) and the
[repository](https://github.com/bdero/flutter_scene):

| | Value |
|---|---|
| Version | `0.23.0`, published 2026-08-25 (pre-1.0, 36 releases, weekly breaking changes) |
| Requires | **Flutter >= 3.47.0** (this project is on 3.38.7), Dart ^3.10.0 |
| Platforms | iOS, Android, **web** (its own WebGL2 backend, CanvasKit and Skwasm), macOS, Windows, Linux - every native one needs **Flutter GPU enabled** (`--enable-flutter-gpu`, or an `Info.plist`/manifest flag per platform; on 3.47.0 Windows/Linux releases need 3.47.1) |
| Depends on | `flutter_gpu`, `flutter_gpu_shaders`, `code_assets`, `data_assets`, `hooks` |
| Adds | a build hook (`dart run flutter_scene:init`) that converts `.glb`/`.fmat` into `.fsceneb` under `flutter_scene_generated/` |
| Gives | glTF models, PBR + image-based lighting, skinned animation, physics (rapier), an editor, custom shaders |

### Tried for real, then removed (2026-09-24)

`flutter_scene` was wired in for a day: the same dial built as real geometry
(the engine's primitives for the car, the dial, the rings and the load ball, its
studio environment for light, a perspective camera), and compared against the
hand-drawn one **on the same screen** - one dial, same size, same wrapper, same
telemetry, switched with `--dart-define=DIAL=canvas|scene|both`.

What the trial cost: Flutter **3.38.7 → 3.47.5** (Dart 3.10.7 → 3.13.4, pinned in
`.fvmrc`) plus Flutter GPU enabled for the whole app (`FLTEnableFlutterGPU` in
`macos/Runner/Info.plist`), and `flutter_scene` in the pubspec. The Flutter
upgrade itself came through cleanly and stayed: `analyze` reports 0 errors and
all 131 tests pass on it.

The load, both runs debug builds on an M1, window frontmost, `top` for the live
CPU sample and `ioreg` for device utilisation:

| Same screen, one dial | CPU | Memory | GPU (device utilisation) |
|---|---|---|---|
| Hand-drawn `CustomPainter` | **5.0%** | 549 MB | ~19-20% |
| `flutter_scene` | **21.6-21.9%** | 648 MB | ~24-25% |

Four times the CPU and about 100 MB more for the identical instrument, plus the
engine flag on for everything the app ships. (The zeros in some GPU samples are
the window losing focus - Flutter stops producing frames when it is hidden.
There is no per-frame GPU figure here: `powermetrics` needs root and the DevTools
frame profiler captures nothing for a scene, which renders off the UI thread.)

**Decision: removed.** The package, the entry point that demoed it and the engine
flag are gone; the hand-drawn dial stays, at a quarter of the CPU. The finding is
kept here because it is the argument: the engine earns its place when the view
has to be a *place* (a 3D circuit with terrain and a camera), not an instrument
four hundred pixels wide.

Verdict, now measured: **overkill for this HUD.** The indicator is a few dozen
polygons drawn by hand in Dart with no dependencies, no assets and no engine
path, at a quarter of the CPU of the engine version. It becomes the right tool the day we want a real 3D track with
terrain and a camera, a car with reflections, or many 3D objects on screen - and
that day starts with the Flutter upgrade, not with the package.

Web support is genuinely there, but note it does not rescue the *telemetry*: a
browser has no UDP socket, so a web build of this app can only ever show mock or
recorded data.

Along the way this found a real bug: the demo built its rotation quaternion
*before* `surge` was filled in, so every component was `NaN` - which silently
switched off both the drift angle and the attitude readouts. The composition now
happens after the motion block.

### The clutch on the pedal graph

`0xF4` is the clutch pedal's own position and `0xF8` is how far the clutch is
actually let in - both 0..1, both in **packet A**, the one every console answers
- so the pedal graph can draw them whatever heartbeat the session uses.
`ThrottleBrakeGraphBloc` carries them as two more series beside throttle and
brake, in percent like them: the pedal in the HUD's cyan, the clutch itself in
its yellow, so the pair reads as one control with two halves. Where the two
traces part company - pedal up, clutch still coming in - is the slip.

Three decisions worth writing down:

* **the traces are drawn only when the window has clutch in it** (more than 1%
  on any sample), and the readouts follow the same rule. Most cars are driven
  with paddles, where both fields stay at zero, and a line pinned to the axis is
  noise pretending to be data: a driver with a clutch sees four numbers and a
  driver without sees two, which is also what keeps four entries fitting the
  column the graph leaves them;
* **`clutchEngaged` may turn out to be a mirror of the pedal on a real car.**
  The demo gives it a lag, so the two traces differ there by construction - which
  is exactly why the demo proves nothing about the console. On a car whose clutch
  the game does not model (anything driven with paddles) `0xF8` may simply be
  `1 - 0xF4`, and then the yellow `ENGAGED` trace is a second line saying what the
  cyan one already said. **First job with a real capture**: drive one session
  with a manual/clutch car and compare `clutch` against `clutchEngaged` frame by
  frame (they are in packet `A`, so any heartbeat will do). If `0xF8` never leaves
  `1 - 0xF4`, delete the engaged trace and the `ENGAGED` readout - the pedal alone
  is then the whole truth;
* **the demo works a pedal**, because a paddle-shift demo would never exercise
  the trace: it presses the clutch for 0.12 s at each gear change, lets the pedal
  out over the next 0.25 s, and has the clutch itself follow with a first-order
  lag, so the two traces are visibly not one line. The first version of that logic compared the gear against
  `telemetry.currentGear` *of the packet it was building* - which starts at zero
  on every tick, so every tick looked like a shift and the pedal stayed down for
  good. `ThrottleBrakeGraphBloc`'s own test now checks both that the pedal goes
  down **and** that it comes back up, which is the shape that bug had.

### Steering and drift: one instrument, not two cards

They were two cards side by side, which left the reader comparing two pictures in
their head. They are now **one axis with two markers**:

* the **wheel** - a filled dot with the input bar behind it, in the HUD's cyan -
  at its position for full lock (2.4 rad);
* the **nose** - a ring below the line, in orange - at its position for 40
  degrees of slide;
* the **band between them** is the slip: the distance between where the wheels
  point and where the car is actually going.

The two markers are not the same unit, and the axis does not pretend they are:
each sits at its own full-scale position and the numbers are printed in degrees
beside them. What the eye compares is how far into the corner the wheels are
against how far the car has let go.

A chip reads **GRIP / OVERSTEER / UNDERSTEER / SLIDING** from the two, using the
classic heuristic: a nose turned further into the corner than the wheels is the
rear letting go, a nose turned out of it while the wheels are in is the front.
It stays at `—` until the car is sliding by more than 1.5 degrees, because below
that the two numbers are noise around zero and a verdict would be invented rather
than read.

**The signs are a convention we have not confirmed against a console.** A
positive steering angle means *left* in this app - it is how the demo models a
corner and how the car on the dial was verified - and a positive slip means the
nose is to the left of the travel. Both markers are drawn left-of-centre for a
left turn. They were not consistent before the merge: the old steering bar drew a
positive angle to the *right*, which a shared axis would have exposed as the two
markers disagreeing about a corner the car was taking cleanly. **First job with a
real capture**: steer left and check that both markers go left; if they go right,
the packet's steering sign is the other way round and `_AttitudeCard` needs its
one negation moved.

## 4. Verification

* `test/track_trace_test.dart` → `packet B motion block`: a synthetic 316-byte
  packet decodes steering `-0.42 rad`, rate `1.25 rad/s`, `sway` 1.0 g and
  `surge` -1.0 g; a 296-byte packet reports no motion data at all; a 368-byte
  packet carries the same block.
* `test/car_model_3d_test.dart` → the geometry: a wheel turns about its own
  centre, no wheel climbs with the body, the nose is drawn further away than the
  tail, and the car's right-hand side lands on the right of the screen - the
  four things that were each wrong once and are all invisible in a still frame.
* `test/motion_panel_layout_test.dart` → the merged instrument: the wheel and the
  nose share a row and an axis, a gripping drive reads `GRIP`, a nose turned
  further in than the wheels reads `OVERSTEER`, a nose turned out reads
  `UNDERSTEER`, and with no route at all it refuses to guess.
* `test/wheel_surface_tint_test.dart` → the surface tint reaches the canvas: a
  plain car and an all-tarmac car carry no surface colour, a grass wheel paints
  red and a kerb wheel yellow, and the tint lands on the wheel that asked for it.
* `flutter analyze lib` → 0 errors; `flutter test` → all suites pass (154 tests,
  2026-09-24).

## 5. Still open

* **Does `clutchEngaged` (`0xF8`) say anything the pedal (`0xF4`) does not?** The
  graph draws both as separate traces, with the demo deliberately lagging the
  clutch behind the pedal so the pair is visible. On real hardware this is the
  first thing to check: one session, manual gearbox, both fields logged. If they
  are always `x` and `1 - x`, the second trace goes.

* `C`-only fields (front wheel angles, surface under each tyre, car category)
  need one real `C` capture to locate them — see §2.
* The car's yaw from the packet is decoded but unused: a heading needle or a
  "drift angle" readout (yaw vs. direction of travel) is now a small step.
