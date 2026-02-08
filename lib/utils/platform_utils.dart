import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class PlatformUtils {
  static const double kDefaultMacTrafficLightInset = 74.0;

  static final ValueNotifier<EdgeInsets> windowInsetsNotifier = ValueNotifier(
    const EdgeInsets.only(left: kDefaultMacTrafficLightInset),
  );

  static Future<void> configurePlatformWindowUtils() async {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        await _configureMacosWindowUtils();
      } else {
        windowInsetsNotifier.value = EdgeInsets.zero;
      }
    }
  }

  static Future<void> _configureMacosWindowUtils() async {
    await WindowManipulator.initialize(enableWindowDelegate: true);

    WindowManipulator.makeTitlebarTransparent();
    WindowManipulator.enableFullSizeContentView();
    WindowManipulator.addToolbar();
    WindowManipulator.hideTitle();
    WindowManipulator.setToolbarStyle(
      toolbarStyle: NSWindowToolbarStyle.automatic,
    );
    WindowManipulator.makeWindowFullyTransparent();
    WindowManipulator.addNSWindowDelegate(GTDelegate());

    windowInsetsNotifier.value = const EdgeInsets.only(
      left: kDefaultMacTrafficLightInset,
    );
  }
}

class GTDelegate extends NSWindowDelegate {
  @override
  void windowWillEnterFullScreen() {
    PlatformUtils.windowInsetsNotifier.value = EdgeInsets.zero;
    WindowManipulator.removeToolbar();
    super.windowWillEnterFullScreen();
  }

  @override
  void windowDidExitFullScreen() {
    PlatformUtils.windowInsetsNotifier.value = const EdgeInsets.only(
      left: PlatformUtils.kDefaultMacTrafficLightInset,
    );
    WindowManipulator.addToolbar();
    super.windowDidExitFullScreen();
  }
}
