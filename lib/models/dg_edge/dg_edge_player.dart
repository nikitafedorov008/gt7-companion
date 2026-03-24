import 'package:flutter/foundation.dart';

int? _asInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) : null);

/// Data returned by DG-Edge /api/b.players.retrievePlayerEvents
class DgEdgePlayerEventsResponse {
  final List<DgEdgePlayerEvent> events;
  final DgEdgePlayerEventsPagination? pagination;
  final String? csrfToken;

  DgEdgePlayerEventsResponse({
    required this.events,
    this.pagination,
    this.csrfToken,
  });

  factory DgEdgePlayerEventsResponse.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    if (payload == null || payload is! Map) {
      throw FormatException(
        'Missing payload in DG-Edge player events response',
      );
    }

    final list = payload['list'];
    final items = <DgEdgePlayerEvent>[];
    if (list is Iterable) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          items.add(DgEdgePlayerEvent.fromJson(item));
        }
      }
    }

    DgEdgePlayerEventsPagination? pagination;
    if (payload['pagination'] is Map<String, dynamic>) {
      pagination = DgEdgePlayerEventsPagination.fromJson(
        payload['pagination'] as Map<String, dynamic>,
      );
    }

    return DgEdgePlayerEventsResponse(
      events: items,
      pagination: pagination,
      csrfToken: json['csrfToken'] as String?,
    );
  }
}

class DgEdgePlayerEventsPagination {
  final int? prevPage;
  final int? actualPage;
  final int? totalRecords;
  final int? nextPage;
  final int? lastPage;
  final int? current;
  final bool? hasMore;

  DgEdgePlayerEventsPagination({
    this.prevPage,
    this.actualPage,
    this.totalRecords,
    this.nextPage,
    this.lastPage,
    this.current,
    this.hasMore,
  });

  factory DgEdgePlayerEventsPagination.fromJson(Map<String, dynamic> json) {
    return DgEdgePlayerEventsPagination(
      prevPage: _asInt(json['prevPage']),
      actualPage: _asInt(json['actualPage']),
      totalRecords: _asInt(json['totalRecords']),
      nextPage: _asInt(json['nextPage']),
      lastPage: _asInt(json['lastPage']),
      current: _asInt(json['current']),
      hasMore: json['hasMore'] is bool ? json['hasMore'] as bool : null,
    );
  }
}

class DgEdgePlayerEvent {
  final int? id;
  final int? externalId;
  final String? eventType;
  final String? status;
  final bool isActive;
  final bool isFuture;
  final bool isEnded;

  final String? trackName;
  final String? trackFullName;
  final String? carName;
  final String? carBrand;

  final DgEdgePlayerResult? playerResult;

  DgEdgePlayerEvent({
    this.id,
    this.externalId,
    this.eventType,
    this.status,
    this.isActive = false,
    this.isFuture = false,
    this.isEnded = false,
    this.trackName,
    this.trackFullName,
    this.carName,
    this.carBrand,
    this.playerResult,
  });

  factory DgEdgePlayerEvent.fromJson(Map<String, dynamic> json) {
    final track = json['track'];
    final car = json['car'];
    final playerResult = json['playerResult'];

    return DgEdgePlayerEvent(
      id: _asInt(json['id']),
      externalId: _asInt(json['externalId']),
      eventType: json['eventType'] as String?,
      status: json['status'] as String?,
      isActive: json['isActive'] is bool ? json['isActive'] as bool : false,
      isFuture: json['isFuture'] is bool ? json['isFuture'] as bool : false,
      isEnded: json['isEnded'] is bool ? json['isEnded'] as bool : false,
      trackName: track is Map<String, dynamic>
          ? track['name'] as String?
          : null,
      trackFullName: track is Map<String, dynamic>
          ? track['fullName'] as String?
          : null,
      carName: car is Map<String, dynamic> ? car['name'] as String? : null,
      carBrand: car is Map<String, dynamic>
          ? (car['brand'] is Map<String, dynamic>
                ? car['brand']['name'] as String?
                : null)
          : null,
      playerResult: playerResult is Map<String, dynamic>
          ? DgEdgePlayerResult.fromJson(playerResult)
          : null,
    );
  }
}

class DgEdgePlayerResult {
  final int? globalPosition;
  final int? countryPosition;
  final String? time;
  final String? deltaGlobal;
  final String? deltaLocal;
  final String? timestamp;
  final DgEdgePlayerResultCar? car;

  DgEdgePlayerResult({
    this.globalPosition,
    this.countryPosition,
    this.time,
    this.deltaGlobal,
    this.deltaLocal,
    this.timestamp,
    this.car,
  });

  factory DgEdgePlayerResult.fromJson(Map<String, dynamic> json) {
    return DgEdgePlayerResult(
      globalPosition: _asInt(json['globalPosition']),
      countryPosition: _asInt(json['countryPosition']),
      time: json['time'] as String?,
      deltaGlobal: json['deltaGlobal'] as String?,
      deltaLocal: json['deltaLocal'] as String?,
      timestamp: json['timestamp'] as String?,
      car: json['car'] is Map<String, dynamic>
          ? DgEdgePlayerResultCar.fromJson(json['car'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DgEdgePlayerResultCar {
  final int? externalId;
  final String? brand;
  final String? name;

  DgEdgePlayerResultCar({this.externalId, this.brand, this.name});

  factory DgEdgePlayerResultCar.fromJson(Map<String, dynamic> json) {
    return DgEdgePlayerResultCar(
      externalId: _asInt(json['externalId']),
      brand: json['brand'] as String?,
      name: json['name'] as String?,
    );
  }
}
