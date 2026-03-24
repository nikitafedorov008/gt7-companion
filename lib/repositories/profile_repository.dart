import 'package:flutter/foundation.dart';

import '../models/dg_edge/dg_edge_player.dart';
import '../services/dg_edge_service.dart';

abstract class ProfileRepository {
  Future<DgEdgePlayerEventsResponse> fetchPlayerEvents(
    String onlineId, {
    int page = 1,
  });

  Future<bool> sendBannerImpressions(List<int> impressions, {String onlineId});
}

class ProfileRepositoryImpl extends ProfileRepository with ChangeNotifier {
  final DgEdgeService _dgEdgeService;

  ProfileRepositoryImpl(this._dgEdgeService);

  @override
  Future<DgEdgePlayerEventsResponse> fetchPlayerEvents(
    String onlineId, {
    int page = 1,
  }) {
    return _dgEdgeService.fetchPlayerEvents(
      onlineId,
      page: page,
      language: 'EN',
      tz: 'Europe/Moscow',
    );
  }

  @override
  Future<bool> sendBannerImpressions(
    List<int> impressions, {
    String onlineId = '',
  }) {
    return _dgEdgeService.sendBannerImpressions(
      impressions,
      onlineId: onlineId,
      tz: 'Europe/Moscow',
    );
  }
}
