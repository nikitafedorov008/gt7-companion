# The data view: what sits where, and why

`lib/widgets/telemetry/telemetry_display.dart` is the second of the two
presentations the telemetry screen can show - the graphs and the numbers, next
to the in-game HUD replica in `gt7_hud.dart`. It is one scrolling column. On a wide page the **top row** holds exactly two
things - the route the driver is on, and what the car is doing on it - and
everything else follows below:

| # | Panel | What it is |
|---|---|---|
| 1 | `MotionWorkspace` with `leading: _TrackMapPanel` | **the top row**: the route on the left, the motion block in a **fixed 430 px column** on the right. Narrower than 900 px they stack, route first |
| 2 | `GaugeDial` ×2 | speed and rpm, side by side on desktop and stacked on a phone - the two things read *while driving*, so they come straight after the route and the load |
| 3 | `MotionSideCards` | the car's card, right-aligned in the column the dial stands in |
| 4 | `ElevationProfile` | the height the packet reports, along the fastest lap |
| 5 | `_SessionBestPanel` | last/best lap with the signed deltas and the live delta |
| 6 | `ThrottleBrakeGraph` | the last ten seconds of throttle, brake and clutch |

The motion column is a fixed 430 px rather than a share of the row, and the route
takes what is left (about 800 px on a 1280 px window). Fixed, because the same
column holds the car's card further down the page: a ratio would put the dial and
the card 20 px out of line at one width and 60 at another, which reads as a
mistake without being one. The map is a picture and uses the width it is given.

**The row has a height budget** (`dialSize: 360`, `mapHeight: 320`), because the
dial and the map's drawing box are the only two things on the page that grow
without limit, and left alone they pushed everything else out of the frame. With
the budget the row measures **454 px** - the dial and its heading, nothing else -
and the cards under it start at 481.

The map's box is sized *to the motion block* on purpose: a panel is its drawing
box plus about 145 px of header and footer, and the block is its dial plus 94 px
of heading and padding, so 320 px of drawing brings the two out level. The test
asserts they are within a line of each other rather than to the pixel - the map's
footer wraps by a line depending on the numbers in it, and plumbing a fixed
height through both panels to hide that is not worth it - because a row with one
panel ending 50 px short of the other reads as a mistake whatever the reason was.

The dial at 360 is not an arbitrary size - it is [kGForceBallWheelbaseSize], the
smallest dial whose own label still fits inside the circle *with* the wheelbase
dimension drawn on the car. Below it the dimension goes back to the readouts as
text. That threshold, the width of the label band and the radius all come from
one constant (`kGForceBallLabelBand`), which is what let the four channel
readouts shrink - 9/20/7 px down to 8/15/6 - to grow the circle from a 62 px
radius to 108 without spending a pixel of height.

The facts row (category, wheelbase) is a **fallback** now, not a fixture: it
appears only on a dial too small to draw the wheelbase on the car itself, which
in practice means the HUD's MFD page. The car's category moved to the car's own
card, where the rest of its state lives.

The cards below are the session's, not the dial's: they are read at a glance
between corners, not while driving, which is why they left the motion block and
now lie along the page under the top row.

## The motion block is tall, and the cards are their own cards

`MotionPanel` is the instrument: the dial, with two compact channel cards and
the car's own facts **stacked under it**. The channels - steering, and the drift
angle the trace measures - share a row, each in its own card with a short bar:
they are short, they belong together, and a steering bar across the whole panel
said less than half of one beside its neighbour. Under 520 px they stack.

The car's **aids** (TCS, ABS), the **pre-aid inputs** and the **energy
recovery** are not the driver's doing but the car's state, so they live in the
`TYRES & VEHICLE` card with the tyres and the fluids - under an `AIDS` label, and
only when the packet actually carries them: on heartbeat `A` the row says
`NO AID DATA IN PACKET A` rather than showing zeros. `MotionSideCards` is the cards that belong with it, each with its own frame and
none of them nested inside the motion panel:

| Card | What is in it |
|---|---|
| `LAP`, `POSITION`, `LAP TIME` | where the driver is in the race: the lap, the place, and the lap in progress |
| `TYRES & VEHICLE` | **the car** (430 px): gear and fuel, `AttitudeCard` (steering and drift as one instrument), the four tyres with their surfaces in one row, the fluids, the brakes, the aids |

The **session's numbers - lap, position, the lap in progress - are drawn on the
map**, in the corner of its own drawing box, the way a racing HUD puts them. They
were a row of cards that cost a whole band of the page for three short numbers,
and the map had the room: the route is centred, so a corner overlay covers none
of it. The card is a `Stack` over the drawing, with a translucent plate behind the
numbers for the one corner where the route does run under it.

The steering instrument lives in the car's card rather than in the motion block:
what the driver does with the wheel and what the car does with it - a slide, a
tyre off the road - is the same subject as the tyres that have to make it happen,
and the motion block is left as the dial alone. `MotionPanel` keeps the
instrument inline when it has no cards to hand, which is the HUD's MFD page.

Gear and fuel sit *inside* the car card rather than above it: they are the car's
state as much as its tyres are, and one card that describes the car is easier to
read at a glance than three that each describe a corner of it. `MotionWorkspace` puts the two
side by side, the block on the left and the cards in their own column on the
right, which is what makes the block a column of things rather than a band with a
circle in it.

The tyre tiles in `TYRES & VEHICLE` carry the surface each wheel is on, in that
surface's colour, with an `OFF TRACK` badge on the card when any wheel has left
the racing surface. Those letters used to sit in a row of chips in the motion
readouts - a surface belongs to a wheel, so it is written on the wheel.

`MotionWorkspace` owns that arrangement, so nothing else has to know the widths:

| Workspace width | Layout |
|---|---|
| ≥ 900 px | two columns: the motion block \| the cards, 320 px wide |
| < 900 px | one column: the motion block, then the cards |

Inside the block, the dial is capped at 470 px and centred, with the readouts
under it; `MotionPanel.readoutsBelow` is what asks for that arrangement even when
the panel itself is wide, which is the case here.

The dial also carries the wheelbase now, as a dimension line drawn on the car
(see `telemetry-packets.md`), so the readouts beside it no longer repeat the
number - `kGForceBallWheelbaseSize` decides which of the two shows it.

## Two traps in this layout, both hit for real

* **`CrossAxisAlignment.stretch` inside the scrolling column throws.** The page
  is a `SingleChildScrollView`, so the cross axis (height) is unbounded;
  stretching a row to fill it asks for an infinite height, the frame throws
  "BoxConstraints forces an infinite height", and the view renders **black**.
  Pairs of cards use `IntrinsicHeight` instead, which gives them one height
  without asking for infinity.
* **A layout test with a placeholder side widget does not test the layout.** The
  cards were first tested through `side: SizedBox(...)`, which cannot throw the
  way the real cards do. The tests now pass the real `MotionSideCards`, at
  desktop and phone widths, and assert the exception channel is empty.

## Verification

`test/motion_panel_layout_test.dart` measures where things land rather than
trusting the code to look right: the dial left of the readouts when wide and
above them when narrow, the cards at the panel's right padding edge in three
columns, below the dial in two, after the readouts in one - and no exception
from the real cards at either width.
