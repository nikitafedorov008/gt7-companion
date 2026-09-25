import 'package:flutter/foundation.dart';

import '../models/telemetry/track_trace.dart';
import '../services/telemetry_service.dart';

/// Keeps the driven route up to date for whoever wants to draw it.
///
/// GT7 sends a position 60 times a second; the trace thins those into one point
/// every couple of metres, so this listens to [TelemetryService] and forwards
/// every packet. It only notifies when a point was actually recorded, which
/// keeps the map from repainting 60 times a second for nothing.
class TrackTraceRepository extends ChangeNotifier {
  TrackTraceRepository(this._telemetryService) {
    _telemetryService.addListener(_onTelemetry);
  }

  final TelemetryService _telemetryService;
  final TrackTrace _trace = TrackTrace();

  TrackTrace get trace => _trace;

  bool get hasRoute => _trace.hasRoute;

  void clear() {
    _trace.clear();
    notifyListeners();
  }

  void _onTelemetry() {
    final telemetry = _telemetryService.telemetry;
    if (telemetry == null) return;
    // When the rotation block is a quaternion the body angle is exact, so the
    // drift readout does not have to measure the yaw unit from the drive.
    _trace.exactBodyHeading = telemetry.quaternionHeading;
    if (_trace.add(telemetry)) notifyListeners();
  }

  @override
  void dispose() {
    _telemetryService.removeListener(_onTelemetry);
    super.dispose();
  }
}
