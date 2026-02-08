import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// Shell that hosts the "home stack" — the visible Home screen and its
/// in-place children (Used, Legendary, GT Auto). Child routes will render
/// inside this shell's AutoRouter so navigation stays within the Home area.
@RoutePage()
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    // This shell intentionally does not render the global navigation chrome;
    // it's responsible only for providing the inner navigator for home-related
    // screens.
    return const SafeArea(child: AutoRouter());
  }
}
