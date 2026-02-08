import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter/animation.dart';

import '../utils/platform_utils.dart';

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
    if (!enabled || kIsWeb) return child;

    return ValueListenableBuilder<EdgeInsets>(
      valueListenable: PlatformUtils.windowInsetsNotifier,
      builder: (context, inset, _) {
        final mq = MediaQuery.of(context);
        final left = mq.padding.left + inset.left;
        final right = mq.padding.right + inset.right;

        if (!animate) {
          return Padding(
            padding: EdgeInsets.only(left: left, right: right),
            child: child,
          );
        }

        return AnimatedPadding(
          duration: duration,
          curve: curve,
          padding: EdgeInsets.only(left: left, right: right),
          child: child,
        );
      },
    );
  }
}
