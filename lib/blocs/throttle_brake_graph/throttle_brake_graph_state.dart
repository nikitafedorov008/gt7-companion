import 'package:freezed_annotation/freezed_annotation.dart';

part 'throttle_brake_graph_state.freezed.dart';

/// Data point representing throttle and brake values at a specific time
@freezed
abstract class ThrottleBrakeDataPoint with _$ThrottleBrakeDataPoint {
  const factory ThrottleBrakeDataPoint({
    required double throttle,
    required double brake,
    required DateTime timestamp,
  }) = _ThrottleBrakeDataPoint;
}

/// State for ThrottleBrakeGraphBloc
@freezed
abstract class ThrottleBrakeGraphState with _$ThrottleBrakeGraphState {
  const factory ThrottleBrakeGraphState.initial() = _Initial;

  const factory ThrottleBrakeGraphState.loading() = _Loading;

  const factory ThrottleBrakeGraphState.success({
    @Default(<ThrottleBrakeDataPoint>[]) List<ThrottleBrakeDataPoint> history,
  }) = _Success;

  const factory ThrottleBrakeGraphState.error(String message) = _Error;
}
