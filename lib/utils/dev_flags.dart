/// Compile-time development switches.
///
/// `--dart-define=GT7_DEMO=true` opens the app straight on the telemetry tab
/// with the built-in demo feed already running, so the dashboard can be
/// inspected without a PlayStation on the network:
///
/// ```sh
/// flutter run -d macos --dart-define=GT7_DEMO=true
/// ```
const bool kAutoDemoTelemetry = bool.fromEnvironment('GT7_DEMO');

/// Which telemetry view to open with: `hud` (the in-game replica, the default)
/// or `data` (graphs and numeric readouts).
///
/// ```sh
/// flutter run -d macos --dart-define=GT7_VIEW=data
/// ```
const String kInitialTelemetryView = String.fromEnvironment(
  'GT7_VIEW',
  defaultValue: 'hud',
);

/// Which MFD page to open on, for screenshots and demos.
///
/// ```sh
/// flutter run -d macos --dart-define=GT7_MFD=5
/// ```
const int kInitialMfdPage = int.fromEnvironment('GT7_MFD');

/// Which map mode the data view opens in: `north` is the flat plan of the whole
/// circuit, `heading` is the navigator view that follows the car.
///
/// ```sh
/// flutter run -d macos --dart-define=GT7_MAP=heading
/// ```
const String kInitialMapMode = String.fromEnvironment(
  'GT7_MAP',
  defaultValue: 'north',
);

/// Runtime override for the demo feed, for entrypoints that cannot pass
/// `--dart-define` (for example an app launched by the Dart MCP server).
bool autoDemoTelemetryOverride = false;

/// Whether the demo feed should start on launch.
bool get autoDemoTelemetryEnabled =>
    kAutoDemoTelemetry || autoDemoTelemetryOverride;
