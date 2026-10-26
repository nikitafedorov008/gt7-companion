import 'dart:math' as math;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

/// Marks content already placed below the desktop navigation bar.
/// Dialogs and root routes do not inherit this scope, so their own headers
/// still avoid the traffic lights in a full-size macOS content view.
class WindowNavigationScope extends InheritedWidget {
  const WindowNavigationScope({
    super.key,
    required this.hasTopNavigation,
    required super.child,
  });
  final bool hasTopNavigation;
  @override
  bool updateShouldNotify(WindowNavigationScope oldWidget) =>
      hasTopNavigation != oldWidget.hasTopNavigation;
}

/// Reserves native window-control space once, and consumes overlapping system
/// horizontal safe padding instead of adding it a second time.
class WindowNavigationSafeArea extends StatelessWidget {
  const WindowNavigationSafeArea({
    super.key,
    required this.child,
    this.enabled = true,
    this.animate = true,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
  });
  final Widget child;
  final bool enabled;
  final bool animate;
  final Duration duration;
  final Curve curve;
  @override
  Widget build(BuildContext context) {
    final consumed =
        context
            .dependOnInheritedWidgetOfExactType<WindowNavigationScope>()
            ?.hasTopNavigation ??
        false;
    if (!enabled ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.macOS ||
        consumed) {
      return child;
    }
    return ValueListenableBuilder<EdgeInsets>(
      valueListenable: PlatformUtils.windowInsetsNotifier,
      builder: (context, inset, _) {
        final padding = MediaQuery.paddingOf(context);
        final effective = EdgeInsets.only(
          left: math.max(padding.left, inset.left),
          right: math.max(padding.right, inset.right),
        );
        final content = WindowNavigationScope(
          hasTopNavigation: true,
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: child,
          ),
        );
        return animate
            ? AnimatedPadding(
                duration: duration,
                curve: curve,
                padding: effective,
                child: content,
              )
            : Padding(padding: effective, child: content);
      },
    );
  }
}

/// An ordinary AppBar with native-window safe spacing on standalone routes.
class WindowNavigationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const WindowNavigationAppBar({super.key, required this.child});
  final PreferredSizeWidget child;
  @override
  Size get preferredSize => child.preferredSize;
  @override
  Widget build(BuildContext context) => WindowNavigationSafeArea(child: child);
}
