import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:gt7_companion/services/telemetry_service.dart';

import 'throttle_brake_graph_event.dart';
import 'throttle_brake_graph_state.dart';

/// BLoC for managing throttle and brake graph history
///
/// Maintains a ring buffer of throttle/brake data points with a fixed time window.
/// Listens to TelemetryService for real-time telemetry updates and maintains
/// history in chronological order without duplicates.
class ThrottleBrakeGraphBloc extends Bloc<ThrottleBrakeGraphEvent, ThrottleBrakeGraphState> {
  final TelemetryService _telemetryService;

  /// Ring buffer for storing throttle/brake history
  final List<ThrottleBrakeDataPoint> _history = [];

  /// Timer for polling telemetry updates
  Timer? _pollTimer;

  /// Maximum number of data points to keep in buffer (600 points = ~10 seconds at 60 Hz)
  static const int maxBufferSize = 600;

  /// Time window duration in seconds (10 seconds recommended)
  static const int timeWindowSeconds = 10;

  /// Last timestamp to prevent duplicates
  DateTime? _lastTimestamp;

  ThrottleBrakeGraphBloc(this._telemetryService)
      : super(const ThrottleBrakeGraphState.initial()) {
    on<ThrottleBrakeGraphEvent>((event, emit) async {
      await event.when(
        initialize: () async => _handleInitialize(emit),
        telemetryUpdated: (throttle, brake, timestamp) async =>
            _handleTelemetryUpdated(throttle, brake, timestamp, emit),
        clear: () async => _handleClear(emit),
      );
    });
  }

  /// Initialize the BLoC and start listening to telemetry
  Future<void> _handleInitialize(Emitter<ThrottleBrakeGraphState> emit) async {
    emit(const ThrottleBrakeGraphState.loading());

    try {
      // Start polling telemetry service every 16ms (~60 FPS)
      _pollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        _onTelemetryChanged();
      });

      emit(ThrottleBrakeGraphState.success(history: List.from(_history)));
    } catch (e) {
      emit(ThrottleBrakeGraphState.error('Failed to initialize: ${e.toString()}'));
    }
  }

  /// Called when telemetry service changes
  void _onTelemetryChanged() {
    final data = _telemetryService.telemetry;
    if (data != null) {
      add(ThrottleBrakeGraphEvent.telemetryUpdated(
        throttle: data.throttle.toDouble(),
        brake: data.brake.toDouble(),
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Handle telemetry data update
  Future<void> _handleTelemetryUpdated(
    double throttle,
    double brake,
    DateTime timestamp,
    Emitter<ThrottleBrakeGraphState> emit,
  ) async {
    try {
      // Prevent duplicate timestamps (filter updates less than 10ms apart)
      if (_lastTimestamp != null &&
          timestamp.difference(_lastTimestamp!).inMilliseconds < 10) {
        return;
      }
      _lastTimestamp = timestamp;

      // Create new data point
      final dataPoint = ThrottleBrakeDataPoint(
        throttle: throttle.clamp(0.0, 100.0),
        brake: brake.clamp(0.0, 100.0),
        timestamp: timestamp,
      );

      // Add to history and maintain chronological order
      _history.add(dataPoint);

      // Remove old entries outside the time window
      _pruneOldData(timestamp);

      // Limit buffer size to prevent unbounded memory growth
      if (_history.length > maxBufferSize) {
        _history.removeAt(0);
      }

      emit(ThrottleBrakeGraphState.success(history: List.from(_history)));
    } catch (e) {
      emit(ThrottleBrakeGraphState.error('Failed to update telemetry: ${e.toString()}'));
    }
  }

  /// Handle clear event
  Future<void> _handleClear(Emitter<ThrottleBrakeGraphState> emit) async {
    try {
      _history.clear();
      _lastTimestamp = null;
      emit(const ThrottleBrakeGraphState.success());
    } catch (e) {
      emit(ThrottleBrakeGraphState.error('Failed to clear history: ${e.toString()}'));
    }
  }

  /// Prune old data points outside the time window
  void _pruneOldData(DateTime currentTime) {
    final cutoffTime =
        currentTime.subtract(Duration(seconds: timeWindowSeconds));

    _history.removeWhere((point) => point.timestamp.isBefore(cutoffTime));
  }

  @override
  Future<void> close() async {
    // Cancel polling timer
    _pollTimer?.cancel();
    return super.close();
  }
}
