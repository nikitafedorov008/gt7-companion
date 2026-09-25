import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../router/app_router.dart';
import '../services/telemetry_service.dart';
import '../utils/dev_flags.dart';

import 'adaptive_navbar.dart';

/// Shell that uses AutoRoute's tabbed API (pageView) so child pages can be
/// swiped and the TabsRouter is available to the `AdaptiveNavBar`.
@RoutePage()
class NestedWidget extends StatelessWidget {
  const NestedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter.pageView(
      // primary app sections exposed as tabs
      routes: const [
        HomePageRoute(),
        WishlistPageRoute(),
        ProfilePageRoute(),
        TelemetryDetailsScreenRoute(),
      ],
      builder: (context, child, _) {
        // Platform-aware nav placement:
        // - show bottom nav ONLY on mobile platforms (iOS / Android)
        // - show top nav on desktop platforms and web
        // - for unknown platforms fall back to a width heuristic
        final platform = defaultTargetPlatform;
        final isWeb = kIsWeb;
        final isMobilePlatform =
            !isWeb &&
            (platform == TargetPlatform.iOS ||
                platform == TargetPlatform.android);
        final isDesktopPlatform =
            isWeb ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.windows ||
            platform == TargetPlatform.linux;

        final width = MediaQuery.of(context).size.width;
        final preferTopNavBecauseOfWidth = width > 800;

        final showTopNav =
            isDesktopPlatform ||
            (!isMobilePlatform && preferTopNavBecauseOfWidth);
        final showBottomNav = isMobilePlatform;

        return Scaffold(
          extendBody: true,
          appBar: showTopNav
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(72),
                  child: AdaptiveNavBar(),
                )
              : null,
          bottomNavigationBar: showBottomNav ? const AdaptiveNavBar() : null,
          body: _AutoDemoLauncher(child: child),
        );
      },
    );
  }
}

/// Development helper: with `--dart-define=GT7_DEMO=true` the app lands on the
/// telemetry tab with the demo feed already running, so the dashboard can be
/// inspected without a console on the network.
class _AutoDemoLauncher extends StatefulWidget {
  const _AutoDemoLauncher({required this.child});

  final Widget child;

  @override
  State<_AutoDemoLauncher> createState() => _AutoDemoLauncherState();
}

class _AutoDemoLauncherState extends State<_AutoDemoLauncher> {
  @override
  void initState() {
    super.initState();
    if (!autoDemoTelemetryEnabled) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final service = context.read<TelemetryService>();
      if (!service.isConnected) {
        service.startDemoTelemetry();
      }

      try {
        AutoTabsRouter.of(context).setActiveIndex(3);
      } catch (_) {
        // Not inside a TabsRouter (e.g. a deep link) - nothing to switch.
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
