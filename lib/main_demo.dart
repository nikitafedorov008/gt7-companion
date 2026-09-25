import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'app.dart';
import 'utils/dev_flags.dart';
import 'utils/platform_utils.dart';

/// Development entrypoint: the demo feed is running from the first frame, so it
/// can be launched by tooling that cannot pass `--dart-define` (the Dart MCP
/// server's `launch_app`, for example).
///
/// It opens on the *home* page, not the dashboard: the dashboard is one tap away
/// through `Open dashboard` on the telemetry card. `GT7_VIEW=data` only decides
/// which view the dashboard itself opens in.
///
/// It also installs the Marionette binding, which is what lets an agent drive
/// the running UI (inspect elements, tap, screenshot). Release builds keep
/// using `lib/main.dart` and never link Marionette.
void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  autoDemoTelemetryOverride = true;
  PlatformUtils.configurePlatformWindowUtils();
  runApp(const App());
}
