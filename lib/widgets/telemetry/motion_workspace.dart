import 'package:flutter/material.dart';

import '../../models/telemetry/telemetry_data.dart';
import '../../models/telemetry/track_trace.dart';
import 'motion_panel.dart';

/// The width of the motion column, and therefore of the car's card under it:
/// one column of the page, the dial and its heading across it. The route takes
/// whatever is left, which on a 1280 px window is about 800 px.
///
/// Fixed rather than a flex share, so that the two things that sit in this column
/// - the dial above, the car's card below - line up with each other whatever the
/// page is. A ratio would leave them 20 px apart at one width and 60 at another,
/// which is the kind of thing that reads as a mistake without being one.
const double kMotionColumnWidth = 430;

/// The width at which the route can stand beside the motion block

/// The width at which the route can stand beside the motion block rather than
/// above it. Below this the two would be about 200 px each, which is where the
/// route stops being a route.
const double kMotionWorkspaceWide = 900;

/// The top of the data view: the route a driver is on, beside what the car is
/// doing on it.
///
/// That is the whole of it - the session's numbers and the car's state are their
/// own cards further down the page, not part of this row. What is left here is
/// the two things looked at *while driving*: where the track goes, and the load.
///
/// Under [kMotionWorkspaceWide] the two columns become one, the route first.
class MotionWorkspace extends StatelessWidget {
  const MotionWorkspace({
    super.key,
    required this.telemetry,
    this.trace,
    this.dialSize,
    this.leading,
  });

  final TelemetryData telemetry;

  /// The driven route, which is where the drift angle comes from.
  final TrackTrace? trace;

  /// Fixes the dial's size. Left unset it takes the width the column allows.
  final double? dialSize;

  /// The route, drawn. Beside the motion block on a wide page, above it on a
  /// narrow one; absent when there is no route yet.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final motion = MotionPanel(
      telemetry: telemetry,
      trace: trace,
      dialSize: dialSize,
      // The data view always stacks: the block is a column, and the cards that
      // used to share it are cards of their own further down the page.
      readoutsBelow: true,
    );

    if (leading == null) return motion;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kMotionWorkspaceWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leading!,
              const SizedBox(height: 14),
              motion,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leading!),
            const SizedBox(width: 14),
            SizedBox(width: kMotionColumnWidth, child: motion),
          ],
        );
      },
    );
  }
}
