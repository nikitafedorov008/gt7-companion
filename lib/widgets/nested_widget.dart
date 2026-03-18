import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../router/app_router.dart';

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
          body: child,
        );
      },
    );
  }
}
