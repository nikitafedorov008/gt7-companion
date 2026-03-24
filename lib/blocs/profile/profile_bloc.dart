import 'package:bloc/bloc.dart';

import '../../repositories/profile_repository.dart';
import '../../models/dg_edge/dg_edge_player.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc(this._profileRepository) : super(ProfileState.initial()) {
    on<ProfileEvent>((event, emit) async {
      await event.when(
        loadPlayer: (onlineId, page) async => _handleLoadPlayer(onlineId, page, emit),
        sendBannerImpressions: (impressions) async => _handleBannerImpressions(impressions, emit),
      );
    });
  }

  Future<void> _handleLoadPlayer(
    String onlineId,
    int page,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileState.loading());

    try {
      final response = await _profileRepository.fetchPlayerEvents(
        onlineId,
        page: page,
      );

      emit(
        ProfileState.loaded(
          onlineId: onlineId,
          events: response.events,
          pagination: response.pagination,
          csrfToken: response.csrfToken,
        ),
      );
    } catch (e) {
      emit(ProfileState.error(e.toString()));
    }
  }

  Future<void> _handleBannerImpressions(
    List<int> impressions,
    Emitter<ProfileState> emit,
  ) async {
    final onlineIdMaybe = state.maybeWhen(
      loaded: (onlineId, events, pagination, csrfToken) => onlineId,
      orElse: () => null,
    );

    if (onlineIdMaybe == null || onlineIdMaybe.isEmpty) {
      return;
    }

    try {
      await _profileRepository.sendBannerImpressions(
        impressions,
        onlineId: onlineIdMaybe,
      );
      // keep current success state
    } catch (e) {
      emit(ProfileState.error(e.toString()));
    }
  }
}
