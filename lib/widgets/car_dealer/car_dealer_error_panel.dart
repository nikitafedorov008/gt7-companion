// FILE: lib/widgets/car_dealer/car_dealer_error_panel.dart
// VERSION: 1.0.0
// START_MODULE_CONTRACT
//   PURPOSE: Show the standard car-dealer error state: an icon, a title, the failure message and a retry button.
//   SCOPE: Error presentation only; the caller owns what retry does.
//   DEPENDS: none
//   LINKS: M-WIDGET-CAR-DEALER, V-M-WIDGET-CAR-DEALER
//   ROLE: RUNTIME
//   MAP_MODE: EXPORTS
// END_MODULE_CONTRACT
//
// START_MODULE_MAP
//   CarDealerErrorPanel - centered error state with a retry action.
// END_MODULE_MAP

import 'package:flutter/material.dart';


/// The error state both dealership screens show when loading fails.
///
/// Extracted from two copies that differed only in their title string. It stays
/// a leaf: it takes the message and a retry callback instead of a repository, so
/// a widget test can build it without the data layer, and the screen keeps
/// control of what retrying means.
class CarDealerErrorPanel extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const CarDealerErrorPanel({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
