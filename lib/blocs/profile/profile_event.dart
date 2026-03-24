import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_event.freezed.dart';

@freezed
class ProfileEvent with _$ProfileEvent {
  const factory ProfileEvent.loadPlayer({
    required String onlineId,
    @Default(1) int page,
  }) = _LoadPlayer;

  const factory ProfileEvent.sendBannerImpressions({
    required List<int> impressions,
  }) = _SendBannerImpressions;
}
