import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import '../dealer_inventory.dart';

@RoutePage()
class LegendaryCarDisplay extends StatelessWidget {
  const LegendaryCarDisplay({super.key});
  @override
  Widget build(BuildContext context) => const DealerInventory(legendary: true);
}
