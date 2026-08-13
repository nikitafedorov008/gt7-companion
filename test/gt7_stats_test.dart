import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/gt7_sport_profile.dart';
import 'package:gt7_companion/models/gt7_sport_race_stats.dart';
import 'package:gt7_companion/models/gt7_stats.dart';
import 'package:gt7_companion/models/gt7_stats_history.dart';
import 'package:gt7_companion/models/gt7_user_stats.dart';

/// Payloads captured verbatim from the live GT7 web API.
const String _statsGet = '''
{"result":{"car_life":{"buy_car_count":229,"buy_car_credit_amount":60638522,
"car_dictionary_progress":54,"customize_credit_amount":2611670,
"tuning_credit_amount":11413700},"driving":{"average_fuel_consumption":4690,
"driving_distance":44102177,"driving_time":532648,"total_fuel_consumption":9402860},
"game_play":{"credit_amount":80011383,"photo_count":9,"play_time":1977296},
"gt_world":{"circuit_experience_progress":8,"drift_point":1049050,
"episode_progress":0},"login_day_count":313,"medal":{"bronze":19,"gold":1,
"silver":1},"other":{},"profile":{"badge":5,"driver_level":66,"exp":99138170,
"license":5},"social":{"followers":29,"followings":25,"friends":0},
"sports_mode":{"clean_race_count":32,"fastest_lap_count":7,
"pole_position_count":1,"race_count":174,"win_count":6},
"user":{"avatar_photo_id":21111529820279920,"country_code":"RU",
"nick_name":"NikitaFedorov008","user_id":"038a1147-d5df-44ae-ae43-84934b4d2da2",
"driver_rating":2,"is_star_player":false,"manufacturer_id":0,
"sportsmanship_rating":6,"dr_point_ratio":0.4865}}}
''';

const String _sportProfile = '''
{"result":{"driver_rating":2,"is_star_player":false,"main_area":4772,
"manufacturer_id":0,"race_count":171,"secondary_area":6756,
"sportsmanship_rating":6,"user_id":"038a1147-d5df-44ae-ae43-84934b4d2da2"}}
''';

const String _sportRace = '''
{"result":[{"average_qualify_rank":9.06578947368421,"average_rank":7.75,
"lap":818,"lead_lap":9,"pole_position":0,"race":152,"target_id":0,"top5":44,
"top_match":0,"type":1,"win":3},{"average_qualify_rank":11.11111111111111,
"average_rank":7.472222222222222,"lap":456,"lead_lap":39,"pole_position":1,
"race":36,"target_id":0,"top5":14,"top_match":0,"type":2,"win":3}]}
''';

const String _history = '''
{"result":{"driver_rating":[2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
"driving_distance":[0,110824,0,0,0,0,0,30160,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
"driving_marathon_count":[0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
"sportsmanship_rating":[6,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}}
''';

Map<String, dynamic> _decode(String s) =>
    jsonDecode(s) as Map<String, dynamic>;

void main() {
  group('Gt7Stats.fromJson', () {
    final stats = Gt7Stats.fromJson(_decode(_statsGet));

    test('reads car life and lifetime driving', () {
      expect(stats.carLife.buyCarCount, 229);
      expect(stats.carLife.carDictionaryProgress, 54);
      expect(stats.driving.drivingDistanceMeters, 44102177);
      expect(stats.driving.totalKm, closeTo(44102.177, 0.001));
      expect(stats.driving.drivingTime, const Duration(seconds: 532648));
    });

    test('reads sport mode, social, medals and profile', () {
      expect(stats.sportsMode.raceCount, 174);
      expect(stats.sportsMode.winCount, 6);
      expect(stats.sportsMode.polePositionCount, 1);
      expect(stats.social.followers, 29);
      expect(stats.medals.total, 21);
      expect(stats.profile.driverLevel, 66);
      expect(stats.profile.license, 5);
      expect(stats.loginDayCount, 313);
    });

    test('keeps dr_point_ratio, the exact DR bar fill', () {
      expect(stats.driverRatingRatio, 0.4865);
      expect(stats.driverRating, 2);
      expect(stats.sportsmanshipRating, 6);
    });

    test('survives a response with sections missing', () {
      final sparse = Gt7Stats.fromJson(_decode('{"result":{}}'));
      expect(sparse.carLife.buyCarCount, 0);
      expect(sparse.driving.totalKm, 0);
      expect(sparse.driverRating, -1);
      expect(sparse.profile.license, -1);
    });
  });

  group('Gt7SportProfile.fromJson', () {
    final profile = Gt7SportProfile.fromJson(_decode(_sportProfile));

    test('reads numeric ratings and race count', () {
      expect(profile.driverRating, 2);
      expect(profile.sportsmanshipRating, 6);
      expect(profile.raceCount, 171);
      expect(profile.mainArea, 4772);
    });

    test('maps rating codes to the letters the site displays', () {
      // Anchored on a screenshot of the live profile page for this account:
      // it renders "Рейтинг гонщика D" and "Рейтинг безопасности S" for
      // codes 2 and 6. If the site ever disagrees, this test is where it
      // surfaces.
      expect(profile.driverRatingLabel, 'D');
      expect(profile.safetyRatingLabel, 'S');
    });

    test('returns null for an unmapped code instead of a wrong letter', () {
      final odd = Gt7SportProfile.fromJson(
        _decode('{"result":{"driver_rating":99,"sportsmanship_rating":99}}'),
      );
      expect(odd.driverRatingLabel, isNull);
      expect(odd.safetyRatingLabel, isNull);
    });
  });

  group('Gt7SportRaceStats.listFromJson', () {
    final races = Gt7SportRaceStats.listFromJson(_decode(_sportRace));

    test('parses one entry per requested type', () {
      expect(races, hasLength(2));
      expect(races[0].type, 1);
      expect(races[0].races, 152);
      expect(races[0].wins, 3);
      expect(races[1].type, 2);
      expect(races[1].leadLaps, 39);
      expect(races[1].averageRank, closeTo(7.4722, 0.0001));
    });

    test('returns empty when result is not a list', () {
      expect(Gt7SportRaceStats.listFromJson(_decode('{"result":{}}')), isEmpty);
    });
  });

  group('Gt7StatsHistory.fromJson', () {
    final history = Gt7StatsHistory.fromJson(
      _decode(_history),
      year: 2026,
      month: 8,
    );

    test('sums daily distance into kilometres', () {
      expect(history.drivingDistanceMeters, hasLength(31));
      expect(history.totalKm, closeTo(140.984, 0.001));
      expect(history.activeDays, 2);
      expect(history.latestDriverRating, 2);
    });

    test('handles an empty month', () {
      final empty = Gt7StatsHistory.fromJson(
        _decode('{"result":{}}'),
        year: 2026,
        month: 1,
      );
      expect(empty.totalKm, 0);
      expect(empty.activeDays, 0);
      expect(empty.latestDriverRating, isNull);
    });
  });

  group('Gt7UserStats.fromApi', () {
    // Every expectation here is a number read off a screenshot of the live
    // profile page for this account, not a number the code happened to produce.
    test('matches what the site prints for this account', () {
      final combined = Gt7UserStats.fromApi(
        sportProfile: Gt7SportProfile.fromJson(_decode(_sportProfile)),
        sportRaces: Gt7SportRaceStats.listFromJson(_decode(_sportRace)),
        stats: Gt7Stats.fromJson(_decode(_statsGet)),
      );

      expect(combined.driverRating, 'D'); // «Рейтинг гонщика D»
      expect(combined.safetyRating, 'S'); // «Рейтинг безопасности S»
      expect(combined.license, 'S'); // «Лицензия S»
      expect(combined.collectionLevel, 66); // «Уровень коллекции 66»
      // «Гонки 188» — the sum of get_sport_race (152 + 36), not the 174 in
      // sports_mode nor the 171 in get_sport_profile.
      expect(combined.races, 188);
      expect(combined.wins, 6); // «Победы 6»
      expect(combined.totalKm, closeTo(44102.177, 0.001)); // «44102.18 км»
      expect(combined.carsPurchased, 229); // «Купленные машины 229»
      expect(combined.followers, 29); // «29 Подписчик»
      expect(combined.driverRatingProgress, 0.4865);
    });

    test('falls back to the sport profile when /stats/get failed', () {
      final partial = Gt7UserStats.fromApi(
        sportProfile: Gt7SportProfile.fromJson(_decode(_sportProfile)),
        sportRaces: Gt7SportRaceStats.listFromJson(_decode(_sportRace)),
      );

      expect(partial.races, 188); // still the sport_race sum
      expect(partial.wins, 6);
      expect(partial.totalKm, isNull);
      expect(partial.carsPurchased, isNull);
      expect(partial.license, isNull);
      // No exact ratio available — falls back to the per-letter estimate.
      expect(partial.driverRatingProgress, 0.3);
    });
  });

  group('Gt7ProfileStats.licenseLabel', () {
    test('maps code 5 to the S badge the site shows', () {
      final stats = Gt7Stats.fromJson(_decode(_statsGet));
      expect(stats.profile.license, 5);
      expect(stats.profile.licenseLabel, 'S');
    });

    test('returns null for an unknown code', () {
      final odd = Gt7Stats.fromJson(_decode('{"result":{"profile":{"license":99}}}'));
      expect(odd.profile.licenseLabel, isNull);
    });
  });
}
