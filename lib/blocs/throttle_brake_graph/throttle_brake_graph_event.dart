import 'package:freezed_annotation/freezed_annotation.dart';

part 'throttle_brake_graph_event.freezed.dart';

@freezed
class ThrottleBrakeGraphEvent with _$ThrottleBrakeGraphEvent {
  const factory ThrottleBrakeGraphEvent.initialize() = _Initialize;

  const factory ThrottleBrakeGraphEvent.telemetryUpdated({
    required double throttle,
    required double brake,
    required DateTime timestamp,
    @Default(0.0) double clutch,
    @Default(0.0) double clutchEngaged,
  }) = _TelemetryUpdated;

  const factory ThrottleBrakeGraphEvent.clear() = _Clear;
}
