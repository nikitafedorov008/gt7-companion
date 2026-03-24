import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/dg_edge/dg_edge_player.dart';

part 'profile_state.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(false) bool isLoading,
    String? error,
    String? onlineId,
    @Default(<DgEdgePlayerEvent>[]) List<DgEdgePlayerEvent> events,
    DgEdgePlayerEventsPagination? pagination,
    String? csrfToken,
  }) = _ProfileState;

  factory ProfileState.initial() => const ProfileState();
}
