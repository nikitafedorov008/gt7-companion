import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/dg_edge/dg_edge_player.dart';

part 'profile_state.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = _ProfileStateInitial;

  const factory ProfileState.loading() = _ProfileStateLoading;

  const factory ProfileState.loaded({
    required String onlineId,
    @Default(<DgEdgePlayerEvent>[]) List<DgEdgePlayerEvent> events,
    DgEdgePlayerEventsPagination? pagination,
    String? csrfToken,
  }) = _ProfileStateLoaded;

  const factory ProfileState.error(String message) = _ProfileStateError;
}
