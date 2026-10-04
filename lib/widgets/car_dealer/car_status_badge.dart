// FILE: lib/widgets/car_dealer/car_status_badge.dart
// VERSION: 1.0.0
// START_MODULE_CONTRACT
//   PURPOSE: Draw the small stock badge a car-dealer card shows for SOLD OUT or LIMITED STOCK.
//   SCOPE: Badge layout and colours only; no state, no data access.
//   DEPENDS: none
//   LINKS: M-WIDGET-CAR-DEALER, V-M-WIDGET-CAR-DEALER
//   ROLE: RUNTIME
//   MAP_MODE: EXPORTS
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   CarStatusBadge - stock badge with caller-supplied text and colours.
// END_MODULE_MAP

import 'package:flutter/material.dart';

/// The stock badge both dealership grids use.
///
/// Extracted from two byte-identical private copies in UsedCarCardItem and
/// LegendaryCarCardItem, so the padding, radius and type size live in one place.
/// Colours stay the caller's business: the used and legendary cards pick their
/// own pairs.
class CarStatusBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const CarStatusBadge({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }
}
