import 'package:bloc/bloc.dart';

import '../../repositories/profile_repository.dart';
import '../../models/dg_edge/dg_edge_player.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc(this._profileRepository) : super(ProfileState.initial()) {
    on<ProfileEvent>((event, emit) async {
      await event.map(
        loadPlayer: (loadEvent) async => _handleLoadPlayer(loadEvent, emit),
        sendBannerImpressions: (impressionsEvent) async =>
            _handleBannerImpressions(impressionsEvent, emit),
      );
    });
  }

  Future<void> _handleLoadPlayer(
    dynamic event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final response = await _profileRepository.fetchPlayerEvents(
        event.onlineId,
        page: event.page,
      );

      emit(
        state.copyWith(
          isLoading: false,
          onlineId: event.onlineId,
          events: response.events,
          pagination: response.pagination,
          csrfToken: response.csrfToken,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _handleBannerImpressions(
    dynamic event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.onlineId == null || state.onlineId!.isEmpty) {
      return;
    }

    try {
      await _profileRepository.sendBannerImpressions(
        event.impressions,
        onlineId: state.onlineId!,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
