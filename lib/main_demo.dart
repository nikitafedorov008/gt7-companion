import 'dart:async';

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
///
/// The app logs through `print`/`debugPrint`, so a [PrintLogCollector] is
/// attached to the binding: both sinks and framework exceptions forward into it,
/// and `get_logs` on the MCP side then returns everything the app emitted since
/// start or last reload instead of failing with "Log collection is not
/// configured".
void main() {
  if (kDebugMode) {
    _runWithMarionette();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
    _startApp();
  }
}

/// Boots the app with Marionette enabled and the app's output wired into its log store.
void _runWithMarionette() {
  final logCollector = PrintLogCollector();

  // A single hook covers both sinks: the app's own `print(...)` calls go through
  // the zone, and Flutter's `debugPrint` funnels its lines into the very same
  // `print` (see `debugPrintThrottled` → `_debugPrintTask` in the framework),
  // so nothing is recorded twice. Lines still reach stdout for `flutter run`.
  //
  // The binding is initialized inside this zone as well: Flutter asserts when
  // `runApp` runs in a different zone than the one that initialized it.
  runZoned(
    () {
      MarionetteBinding.ensureInitialized(
        MarionetteConfiguration(logCollector: logCollector),
      );

      // Framework failures (build and layout errors, uncaught widget exceptions)
      // are reported from outside the app's zone, so they are forwarded
      // explicitly. The previous handler still runs, keeping the usual output.
      final forwardFlutterError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        logCollector.addLog('EXCEPTION: ${details.exceptionAsString()}');
        forwardFlutterError?.call(details);
      };

      _startApp();
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        parent.print(zone, line);
        logCollector.addLog(line);
      },
    ),
  );
}

void _startApp() {
  autoDemoTelemetryOverride = true;
  PlatformUtils.configurePlatformWindowUtils();
  runApp(const App());
}
