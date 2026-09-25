import 'package:freezed_annotation/freezed_annotation.dart';

part 'throttle_brake_graph_state.freezed.dart';

/// One frame of pedal input: the two a driver works all the time, and the
/// clutch, which only a clutch pedal (or a shift with one) produces.
///
/// All of them in percent. `clutch` is the packet's `0xF4`, the clutch pedal's
/// own position, and `clutchEngaged` its `0xF8`, how far the clutch is actually
/// let in - the two only part company on a car with a real clutch, which is why
/// the graph draws neither trace until one of them has something to say.
@freezed
abstract class ThrottleBrakeDataPoint with _$ThrottleBrakeDataPoint {
  const factory ThrottleBrakeDataPoint({
    required double throttle,
    required double brake,
    required DateTime timestamp,
    @Default(0.0) double clutch,
    @Default(0.0) double clutchEngaged,
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
