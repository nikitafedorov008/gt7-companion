import 'package:flutter/material.dart';

import '../../theme/gt7_theme.dart';

/// The vocabulary GT7's surface codes are spoken in, in one place.
///
/// Packet `C` reports one letter per wheel (`0x158`), in the order
/// **FL, FR, RL, RR** - the same order the three-dimensional car builds its
/// wheels in, so a colour computed here can be handed straight to a wheel.
///
/// The chips, the tyre cards and the tyres painted on the car all read from
/// these functions, which is the point of them: three places that describe the
/// same letter cannot drift apart if there is only one description.

/// The colour a surface code is *shown* in.
///
/// Tarmac is the neutral the rest of the HUD is written in, because "TARMAC" has
/// to be readable as text. A *tyre* standing on tarmac is not tinted at all,
/// which is a separate decision - see [gt7WheelSurfaceColours] in
/// `g_force_ball.dart`.
Color gt7SurfaceColour(String code) {
  return switch (code) {
    'T' => gt7Text,
    'C' => gt7SlotB, // kerb
    'D' || 'G' || 'S' => gt7Warn, // dirt, grass, sand: off the racing surface
    's' => gt7SlotA, // snow
    _ => gt7TextMuted,
  };
}

/// The word for a surface code, as the HUD prints it.
String gt7SurfaceLabel(String code) {
  return switch (code) {
    'T' => 'TARMAC',
    'C' => 'KERB',
    'D' => 'DIRT',
    'G' => 'GRASS',
    'S' => 'SAND',
    's' => 'SNOW',
    _ => '—',
  };
}

/// True when the code means the tyre is no longer on tarmac or a kerb.
bool gt7SurfaceIsOffTrack(String code) => 'DGgsS'.contains(code);

/// The wheel names in the packet's own order.
const List<String> gt7WheelNames = ['FL', 'FR', 'RL', 'RR'];

/// The surface code for one wheel, or an empty string when the packet carries
/// no surface data at all (packets `A` and `B` do not).
String gt7SurfaceAt(String surfaceTypes, int wheel) {
  if (wheel < 0 || wheel >= surfaceTypes.length) return '';
  return surfaceTypes[wheel];
}
