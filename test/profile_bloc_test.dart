import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/blocs/profile/profile_bloc.dart';
import 'package:gt7_companion/blocs/profile/profile_event.dart';
import 'package:gt7_companion/blocs/profile/profile_state.dart';
import 'package:gt7_companion/models/dg_edge/dg_edge_player.dart';
import 'package:gt7_companion/repositories/profile_repository.dart';
import 'package:gt7_companion/services/dg_edge_service.dart';

class FakeDgEdgeService extends DgEdgeService {
  @override
  Future<DgEdgePlayerEventsResponse> fetchPlayerEvents(
    String onlineId, {
    int page = 1,
    String language = 'EN',
    String tz = 'Europe/Moscow',
    int version = 162,
  }) async {
    return DgEdgePlayerEventsResponse(
      events: [
        DgEdgePlayerEvent(
          id: 1,
          eventType: 'TT',
          trackName: 'Test Track',
          carName: 'Test Car',
          isEnded: true,
          playerResult: DgEdgePlayerResult(
            globalPosition: 100,
            countryPosition: 2,
            time: '01:00.000',
          ),
        ),
      ],
      pagination: DgEdgePlayerEventsPagination(current: 1, totalRecords: 1),
      csrfToken: 'fake-token',
    );
  }

  @override
  Future<bool> sendBannerImpressions(
    List<int> impressions, {
    String language = 'EN',
    int version = 162,
    String tz = 'Europe/Moscow',
    String onlineId = '',
  }) async {
    return true;
  }
}

void main() {
  group('ProfileBloc', () {
    test('loadPlayer updates state', () async {
      final bloc = ProfileBloc(ProfileRepositoryImpl(FakeDgEdgeService()));

      bloc.add(const ProfileEvent.loadPlayer(onlineId: 'nikitawolf008'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loadedState = bloc.state.maybeWhen(
        loaded: (onlineId, events, pagination, csrfToken) => bloc.state,
        orElse: () => null,
      );

      expect(loadedState, isNotNull);
      expect(
        bloc.state.maybeWhen(
          loaded: (onlineId, events, pagination, csrfToken) => onlineId,
          orElse: () => null,
        ),
        'nikitawolf008',
      );
      final events = bloc.state.maybeWhen(
        loaded: (onlineId, events, pagination, csrfToken) => events,
        orElse: () => <DgEdgePlayerEvent>[],
      );
      expect(events, isNotEmpty);
      expect(events.first.trackName, 'Test Track');

      await bloc.close();
    });

    test('sendBannerImpressions staying success state', () async {
      final bloc = ProfileBloc(ProfileRepositoryImpl(FakeDgEdgeService()));

      bloc.add(const ProfileEvent.loadPlayer(onlineId: 'nikitawolf008'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const ProfileEvent.sendBannerImpressions(impressions: [34]));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        bloc.state.maybeWhen(error: (message) => message, orElse: () => null),
        isNull,
      );
      await bloc.close();
    });
  });
}
